import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../models/premium_service_model.dart';
import '../../models/text_reading_model.dart';
import '../../providers/user_provider.dart';
import '../../services/premium_service.dart';

class AdvisorPremiumOrderDetailScreen extends StatefulWidget {
  final int requestId;

  const AdvisorPremiumOrderDetailScreen({
    Key? key,
    required this.requestId,
  }) : super(key: key);

  @override
  State<AdvisorPremiumOrderDetailScreen> createState() => _AdvisorPremiumOrderDetailScreenState();
}

class _AdvisorPremiumOrderDetailScreenState extends State<AdvisorPremiumOrderDetailScreen> {
  final _premiumService = PremiumService();
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isSendingMessage = false;
  bool _isActing = false;

  PremiumRequestModel? _request;
  List<ServiceMessageModel> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    try {
      final req = await _premiumService.getPremiumRequestDetail(widget.requestId);
      _request = req;

      final msgs = await _premiumService.getServiceMessages(widget.requestId);
      _messages = msgs;
    } catch (e) {
      debugPrint("Error loading premium request detail: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _request == null) return;

    final userProv = Provider.of<UserProvider>(context, listen: false);
    final user = userProv.user;
    final advisorName = user?.displayName ?? user?.screenName ?? "Advisor";
    final advisorId = user?.id ?? _request!.advisorUserId;

    setState(() => _isSendingMessage = true);

    final payload = {
      'requestId': widget.requestId,
      'messageText': text,
      'entityTypeId': 1, // 1 for premium service
      'entityId': widget.requestId,
      'clientId': _request!.userId,
      'userName': advisorName,
      'advisorLoginId': advisorId,
      'isAdvisor': true,
    };

    try {
      await _premiumService.createServiceMessage(payload);
      _messageController.clear();
      final msgs = await _premiumService.getServiceMessages(widget.requestId);
      setState(() => _messages = msgs);
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send message: $e"), backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingMessage = false);
    }
  }

  Future<void> _handleAccept() async {
    setState(() => _isActing = true);
    try {
      await _premiumService.acceptOffer(widget.requestId);
      if (!mounted) return;
      _showCompletionDialog("Offer Accepted", "You have accepted this premium order. You may now perform the service and exchange clarification messages with the customer.");
      _loadDetails();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error accepting offer: $e"), backgroundColor: AppColors.errorRed),
      );
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _handleMarkCompleted() async {
    setState(() => _isActing = true);
    try {
      await _premiumService.markCompleted(widget.requestId);
      if (!mounted) return;
      _showCompletionDialog("Order Completed", "The premium service order has been marked as completed.");
      _loadDetails();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error completing order: $e"), backgroundColor: AppColors.errorRed),
      );
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _handleCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgDarkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text("Cancel Request", style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold)),
        content: const Text(
          "Are you sure you want to cancel this order? The funds will be refunded to the customer.",
          style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("No, Keep", style: TextStyle(color: AppColors.textSecondaryDark)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Yes, Cancel", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isActing = true);
    try {
      await _premiumService.cancelRequest(widget.requestId);
      if (!mounted) return;
      _showCompletionDialog("Request Cancelled", "The request has been cancelled and customer fees refunded.");
      _loadDetails();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error cancelling order: $e"), backgroundColor: AppColors.errorRed),
      );
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  void _showCompletionDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgDarkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 26),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 13, height: 1.4)),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.textSecondaryDark),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Return to list
            },
            child: const Text("Done & Return", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGold,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Stay & View", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;

    switch (status.toLowerCase().trim()) {
      case 'pending':
        bg = Colors.amber.withOpacity(0.18);
        text = Colors.amber;
        break;
      case 'processing':
        bg = Colors.blue.withOpacity(0.18);
        text = Colors.lightBlueAccent;
        break;
      case 'completed':
        bg = Colors.green.withOpacity(0.18);
        text = Colors.greenAccent;
        break;
      case 'cancelled':
        bg = Colors.red.withOpacity(0.18);
        text = Colors.redAccent;
        break;
      default:
        bg = Colors.white12;
        text = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: text.withOpacity(0.5)),
      ),
      child: Text(status, style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDarkHeader,
        title: Text("Premium Order #${widget.requestId}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentGold))
          : _request == null
              ? const Center(child: Text("Request not found", style: TextStyle(color: Colors.white)))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Customer Header Card
                            _buildCustomerHeader(),

                            const SizedBox(height: 16),

                            // Service Details Card
                            _buildServiceCard(),

                            const SizedBox(height: 16),

                            // Clarification & Messages Section
                            _buildMessagesSection(),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Action Bar
                    _buildBottomActionBar(),
                  ],
                ),
    );
  }

  Widget _buildCustomerHeader() {
    final r = _request!;
    final custPhotoUrl = ApiEndpoints.resolveImageUrl(r.customerPhoto);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgDarkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF2E1A47),
            backgroundImage: custPhotoUrl.isNotEmpty ? NetworkImage(custPhotoUrl) : null,
            child: custPhotoUrl.isEmpty
                ? Text(r.customerDisplayName.isNotEmpty ? r.customerDisplayName[0].toUpperCase() : 'C',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.customerDisplayName,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  "Order placed ${DateFormat('MMM dd, yyyy • hh:mm a').format(r.createdOn)}",
                  style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11),
                ),
              ],
            ),
          ),
          _buildStatusBadge(r.status),
        ],
      ),
    );
  }

  Widget _buildServiceCard() {
    final r = _request!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E1A47), Color(0xFF1E1035)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.accentGold, borderRadius: BorderRadius.circular(6)),
                child: const Text("SERVICE ORDER", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              Text(
                "\$${r.price.toStringAsFixed(2)}",
                style: const TextStyle(color: AppColors.accentGold, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(r.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          if (r.serviceDescription.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              r.serviceDescription,
              style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 13, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessagesSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgDarkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.accentGold, size: 18),
                const SizedBox(width: 8),
                const Text(
                  "Clarification Messages",
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  "${_messages.length} messages",
                  style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.borderDark, height: 1),

          // Message List
          if (_messages.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Center(
                child: Text(
                  "No clarification messages yet.\nYou can send a question or update to the customer below.",
                  style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, idx) {
                final msg = _messages[idx];
                final isAdvisor = msg.isAdvisor;

                return Align(
                  alignment: isAdvisor ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isAdvisor ? const Color(0xFF2E7D32) : const Color(0xFF24153E),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isAdvisor ? Colors.green.shade400 : AppColors.borderDark),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isAdvisor ? "You (Advisor)" : msg.userName,
                              style: TextStyle(
                                color: isAdvisor ? Colors.white : AppColors.accentGold,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('hh:mm a').format(msg.createDate),
                              style: const TextStyle(color: Colors.white54, fontSize: 9),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          msg.messageText,
                          style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // Composer
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "Send message to customer...",
                      hintStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: AppColors.bgDark,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isSendingMessage
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: AppColors.accentGold, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, color: AppColors.accentGold),
                  onPressed: _isSendingMessage ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    final status = _request?.status.toLowerCase().trim() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.bgDarkCard,
        border: Border(top: BorderSide(color: AppColors.borderDark)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (status == 'pending') ...[
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.errorRed),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isActing ? null : _handleCancel,
                  child: const Text("Cancel Request", style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: _isActing
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_rounded, color: Colors.white),
                  label: const Text("Accept Offer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: _isActing ? null : _handleAccept,
                ),
              ),
            ] else if (status == 'processing') ...[
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: _isActing
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.task_alt_rounded, color: Colors.white),
                  label: const Text("Mark as Completed", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  onPressed: _isActing ? null : _handleMarkCompleted,
                ),
              ),
            ] else if (status == 'completed') ...[
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.greenAccent),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.check_circle_rounded, color: AppColors.onlineGreen, size: 20),
                      SizedBox(width: 8),
                      Text("Delivered & Completed", style: TextStyle(color: AppColors.onlineGreen, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ] else if (status == 'cancelled') ...[
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.cancel_outlined, color: AppColors.errorRed, size: 20),
                      SizedBox(width: 8),
                      Text("Cancelled", style: TextStyle(color: AppColors.errorRed, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
