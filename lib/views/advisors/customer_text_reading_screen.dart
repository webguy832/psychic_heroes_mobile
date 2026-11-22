import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_exception.dart';
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

  bool _isLoading = true;
  String? _submittingType; // 'regular', 'fast', 'reply', null

  // Existing / Active Text Reading state
  bool _isExistingResponse = false;
  bool _hasAdvisorResponse = false;
  bool _isAdvisorResponded = false;
  bool _hasCompletedReadings = false;
  int _readingId = 0;
  String? _finalReadingText;
  DateTime? _quesDate;
  DateTime? _resDate;
  List<ServiceMessageModel> _conversationMessages = [];

  @override
  void initState() {
    super.initState();
    _loadTextReadings();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _situationController.dispose();
    _specQuestionController.dispose();
    _queryReplyController.dispose();
    super.dispose();
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

  Future<void> _submitRequest({required bool isFastTrack}) async {
    if (_submittingType != null) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select Date of Birth for the POI.")),
      );
      return;
    }

    final userProv = Provider.of<UserProvider>(context, listen: false);
    final userScreenName = userProv.user?.screenName ?? userProv.user?.displayName ?? '';
    final price = isFastTrack ? 19.99 : 9.99;

    setState(() => _submittingType = isFastTrack ? 'fast' : 'regular');

    final payload = {
      'customerName': _customerNameController.text.trim(),
      'dob': DateFormat('yyyy-MM-dd').format(_selectedDob!),
      'gender': _selectedGender,
      'generalDescription': _situationController.text.trim(),
      'specQuestion': _specQuestionController.text.trim(),
      'advisorId': _getAdvisorId(),
      'price': price,
      'userScreenName': userScreenName,
      'readingType': isFastTrack,
    };

    try {
      final res = await _service.createTextReading(payload);

      if (res is Map && res['message'] == "Prev Text Reading is not completed yet") {
        if (!mounted) return;
        _showAlertDialog(
          title: "Active Request Pending",
          message: "Your previous Text Reading request is not completed yet.",
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

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Text Reading submitted successfully!"),
          backgroundColor: AppColors.onlineGreen,
        ),
      );

      // Refresh readings view
      await _loadTextReadings();
    } catch (e) {
      if (!mounted) return;
      if (e is ApiException && e.statusCode == 400) {
        _showRechargeDialog();
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

    setState(() => _submittingType = 'reply');

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
      _queryReplyController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Query reply sent successfully!"),
          backgroundColor: AppColors.onlineGreen,
        ),
      );
      await _loadTextReadings();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send reply: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => _submittingType = null);
    }
  }

  void _showRechargeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgDarkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Insufficient Balance",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Your wallet does not have enough balance for this text reading request. Please recharge your wallet to proceed.",
          style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondaryDark)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.ctaGreen),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddFundsScreen()));
            },
            child: const Text("Add Funds", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAlertDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgDarkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 14)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProv = Provider.of<UserProvider>(context);
    final userScreenName = userProv.user?.screenName ?? userProv.user?.displayName ?? 'You';

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDarkCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.bgDarkCardElevated,
              backgroundImage: (widget.advisor.profilePhoto != null && widget.advisor.profilePhoto!.isNotEmpty)
                  ? NetworkImage(widget.advisor.profilePhoto!.startsWith('http')
                      ? widget.advisor.profilePhoto!
                      : 'https://psychicheroes.com/${widget.advisor.profilePhoto!}')
                  : null,
              child: (widget.advisor.profilePhoto == null || widget.advisor.profilePhoto!.isEmpty)
                  ? Text(
                      widget.advisor.name.isNotEmpty ? widget.advisor.name[0].toUpperCase() : 'A',
                      style: const TextStyle(color: AppColors.accentGold, fontSize: 13, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Text Reading: ${widget.advisor.name}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    (widget.advisor.advisorTitle != null && widget.advisor.advisorTitle!.isNotEmpty)
                        ? widget.advisor.advisorTitle!
                        : "Spiritual Psychic",
                    style: const TextStyle(color: AppColors.accentGold, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGold)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Info banner when past readings are completed
                  if (_hasCompletedReadings && !_isExistingResponse) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.blue.withOpacity(0.35)),
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
                                  "Your previous reading with this advisor is completed.",
                                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  "Completed and cancelled readings can be viewed in Reading History.",
                                  style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 12),
                                ),
                                const SizedBox(height: 8),
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
                                      fontSize: 13,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Form Container Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.bgDarkCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Display Name (Read-only)
                          const Text(
                            "Display Name",
                            style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.bgDark,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.borderDark),
                            ),
                            child: Text(
                              userScreenName,
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // POI Name *
                          const Text(
                            "POI Name *",
                            style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _customerNameController,
                            enabled: !_isExistingResponse,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: "Enter your POI name",
                              hintStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
                              filled: true,
                              fillColor: _isExistingResponse ? AppColors.bgDark : AppColors.bgDarkCardElevated,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderDark)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderDark)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accentGold)),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return "POI Name is required.";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // DOB of POI *
                          Row(
                            children: const [
                              Text(
                                "DOB of POI *",
                                style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  "(Person of interest related to reading)",
                                  style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _isExistingResponse
                                ? null
                                : () async {
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
                                              surface: AppColors.bgDarkCard,
                                              onSurface: Colors.white,
                                            ),
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
                                color: _isExistingResponse ? AppColors.bgDark : AppColors.bgDarkCardElevated,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.borderDark),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedDob != null
                                        ? DateFormat('dd/MM/yyyy').format(_selectedDob!)
                                        : "Select Date of Birth",
                                    style: TextStyle(
                                      color: _selectedDob != null ? Colors.white : AppColors.textSecondaryDark,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.accentGold),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Gender *
                          const Text(
                            "Gender *",
                            style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              _buildGenderOption("male", "Male"),
                              _buildGenderOption("female", "Female"),
                              _buildGenderOption("prefer_not_say", "Prefer not to say"),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // General Situation * (Between 150 and 3000 chars)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "General Situation *",
                                style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              if (!_isExistingResponse)
                                Text(
                                  "${_situationController.text.length}/3000 (min 150)",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _situationController.text.length < 150
                                        ? Colors.amber
                                        : AppColors.onlineGreen,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _situationController,
                            enabled: !_isExistingResponse,
                            maxLines: 5,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: "Please enter a detailed description of your situation between 150 and 3000 characters...",
                              hintStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
                              filled: true,
                              fillColor: _isExistingResponse ? AppColors.bgDark : AppColors.bgDarkCardElevated,
                              contentPadding: const EdgeInsets.all(14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderDark)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderDark)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accentGold)),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return "General situation description is required.";
                              }
                              if (val.trim().length < 150) {
                                return "Description must be at least 150 characters (current: ${val.trim().length}).";
                              }
                              if (val.trim().length > 3000) {
                                return "Description cannot exceed 3000 characters.";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Specific Questions (Optional)
                          if (!_isExistingResponse) ...[
                            const Text(
                              "Specific Questions",
                              style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _specQuestionController,
                              maxLines: 3,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: "You can ask specific questions here...",
                                hintStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
                                filled: true,
                                fillColor: AppColors.bgDarkCardElevated,
                                contentPadding: const EdgeInsets.all(14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderDark)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderDark)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accentGold)),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // File Upload
                            const Text(
                              "Upload POI Photos (Optional)",
                              style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Accepted: .jpg, .jpeg, .png, .pdf, .doc, .docx. Please ensure documents do not contain contact details.",
                              style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.accentCyan,
                                    side: const BorderSide(color: AppColors.accentCyan),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.attach_file_rounded, size: 18),
                                  label: const Text("Select File"),
                                  onPressed: _pickFile,
                                ),
                                if (_selectedFile != null) ...[
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.onlineGreen.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.onlineGreen.withOpacity(0.4)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_rounded, color: AppColors.onlineGreen, size: 16),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              _selectedFile!.name,
                                              style: const TextStyle(color: AppColors.onlineGreen, fontSize: 12),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 16),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => setState(() => _selectedFile = null),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Submit Buttons (Regular $9.99 & Fast Track $19.99)
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: _submittingType != null ? null : () => _submitRequest(isFastTrack: false),
                                    child: _submittingType == 'regular'
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : Column(
                                            children: const [
                                              Text(
                                                "Regular Service \$9.99",
                                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                "WITHIN 24 HRS",
                                                style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF7C3AED), // Purple
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: _submittingType != null ? null : () => _submitRequest(isFastTrack: true),
                                    child: _submittingType == 'fast'
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : Column(
                                            children: const [
                                              Text(
                                                "Fast Service \$19.99",
                                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                "WITHIN 1 HR",
                                                style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // ACTIVE READING STATUS & CONVERSATION THREAD
                  if (_isExistingResponse) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.bgDarkCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Reading Request Status",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _hasAdvisorResponse
                                      ? AppColors.onlineGreen.withOpacity(0.15)
                                      : Colors.amber.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _hasAdvisorResponse
                                        ? AppColors.onlineGreen.withOpacity(0.5)
                                        : Colors.amber.withOpacity(0.5),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _hasAdvisorResponse ? AppColors.onlineGreen : Colors.amber,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _hasAdvisorResponse ? "Response Received" : "Awaiting Advisor",
                                      style: TextStyle(
                                        color: _hasAdvisorResponse ? AppColors.onlineGreen : Colors.amber,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Initial Question Card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.bgDarkCardElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderDark),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "YOUR QUESTION",
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentCyan),
                                    ),
                                    if (_quesDate != null)
                                      Text(
                                        DateFormat('dd/MM/yyyy, h:mm a').format(_quesDate!),
                                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryDark),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _specQuestionController.text.isNotEmpty
                                      ? _specQuestionController.text
                                      : "No specific question provided.",
                                  style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                                ),
                              ],
                            ),
                          ),

                          // Waiting Banner if Advisor has not responded yet
                          if (!_hasAdvisorResponse) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber.withOpacity(0.35)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.hourglass_top_rounded, color: Colors.amber, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Waiting for Advisor Response",
                                          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Your reading request is currently with ${widget.advisor.name}. You will see their reading and any clarification messages here once they respond.",
                                          style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 12, height: 1.3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Clarification messages thread
                          if (_conversationMessages.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "💬 Clarifications & Queries",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  "${_conversationMessages.length} message${_conversationMessages.length == 1 ? '' : 's'}",
                                  style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ..._conversationMessages.map((msg) {
                              final isAdv = msg.isAdvisor == true ||
                                  (msg.userId == _getAdvisorId() || msg.advisorLoginId == _getAdvisorId());
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isAdv ? Colors.amber.withOpacity(0.1) : AppColors.onlineGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isAdv ? Colors.amber.withOpacity(0.3) : AppColors.onlineGreen.withOpacity(0.3),
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
                                            Text(
                                              msg.userName ?? (isAdv ? widget.advisor.name : "You"),
                                              style: TextStyle(
                                                color: isAdv ? Colors.amber : AppColors.onlineGreen,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isAdv ? Colors.amber : AppColors.onlineGreen,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                isAdv ? "Advisor Clarification" : "Your Reply",
                                                style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          DateFormat('dd/MM, h:mm a').format(msg.createDate),
                                          style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      msg.messageText,
                                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],

                          // Completed Reading card
                          if (_finalReadingText != null && _finalReadingText!.trim().isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.onlineGreen.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.onlineGreen.withOpacity(0.4)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(Icons.check_circle_rounded, color: AppColors.onlineGreen, size: 18),
                                          SizedBox(width: 6),
                                          Text(
                                            "Advisor's Final Reading",
                                            style: TextStyle(color: AppColors.onlineGreen, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      if (_resDate != null)
                                        Text(
                                          DateFormat('dd/MM/yyyy').format(_resDate!),
                                          style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _finalReadingText!,
                                    style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Customer Reply to Advisor Clarification
                          if (_isAdvisorResponded) ...[
                            const SizedBox(height: 20),
                            const Text(
                              "Reply to Advisor",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "The advisor has asked a question regarding your reading. Please provide your reply below:",
                              style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _queryReplyController,
                              maxLines: 3,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: "Type your reply here...",
                                hintStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
                                filled: true,
                                fillColor: AppColors.bgDarkCardElevated,
                                contentPadding: const EdgeInsets.all(12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderDark)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderDark)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accentGold)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _submittingType != null ? null : _submitCustomerReply,
                                icon: _submittingType == 'reply'
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.send_rounded, size: 16),
                                label: Text(
                                  _submittingType == 'reply' ? "Sending..." : "Send Reply",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildGenderOption(String value, String label) {
    final isSelected = _selectedGender == value;
    return InkWell(
      onTap: _isExistingResponse ? null : () => setState(() => _selectedGender = value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.accentGold : AppColors.textSecondaryDark,
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accentGold,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimaryDark,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
