import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/text_reading_model.dart';
import '../../providers/user_provider.dart';
import '../../services/text_reading_service.dart';

class AdvisorTextReadingReplyScreen extends StatefulWidget {
  final int requestId;

  const AdvisorTextReadingReplyScreen({
    Key? key,
    required this.requestId,
  }) : super(key: key);

  @override
  State<AdvisorTextReadingReplyScreen> createState() => _AdvisorTextReadingReplyScreenState();
}

class _AdvisorTextReadingReplyScreenState extends State<AdvisorTextReadingReplyScreen> {
  final _service = TextReadingService();

  final _clarificationController = TextEditingController();
  final _finalReadingController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;

  bool _isRaiseQueryOpen = false;
  bool _isFinalSubmissionOpen = false;

  TextReadingModel? _textReading;
  List<ServiceMessageModel> _conversationMessages = [];

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void dispose() {
    _clarificationController.dispose();
    _finalReadingController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    try {
      final details = await _service.getTextReadingById(widget.requestId);
      _textReading = details;

      if (details != null && details.finalReadingText != null) {
        _finalReadingController.text = details.finalReadingText!;
      }

      final messages = await _service.getServiceMessages(widget.requestId, entityType: 2);
      _conversationMessages = messages;
    } catch (e) {
      debugPrint("Error loading reading details: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitClarificationQuery() async {
    final queryText = _clarificationController.text.trim();
    if (queryText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write your clarification query.")),
      );
      return;
    }

    final userProv = Provider.of<UserProvider>(context, listen: false);
    final user = userProv.user;
    final advisorName = user?.displayName ?? user?.screenName ?? "Advisor";
    final advisorId = user?.id ?? "";

    setState(() => _isSubmitting = true);

    final payload = {
      'MessageText': queryText,
      'EntityTypeId': 2,
      'EntityId': widget.requestId,
      'ClientId': _textReading?.userId ?? "",
      'AdvisorLoginId': advisorId,
      'UserName': advisorName,
      'IsAdvisor': true,
    };

    try {
      await _service.createServiceMessage(payload);
      if (!mounted) return;
      _clarificationController.clear();
      _isRaiseQueryOpen = false;
      _showClarificationSentDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send query: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitFinalReading() async {
    final finalText = _finalReadingController.text.trim();
    if (finalText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write your final reading text.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _service.submitFinalTextReading(
        id: widget.requestId,
        text: finalText,
      );
      if (!mounted) return;
      _isFinalSubmissionOpen = false;
      _isRaiseQueryOpen = false;
      _showFinalReadingCompletedDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Submission failed: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showFinalReadingCompletedDialog() {
    final clientName = _textReading?.customerName.isNotEmpty == true ? _textReading!.customerName : "Customer";
    final priceStr = _textReading != null ? "\$${_textReading!.price.toStringAsFixed(2)}" : "\$9.99";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgDarkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.onlineGreen, width: 2),
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
              child: const Icon(Icons.check_circle_rounded, color: AppColors.onlineGreen, size: 50),
            ),
            const SizedBox(height: 18),
            const Text(
              "Reading Completed!",
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "Your final reading has been successfully delivered to $clientName. The order is now completed and $priceStr has been credited to your account.",
              style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.onlineGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.black, size: 18),
                label: const Text(
                  "Return to Requests List",
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context, true);
                },
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _loadDetails();
              },
              child: const Text(
                "Stay & View Completed Reading",
                style: TextStyle(color: AppColors.accentGold, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClarificationSentDialog() {
    final clientName = _textReading?.customerName.isNotEmpty == true ? _textReading!.customerName : "Customer";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgDarkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.amber, width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: const Icon(Icons.help_outline_rounded, color: Colors.amber, size: 44),
            ),
            const SizedBox(height: 18),
            const Text(
              "Clarification Query Sent!",
              style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "Your query has been sent to $clientName. The reading request remains in progress and you will be notified when they reply.",
              style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB45309), // Amber-700
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                label: const Text(
                  "Back to Requests List",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context, true);
                },
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _loadDetails();
              },
              child: const Text(
                "Stay on Thread",
                style: TextStyle(color: AppColors.accentGold, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProv = Provider.of<UserProvider>(context);
    final currentAdvisorId = userProv.user?.id ?? "";

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDarkCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Reading Request #${widget.requestId}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGold)))
          : _textReading == null
              ? const Center(child: Text("Reading request not found.", style: TextStyle(color: Colors.white70)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card with POI & Client Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.bgDarkCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person_pin_rounded, color: AppColors.accentGold, size: 22),
                                    const SizedBox(width: 8),
                                    Text(
                                      _textReading!.customerName.isNotEmpty
                                          ? _textReading!.customerName
                                          : "Client Request",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _textReading!.isCompleted
                                        ? AppColors.onlineGreen.withOpacity(0.15)
                                        : Colors.amber.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _textReading!.isCompleted
                                          ? AppColors.onlineGreen.withOpacity(0.5)
                                          : Colors.amber.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Text(
                                    _textReading!.isCompleted ? "COMPLETED" : "IN PROGRESS",
                                    style: TextStyle(
                                      color: _textReading!.isCompleted ? AppColors.onlineGreen : Colors.amber,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: AppColors.borderDark, height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailTile(
                                    label: "DOB of POI",
                                    value: _textReading!.dob != null
                                        ? DateFormat('dd/MM/yyyy').format(_textReading!.dob!)
                                        : "Not provided",
                                    icon: Icons.cake_rounded,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDetailTile(
                                    label: "Request Date",
                                    value: _textReading!.createdOn != null
                                        ? DateFormat('dd/MM, h:mm a').format(_textReading!.createdOn!)
                                        : "Recent",
                                    icon: Icons.calendar_today_rounded,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailTile(
                                    label: "Gender",
                                    value: _textReading!.gender.toUpperCase(),
                                    icon: Icons.wc_rounded,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDetailTile(
                                    label: "Price / Earnings",
                                    value: "\$${_textReading!.price.toStringAsFixed(2)}",
                                    icon: Icons.payments_rounded,
                                    valueColor: AppColors.onlineGreen,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Customer Question Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.bgDarkCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "SPECIFIC QUESTION",
                              style: TextStyle(color: AppColors.accentCyan, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _textReading!.specQuestion != null && _textReading!.specQuestion!.isNotEmpty
                                  ? _textReading!.specQuestion!
                                  : "No specific question provided.",
                              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // General Description Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.bgDarkCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "GENERAL SITUATION & CONTEXT",
                              style: TextStyle(color: AppColors.accentGold, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _textReading!.generalDescription,
                              style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 13, height: 1.4),
                            ),
                          ],
                        ),
                      ),

                      // Attachment if present
                      if (_textReading!.photoUrl != null && _textReading!.photoUrl!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.bgDarkCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderDark),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.attach_file_rounded, color: AppColors.accentCyan, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Attachment: ${_textReading!.photoUrl!.split('/').last}",
                                  style: const TextStyle(color: AppColors.accentCyan, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Conversation & Clarifications thread
                      if (_conversationMessages.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "💬 Conversation & Clarifications",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
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
                              (msg.userId == currentAdvisorId || msg.advisorLoginId == currentAdvisorId);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isAdv ? Colors.amber.withOpacity(0.1) : AppColors.onlineGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isAdv ? Colors.amber.withOpacity(0.35) : AppColors.onlineGreen.withOpacity(0.35),
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
                                          isAdv ? "You (Advisor)" : (msg.userName ?? "Customer"),
                                          style: TextStyle(
                                            color: isAdv ? Colors.amber : AppColors.onlineGreen,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isAdv ? Colors.amber : AppColors.onlineGreen,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isAdv ? "Advisor Clarification Query" : "Customer Response",
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
                                const SizedBox(height: 8),
                                Text(
                                  msg.messageText,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],

                      // Completed Reading Display
                      if (_textReading!.isCompleted && _textReading!.finalReadingText != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.onlineGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.onlineGreen.withOpacity(0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.check_circle_rounded, color: AppColors.onlineGreen, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    "Completed Reading Delivered",
                                    style: TextStyle(color: AppColors.onlineGreen, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _textReading!.finalReadingText!,
                                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Action Buttons for In-Progress Reading
                      if (!_textReading!.isCompleted) ...[
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isRaiseQueryOpen ? Colors.amber.shade700 : AppColors.bgDarkCardElevated,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: _isRaiseQueryOpen ? Colors.amber : Colors.amber.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isRaiseQueryOpen = !_isRaiseQueryOpen;
                                    _isFinalSubmissionOpen = false;
                                  });
                                },
                                child: Text(
                                  "Ask Clarification Query",
                                  style: TextStyle(
                                    color: _isRaiseQueryOpen ? Colors.black : Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isFinalSubmissionOpen ? AppColors.onlineGreen : AppColors.bgDarkCardElevated,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: _isFinalSubmissionOpen ? AppColors.onlineGreen : AppColors.onlineGreen.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isFinalSubmissionOpen = !_isFinalSubmissionOpen;
                                    _isRaiseQueryOpen = false;
                                  });
                                },
                                child: Text(
                                  "Submit Final Reading",
                                  style: TextStyle(
                                    color: _isFinalSubmissionOpen ? Colors.black : AppColors.onlineGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Expandable Clarification Query Box
                        if (_isRaiseQueryOpen) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.amber.withOpacity(0.4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Clarification Query to Customer",
                                      style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        "Keeps Reading In Progress",
                                        style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Ask the customer a question if you need more details. This will NOT complete the order.",
                                  style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 11),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _clarificationController,
                                  maxLines: 3,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: "Write your clarification query for the customer...",
                                    hintStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
                                    filled: true,
                                    fillColor: AppColors.bgDark,
                                    contentPadding: const EdgeInsets.all(12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderDark)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderDark)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.amber)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber.shade700,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: _isSubmitting ? null : _submitClarificationQuery,
                                    child: _isSubmitting
                                        ? const SizedBox(
                                            height: 16,
                                            width: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                          )
                                        : const Text(
                                            "Send Query to Customer",
                                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Expandable Final Submission Box
                        if (_isFinalSubmissionOpen) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.onlineGreen.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.onlineGreen.withOpacity(0.4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Final Reading Submission",
                                      style: TextStyle(color: AppColors.onlineGreen, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.onlineGreen.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        "Completes Order",
                                        style: TextStyle(color: AppColors.onlineGreen, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Provide your completed reading. Submitting this delivers your answer, completes the order, and credits your account.",
                                  style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 11),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _finalReadingController,
                                  maxLines: 6,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: "Write your complete final reading submission...",
                                    hintStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
                                    filled: true,
                                    fillColor: AppColors.bgDark,
                                    contentPadding: const EdgeInsets.all(12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderDark)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderDark)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.onlineGreen)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.onlineGreen,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: _isSubmitting ? null : _submitFinalReading,
                                    child: _isSubmitting
                                        ? const SizedBox(
                                            height: 16,
                                            width: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                          )
                                        : const Text(
                                            "Submit Final Reading & Complete",
                                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailTile({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bgDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.accentGold),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: valueColor ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
