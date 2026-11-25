import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_keys.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/audio_service.dart';
import '../../core/utils/file_picker_helper.dart';
import '../../models/advisor_model.dart';
import '../../models/text_reading_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/text_reading_service.dart';
import '../menu_pages/add_funds_screen.dart';
import '../menu_pages/reading_history_screen.dart';

class CustomerTextReadingScreen extends StatefulWidget {
  final AdvisorDto advisor;

  const CustomerTextReadingScreen({
    Key? key,
    required this.advisor,
  }) : super(key: key);

  @override
  State<CustomerTextReadingScreen> createState() => _CustomerTextReadingScreenState();
}

class _CustomerTextReadingScreenState extends State<CustomerTextReadingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = TextReadingService();

  // Controllers
  final _customerNameController = TextEditingController();
  final _situationController = TextEditingController();
  final _specQuestionController = TextEditingController();
  final _queryReplyController = TextEditingController();

  DateTime? _selectedDob;
  String _selectedGender = 'female';
  PickedFileData? _selectedFile;

  // Selected Service Tier: false = Regular ($9.99, 24h), true = Fast-Track ($19.99, 1h)
  bool _isFastTrack = false;

  bool _isLoading = true;
  String? _submittingType; // 'regular', 'fast', 'reply', null

  // Existing / Active Text Reading state
  bool _isExistingResponse = false;
  bool _hasAdvisorResponse = false;
  bool _isAdvisorResponded = false;
  bool _hasCompletedReadings = false;
  bool _showDetailsAccordion = false;
  int _readingId = 0;
  String? _finalReadingText;
  DateTime? _quesDate;
  DateTime? _resDate;
  List<ServiceMessageModel> _conversationMessages = [];
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadTextReadings();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _customerNameController.dispose();
    _situationController.dispose();
    _specQuestionController.dispose();
    _queryReplyController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _silentPollReading());
  }

  Future<void> _silentPollReading() async {
    if (!mounted || !_isExistingResponse || _readingId <= 0) return;
    try {
      final messages = await _service.getServiceMessages(_readingId, entityType: 2);
      if (!mounted) return;
      if (messages.length > _conversationMessages.length) {
        final hasNewAdv = messages.skip(_conversationMessages.length).any((m) => m.isAdvisor == true);
        if (hasNewAdv) {
          AudioService.playMessageChime();
        }
        setState(() {
          _conversationMessages = messages;
          _hasAdvisorResponse = true;
          _isAdvisorResponded = messages.isNotEmpty && (messages.last.isAdvisor == true);
        });
      }
    } catch (_) {}
  }

  String _getAdvisorId() {
    final adv = widget.advisor;
    if (adv.loginId != null && adv.loginId!.isNotEmpty) return adv.loginId!;
    if (adv.advisorId != null && adv.advisorId!.isNotEmpty) return adv.advisorId!;
    return adv.id;
  }

  Future<void> _loadTextReadings() async {
    setState(() => _isLoading = true);
    try {
      final userProv = Provider.of<UserProvider>(context, listen: false);
      userProv.fetchUserProfile(); // ensure latest balance is loaded

      final readings = await _service.getCustomerTextReadings();
      final advId = _getAdvisorId();

      final advisorReadings = readings.where((r) {
        final rAdvId = r.advisorId;
        final rProfileId = r.advisorProfileId ?? '';
        return rAdvId == advId ||
            rProfileId == advId ||
            rAdvId == widget.advisor.id ||
            rProfileId == widget.advisor.id;
      }).toList();

      _hasCompletedReadings = advisorReadings.any((r) {
        final st = (r.status ?? '').toLowerCase().trim();
        return r.isCompleted || r.completedOn != null || st == 'completed' || st == 'cancelled';
      });

      // Filter active (in-progress) readings
      final pendingReadings = advisorReadings.where((r) {
        final st = (r.status ?? '').toLowerCase().trim();
        final isFinished = r.isCompleted || r.completedOn != null || st == 'completed' || st == 'cancelled';
        return !isFinished;
      }).toList();

      pendingReadings.sort((a, b) {
        final tA = a.createdOn?.millisecondsSinceEpoch ?? 0;
        final tB = b.createdOn?.millisecondsSinceEpoch ?? 0;
        return tB.compareTo(tA);
      });

      if (pendingReadings.isNotEmpty) {
        final activeReading = pendingReadings.first;
        _isExistingResponse = true;
        _readingId = activeReading.id;
        _customerNameController.text = activeReading.customerName;
        _selectedDob = activeReading.dob;

        String genderVal = activeReading.gender.toLowerCase().trim();
        if (genderVal == 'na' || genderVal == 'other' || genderVal == 'prefer_not_to_say') {
          genderVal = 'prefer_not_say';
        }
        _selectedGender = genderVal.isNotEmpty ? genderVal : 'prefer_not_say';

        _situationController.text = activeReading.generalDescription;
        _specQuestionController.text = activeReading.specQuestion ?? '';
        _quesDate = activeReading.createdOn;

        final hasFinalText = activeReading.finalReadingText != null &&
            activeReading.finalReadingText!.trim().isNotEmpty;
        _finalReadingText = hasFinalText ? activeReading.finalReadingText : null;
        _resDate = activeReading.completedOn ?? activeReading.createdOn;

        // Fetch clarification messages
        final messages = await _service.getServiceMessages(_readingId, entityType: 2);
        _conversationMessages = messages;

        final hasMessages = messages.isNotEmpty;
        _hasAdvisorResponse = hasFinalText || hasMessages;

        if (hasMessages) {
          final lastMsg = messages.last;
          final isLastFromAdv = lastMsg.isAdvisor != null
              ? lastMsg.isAdvisor!
              : (lastMsg.userId == advId || lastMsg.advisorLoginId == advId);

          _isAdvisorResponded = !activeReading.isCompleted &&
              activeReading.status != 'Completed' &&
              activeReading.status != 'Cancelled' &&
              isLastFromAdv;
        } else {
          _isAdvisorResponded = false;
        }
      } else {
        _isExistingResponse = false;
        _readingId = 0;
        _finalReadingText = null;
        _conversationMessages = [];
        _hasAdvisorResponse = false;
        _isAdvisorResponded = false;
      }
    } catch (e) {
      debugPrint("Error loading text readings: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFile() async {
    final picked = await FilePickerHelper.pickFile(
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
    );
    if (picked != null) {
      setState(() => _selectedFile = picked);
    }
  }

  Future<void> _submitRequest() async {
    if (_submittingType != null) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Please select Date of Birth for the POI."),
        ),
      );
      return;
    }

    final situationText = _situationController.text.trim();
    if (situationText.length < 150) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.amber.shade900,
          content: Text("Description requires at least 150 characters (currently ${situationText.length})."),
        ),
      );
      return;
    }

    final userProv = Provider.of<UserProvider>(context, listen: false);
    final userScreenName = userProv.user?.screenName ?? userProv.user?.displayName ?? '';
    final price = _isFastTrack ? 19.99 : 9.99;

    // Check balance before sending
    if (userProv.userBalance < price) {
      _showRechargeDialog(price);
      return;
    }

    setState(() => _submittingType = _isFastTrack ? 'fast' : 'regular');

    final payload = {
      'customerName': _customerNameController.text.trim(),
      'dob': DateFormat('yyyy-MM-dd').format(_selectedDob!),
      'gender': _selectedGender,
      'generalDescription': situationText,
      'specQuestion': _specQuestionController.text.trim(),
      'advisorId': _getAdvisorId(),
      'price': price,
      'userScreenName': userScreenName,
      'readingType': _isFastTrack,
    };

    try {
      final res = await _service.createTextReading(payload);

      if (res is Map && res['message'] == "Prev Text Reading is not completed yet") {
        if (!mounted) return;
        _showAlertDialog(
          title: "Active Request Pending",
          message: "Your previous Text Reading request with this advisor is still in progress.",
        );
        setState(() => _submittingType = null);
        return;
      }

      int newId = 0;
      if (res is Map) {
        newId = res['id'] ?? res['Id'] ?? 0;
      }

      // If file attached, upload it
      if (_selectedFile != null && newId > 0) {
        try {
          await _service.uploadTextReadingFile(newId, _selectedFile!.bytes, _selectedFile!.name);
        } catch (uploadErr) {
          debugPrint("File upload warning: $uploadErr");
        }
      }

      // Refresh balance
      userProv.fetchUserProfile();

      if (!mounted) return;
      _showSubmissionSuccessDialog(isFastTrack: _isFastTrack);
    } catch (e) {
      if (!mounted) return;
      if (e is ApiException && e.statusCode == 400) {
        _showRechargeDialog(price);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Submission failed: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _submittingType = null);
    }
  }

  Future<void> _submitCustomerReply() async {
    final queryText = _queryReplyController.text.trim();
    if (queryText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please type your reply before sending.")),
      );
      return;
    }

    final userProv = Provider.of<UserProvider>(context, listen: false);
    final userName = userProv.user?.displayName ?? userProv.user?.screenName ?? "Customer";

    final localMsg = ServiceMessageModel(
      id: DateTime.now().millisecondsSinceEpoch,
      entityId: _readingId,
      entityTypeId: 2,
      messageText: queryText,
      userId: userProv.user?.id ?? "",
      userName: userName,
      isAdvisor: false,
      createDate: DateTime.now(),
    );

    setState(() {
      _conversationMessages.add(localMsg);
      _submittingType = 'reply';
    });
    _queryReplyController.clear();

    final payload = {
      'MessageText': queryText,
      'EntityTypeId': 2,
      'EntityId': _readingId,
      'ClientId': userProv.user?.id ?? "",
      'advisorLoginId': _getAdvisorId(),
      'UserName': userName,
    };

    try {
      await _service.createServiceMessage(payload);
      if (!mounted) return;
      _showReplySuccessDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send reply: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => _submittingType = null);
    }
  }

  void _showSubmissionSuccessDialog({required bool isFastTrack}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F0D38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.accentGold, width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accentGold, width: 2),
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.accentGold, size: 50),
            ),
            const SizedBox(height: 18),
            const Text(
              "Request Submitted!",
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              isFastTrack
                  ? "Your Fast-Track Reading request has been delivered to ${widget.advisor.name}. Expected reply within 1 hour."
                  : "Your Reading request has been delivered to ${widget.advisor.name}. Expected reply within 24 hours.",
              style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _loadTextReadings();
                },
                child: const Text(
                  "Track My Reading",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text(
                "Return to Advisor Profile",
                style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReplySuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F0D38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.onlineGreen, width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.onlineGreen.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.onlineGreen, width: 2),
              ),
              child: const Icon(Icons.send_rounded, color: AppColors.onlineGreen, size: 46),
            ),
            const SizedBox(height: 18),
            const Text(
              "Reply Delivered!",
              style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "Your clarification has been submitted to ${widget.advisor.name}. You will be notified when they finalize your reading.",
              style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _loadTextReadings();
                },
                child: const Text("View Conversation", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRechargeDialog(double requiredAmount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F0D38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.account_balance_wallet_rounded, color: AppColors.accentGold, size: 24),
            SizedBox(width: 8),
            Text("Insufficient Balance", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Text(
          "This reading requires \$${requiredAmount.toStringAsFixed(2)}. Please add funds to your wallet to continue.",
          style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondaryDark)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text("Add Funds", style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(ctx);
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddFundsScreen()));
              _loadTextReadings();
            },
          ),
        ],
      ),
    );
  }

  void _showAlertDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F0D38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 14)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGold,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProv = Provider.of<UserProvider>(context);
    final userBalance = userProv.userBalance;
    final currentPrice = _isFastTrack ? 19.99 : 9.99;
    final hasEnoughBalance = userBalance >= currentPrice;

    return Scaffold(
      backgroundColor: const Color(0xFF110722),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B0B33),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accentGold, width: 1.5),
              ),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: const Color(0xFF2E1A47),
                backgroundImage: (widget.advisor.profilePhoto != null && widget.advisor.profilePhoto!.isNotEmpty)
                    ? NetworkImage(widget.advisor.profilePhoto!.startsWith('http')
                        ? widget.advisor.profilePhoto!
                        : 'https://psychicheroes.com/${widget.advisor.profilePhoto!}')
                    : null,
                child: (widget.advisor.profilePhoto == null || widget.advisor.profilePhoto!.isEmpty)
                    ? Text(
                        widget.advisor.name.isNotEmpty ? widget.advisor.name[0].toUpperCase() : 'A',
                        style: const TextStyle(color: AppColors.accentGold, fontSize: 14, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.advisor.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded, color: AppColors.accentGold, size: 14),
                    ],
                  ),
                  Text(
                    (widget.advisor.advisorTitle != null && widget.advisor.advisorTitle!.isNotEmpty)
                        ? widget.advisor.advisorTitle!
                        : "Spiritual Text Reading",
                    style: const TextStyle(color: AppColors.accentGold, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Wallet Balance Chip in AppBar
          Container(
            margin: const EdgeInsets.only(right: 14, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet_rounded, color: AppColors.accentGold, size: 14),
                const SizedBox(width: 5),
                Text(
                  "\$${userBalance.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGold)),
            )
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Advisor Service Showcase Card
                    _buildAdvisorHeaderBanner(),
                    const SizedBox(height: 16),

                    // Past completed readings notification
                    if (_hasCompletedReadings && !_isExistingResponse) ...[
                      _buildCompletedPastReadingsNotice(),
                      const SizedBox(height: 16),
                    ],

                    // If existing response/in-progress, render status and chat FIRST
                    if (_isExistingResponse) ...[
                      _buildActiveReadingStatusCard(),
                      const SizedBox(height: 16),
                      if (_conversationMessages.isNotEmpty) ...[
                        _buildConversationThreadSection(),
                        const SizedBox(height: 16),
                      ],
                      if (_finalReadingText != null && _finalReadingText!.trim().isNotEmpty) ...[
                        _buildFinalReadingCard(),
                        const SizedBox(height: 16),
                      ],
                      if (_isAdvisorResponded) ...[
                        _buildCustomerReplyComposer(),
                        const SizedBox(height: 16),
                      ],
                      _buildSubmittedDetailsAccordion(),
                    ] else ...[
                      // New Request Form (Mobile-first, beautiful 3-card structure)
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. POI Details Card
                            _buildPoiCard(),
                            const SizedBox(height: 16),

                            // 2. Situation & Questions Card
                            _buildSituationCard(),
                            const SizedBox(height: 16),

                            // 3. Delivery Tier Selection Card
                            _buildDeliveryTierCard(),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
      // Sticky Bottom Checkout Bar (Only shown in new request mode)
      bottomNavigationBar: (!_isLoading && !_isExistingResponse)
          ? _buildStickyCheckoutBar(userBalance, currentPrice, hasEnoughBalance)
          : null,
    );
  }

  // -------------------------------------------------------------
  // UI WIDGETS
  // -------------------------------------------------------------

  Widget _buildAdvisorHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF281145), Color(0xFF1A0A30)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentGold.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mail_lock_rounded, color: AppColors.accentGold, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Confidential Spiritual Text Reading",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  "Receive an in-depth, personalized reading directly from ${widget.advisor.name}.",
                  style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedPastReadingsNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: Colors.lightBlueAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Previous reading completed",
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Your past readings can be revisited anytime in Reading History.",
                  style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 12),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReadingHistoryScreen()),
                    );
                  },
                  child: const Text(
                    "View Reading History →",
                    style: TextStyle(
                      color: AppColors.accentCyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card 1: Person of Interest (POI)
  Widget _buildPoiCard() {
    final userProv = Provider.of<UserProvider>(context, listen: false);
    final userScreenName = userProv.user?.screenName ?? userProv.user?.displayName ?? 'Valued Client';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E0E35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: const [
              Icon(Icons.person_pin_rounded, color: AppColors.accentGold, size: 20),
              SizedBox(width: 8),
              Text(
                "Person of Interest (POI)",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "Enter details of the person or relationship focus of your reading.",
            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
          ),
          const SizedBox(height: 16),

          // Display Name Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_circle_outlined, color: AppColors.textSecondaryDark, size: 16),
                const SizedBox(width: 8),
                Text(
                  "Booking as: ",
                  style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                ),
                Text(
                  userScreenName,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // POI Name Input
          const Text(
            "POI Name *",
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _customerNameController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.accentGold, size: 18),
              hintText: "Enter full or first name of POI",
              hintStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFF2A1549),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.accentGold, width: 1.5),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return "POI Name is required.";
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Date of Birth of POI
          const Text(
            "Date of Birth *",
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDob ?? DateTime(now.year - 25, 1, 1),
                firstDate: DateTime(1900),
                lastDate: now,
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppColors.accentGold,
                        onPrimary: Colors.black,
                        surface: Color(0xFF26123D),
                        onSurface: Colors.white,
                      ),
                      dialogBackgroundColor: const Color(0xFF1E0E35),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() => _selectedDob = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1549),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedDob != null ? AppColors.accentGold.withOpacity(0.6) : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, color: AppColors.accentGold, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selectedDob != null
                          ? DateFormat('MMMM d, yyyy').format(_selectedDob!)
                          : "Select Date of Birth of POI",
                      style: TextStyle(
                        color: _selectedDob != null ? Colors.white : AppColors.textSecondaryDark,
                        fontSize: 14,
                        fontWeight: _selectedDob != null ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (_selectedDob != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${DateTime.now().year - _selectedDob!.year} yrs",
                        style: const TextStyle(color: AppColors.accentGold, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ] else ...[
                    const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondaryDark),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Gender Selection (Modern Choice Chips)
          const Text(
            "Gender *",
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildGenderChip("female", "Female", "👩"),
              const SizedBox(width: 8),
              _buildGenderChip("male", "Male", "👨"),
              const SizedBox(width: 8),
              _buildGenderChip("prefer_not_say", "Other", "✨"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderChip(String value, String label, String emoji) {
    final isSelected = _selectedGender == value;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _selectedGender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentGold.withOpacity(0.15) : const Color(0xFF2A1549),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.accentGold : Colors.white.withOpacity(0.08),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.accentGold : Colors.white70,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Card 2: Your Situation & Questions
  Widget _buildSituationCard() {
    final textLength = _situationController.text.trim().length;
    final isMinMet = textLength >= 150;
    final progress = (textLength / 150).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E0E35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: const [
              Icon(Icons.auto_awesome_rounded, color: AppColors.accentGold, size: 20),
              SizedBox(width: 8),
              Text(
                "Your Situation & Questions",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "Share background information so your advisor can connect with your energies.",
            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
          ),
          const SizedBox(height: 14),

          // Helpful topic prompt starters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPromptChip("💖 Love & Relationship", "Regarding my connection with this person: "),
                const SizedBox(width: 8),
                _buildPromptChip("💼 Career & Purpose", "Regarding my current career path and decisions: "),
                const SizedBox(width: 8),
                _buildPromptChip("🔮 Life Transition", "I am currently navigating a major life transition: "),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // General Situation Textarea
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "General Situation *",
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Text(
                "$textLength / 3000 chars",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isMinMet ? AppColors.onlineGreen : Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _situationController,
            maxLines: 6,
            minLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: "Please describe your situation in detail (minimum 150 characters required for an accurate reading)...",
              hintStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFF2A1549),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isMinMet ? AppColors.onlineGreen.withOpacity(0.5) : Colors.white.withOpacity(0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.accentGold, width: 1.5),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return "Situation description is required.";
              }
              if (val.trim().length < 150) {
                return "Please write at least 150 characters (currently ${val.trim().length}).";
              }
              if (val.trim().length > 3000) {
                return "Maximum 3000 characters allowed.";
              }
              return null;
            },
          ),
          const SizedBox(height: 8),

          // Live Character Progress Indicator
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(
                isMinMet ? AppColors.onlineGreen : Colors.amber,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                isMinMet ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                size: 14,
                color: isMinMet ? AppColors.onlineGreen : Colors.amber,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  isMinMet
                      ? "✓ Character requirement satisfied."
                      : "Add ${150 - textLength} more characters to unlock submission.",
                  style: TextStyle(
                    fontSize: 11,
                    color: isMinMet ? AppColors.onlineGreen : Colors.amber,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Specific Questions (Optional)
          const Text(
            "Specific Questions (Optional)",
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _specQuestionController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 30),
                child: Icon(Icons.help_outline_rounded, color: AppColors.accentGold, size: 18),
              ),
              hintText: "1. What does the near future hold?\n2. What should I be aware of?",
              hintStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFF2A1549),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.accentGold, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Upload POI Photos (Optional)
          const Text(
            "Attach Photo / Document (Optional)",
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          if (_selectedFile == null) ...[
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A1549),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.12), style: BorderStyle.solid),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.cloud_upload_outlined, color: AppColors.accentGold, size: 22),
                    SizedBox(width: 10),
                    Text(
                      "Upload POI photo or PDF (.jpg, .png, .pdf)",
                      style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.onlineGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.onlineGreen.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_file_rounded, color: AppColors.onlineGreen, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFile!.name,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "${(_selectedFile!.bytes.length / 1024).toStringAsFixed(1)} KB • Attached",
                          style: const TextStyle(color: AppColors.onlineGreen, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                    onPressed: () => setState(() => _selectedFile = null),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPromptChip(String title, String starterText) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        if (_situationController.text.trim().isEmpty) {
          setState(() {
            _situationController.text = starterText;
          });
        } else {
          setState(() {
            _situationController.text += "\n$starterText";
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
        ),
        child: Text(
          title,
          style: const TextStyle(color: AppColors.accentGold, fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // Card 3: Delivery Tier Selection
  Widget _buildDeliveryTierCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E0E35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.speed_rounded, color: AppColors.accentGold, size: 20),
              SizedBox(width: 8),
              Text(
                "Select Delivery Speed",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "Choose standard delivery or jump to the priority express queue.",
            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
          ),
          const SizedBox(height: 14),

          // Standard Option Card
          _buildTierOptionItem(
            isFast: false,
            title: "Standard Service",
            price: "\$9.99",
            duration: "Within 24 Hours",
            description: "Detailed spiritual reading prepared within 24 hours.",
            icon: Icons.access_time_rounded,
          ),
          const SizedBox(height: 12),

          // Fast-Track Option Card
          _buildTierOptionItem(
            isFast: true,
            title: "Fast-Track Priority",
            price: "\$19.99",
            duration: "Within 1 Hour",
            description: "Direct priority delivery within 60 minutes.",
            badge: "⚡ EXPRESS",
            icon: Icons.bolt_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildTierOptionItem({
    required bool isFast,
    required String title,
    required String price,
    required String duration,
    required String description,
    required IconData icon,
    String? badge,
  }) {
    final isSelected = _isFastTrack == isFast;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _isFastTrack = isFast),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentGold.withOpacity(0.12) : const Color(0xFF2A1549),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.accentGold : Colors.white.withOpacity(0.08),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentGold : Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.black : Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    duration,
                    style: TextStyle(
                      color: isSelected ? AppColors.accentGold : AppColors.textSecondaryDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    color: isSelected ? AppColors.accentGold : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.accentGold : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.accentGold : Colors.white38,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.black)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Sticky Bottom Checkout Bar
  Widget _buildStickyCheckoutBar(double userBalance, double currentPrice, bool hasEnoughBalance) {
    final situationLen = _situationController.text.trim().length;
    final isMinCharsMet = situationLen >= 150;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B0B33),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Price & Speed Info
            Expanded(
              flex: 5,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        "\$${currentPrice.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: AppColors.accentGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isFastTrack ? "1h Fast-Track" : "24h Standard",
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        hasEnoughBalance ? Icons.account_balance_wallet_outlined : Icons.warning_amber_rounded,
                        size: 13,
                        color: hasEnoughBalance ? AppColors.onlineGreen : Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasEnoughBalance
                            ? "Wallet: \$${userBalance.toStringAsFixed(2)}"
                            : "Low Balance: \$${userBalance.toStringAsFixed(2)}",
                        style: TextStyle(
                          color: hasEnoughBalance ? AppColors.onlineGreen : Colors.amber,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Submit Button
            Expanded(
              flex: 6,
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasEnoughBalance ? AppColors.accentGold : const Color(0xFFE5A93C),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _submittingType != null
                      ? null
                      : () {
                          if (!isMinCharsMet) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.amber.shade900,
                                content: Text("Please enter at least 150 characters for your situation (current: $situationLen)."),
                              ),
                            );
                            return;
                          }
                          if (!hasEnoughBalance) {
                            _showRechargeDialog(currentPrice);
                          } else {
                            _submitRequest();
                          }
                        },
                  icon: _submittingType != null
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : Icon(hasEnoughBalance ? Icons.send_rounded : Icons.add_rounded, size: 18),
                  label: Text(
                    _submittingType != null
                        ? "Submitting..."
                        : (hasEnoughBalance ? "Submit Reading" : "Add Funds"),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // ACTIVE READING MODE (When reading is in progress or completed)
  // -------------------------------------------------------------

  Widget _buildActiveReadingStatusCard() {
    final statusText = _finalReadingText != null
        ? "Completed"
        : (_isAdvisorResponded ? "Clarification Requested" : "Awaiting Advisor");

    final statusColor = _finalReadingText != null
        ? AppColors.onlineGreen
        : (_isAdvisorResponded ? Colors.amber : Colors.lightBlueAccent);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E0E35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Reading Progress",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Visual Progress Stepper
          Row(
            children: [
              _buildStepItem(number: "1", title: "Sent", isDone: true, isActive: false),
              _buildStepLine(isDone: true),
              _buildStepItem(
                number: "2",
                title: "Reviewing",
                isDone: _finalReadingText != null,
                isActive: _finalReadingText == null,
              ),
              _buildStepLine(isDone: _finalReadingText != null),
              _buildStepItem(
                number: "3",
                title: "Complete",
                isDone: _finalReadingText != null,
                isActive: false,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Awaiting Notice banner
          if (!_hasAdvisorResponse) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_top_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Your request is with ${widget.advisor.name}. You will be notified the moment they reply.",
                      style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required String number,
    required String title,
    required bool isDone,
    required bool isActive,
  }) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone
                ? AppColors.onlineGreen
                : (isActive ? AppColors.accentGold : Colors.white12),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 16, color: Colors.black)
                : Text(
                    number,
                    style: TextStyle(
                      color: isActive ? Colors.black : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: isDone || isActive ? Colors.white : Colors.white38,
            fontSize: 11,
            fontWeight: isDone || isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine({required bool isDone}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        color: isDone ? AppColors.onlineGreen : Colors.white12,
      ),
    );
  }

  // Conversation Clarification Thread
  Widget _buildConversationThreadSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E0E35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "💬 Clarifications Thread",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                "${_conversationMessages.length} message${_conversationMessages.length == 1 ? '' : 's'}",
                style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._conversationMessages.map((msg) {
            final isAdv = msg.isAdvisor == true ||
                (msg.userId == _getAdvisorId() || msg.advisorLoginId == _getAdvisorId());
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isAdv ? const Color(0xFF331A56) : const Color(0xFF173D2C),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isAdv ? AppColors.accentGold.withOpacity(0.4) : AppColors.onlineGreen.withOpacity(0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isAdv ? Icons.psychology_rounded : Icons.person_rounded,
                            size: 16,
                            color: isAdv ? AppColors.accentGold : AppColors.onlineGreen,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isAdv ? widget.advisor.name : "You",
                            style: TextStyle(
                              color: isAdv ? AppColors.accentGold : AppColors.onlineGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        DateFormat('d MMM, h:mm a').format(msg.createDate),
                        style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    msg.messageText,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.4),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Final Reading Card
  Widget _buildFinalReadingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E1A47), Color(0xFF1B0B33)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentGold, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGold.withOpacity(0.2),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.auto_awesome_rounded, color: AppColors.accentGold, size: 22),
                  SizedBox(width: 8),
                  Text(
                    "Final Reading Delivered",
                    style: TextStyle(color: AppColors.accentGold, fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (_resDate != null)
                Text(
                  DateFormat('MMMM d, yyyy').format(_resDate!),
                  style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),
          Text(
            _finalReadingText!,
            style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.6),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentGold,
                    side: const BorderSide(color: AppColors.accentGold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReadingHistoryScreen()),
                    );
                  },
                  icon: const Icon(Icons.history_rounded, size: 16),
                  label: const Text("View in History"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    setState(() {
                      _isExistingResponse = false;
                      _situationController.clear();
                      _specQuestionController.clear();
                      _customerNameController.clear();
                      _selectedDob = null;
                      _selectedFile = null;
                    });
                  },
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text("New Reading", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Reply Composer (Advisor Clarification)
  Widget _buildCustomerReplyComposer() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E0E35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.reply_rounded, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                "Reply to Advisor's Clarification",
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "${widget.advisor.name} asked for additional details to complete your reading.",
            style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _queryReplyController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: "Type your reply here...",
              hintStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFF2A1549),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.accentGold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              ),
              onPressed: _submittingType != null ? null : _submitCustomerReply,
              icon: _submittingType == 'reply'
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(
                _submittingType == 'reply' ? "Sending..." : "Send Reply",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Submitted Details Accordion
  Widget _buildSubmittedDetailsAccordion() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E0E35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _showDetailsAccordion = !_showDetailsAccordion),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.description_outlined, color: AppColors.accentGold, size: 18),
                      SizedBox(width: 8),
                      Text(
                        "View Submitted Request Details",
                        style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Icon(
                    _showDetailsAccordion ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),
          if (_showDetailsAccordion) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 8),
                  _buildDetailRow("POI Name", _customerNameController.text),
                  if (_selectedDob != null)
                    _buildDetailRow("DOB", DateFormat('dd/MM/yyyy').format(_selectedDob!)),
                  _buildDetailRow("Gender", _selectedGender.toUpperCase()),
                  if (_quesDate != null)
                    _buildDetailRow("Submitted On", DateFormat('dd/MM/yyyy, h:mm a').format(_quesDate!)),
                  const SizedBox(height: 10),
                  const Text("Situation:", style: TextStyle(color: AppColors.accentGold, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_situationController.text, style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4)),
                  if (_specQuestionController.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text("Specific Question:", style: TextStyle(color: AppColors.accentGold, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_specQuestionController.text, style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
