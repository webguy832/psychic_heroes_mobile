import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/services/audio_service.dart';
import '../../models/premium_service_model.dart';
import '../../models/text_reading_model.dart';
import '../../providers/user_provider.dart';
import '../../services/premium_service.dart';

class CustomerPremiumRequestsScreen extends StatefulWidget {
  const CustomerPremiumRequestsScreen({Key? key}) : super(key: key);

  @override
  State<CustomerPremiumRequestsScreen> createState() => _CustomerPremiumRequestsScreenState();
}

class _CustomerPremiumRequestsScreenState extends State<CustomerPremiumRequestsScreen> {
  final _premiumService = PremiumService();

  bool _isLoading = true;
  String _selectedFilter = 'All'; // All, Pending, Processing, Completed, Cancelled

  List<PremiumRequestModel> _allRequests = [];
  int _pageNumber = 1;
  final int _pageSize = 10;
  int _totalCount = 0;
  int _totalPages = 1;
  Timer? _listPollTimer;

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _listPollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted) _silentPollRequests();
    });
  }

  @override
  void dispose() {
    _listPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _silentPollRequests() async {
    try {
      final res = await _premiumService.getPremiumRequests(pageNumber: _pageNumber, pageSize: _pageSize);
      if (!mounted) return;
      final newRequests = (res['data'] as List<PremiumRequestModel>?) ?? [];
      final newCount = (res['totalCount'] as int?) ?? newRequests.length;
      final newPages = (res['totalPages'] as int?) ?? 1;
      setState(() {
        _allRequests = newRequests;
        _totalCount = newCount;
        _totalPages = newPages;
      });
    } catch (_) {}
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final res = await _premiumService.getPremiumRequests(pageNumber: _pageNumber, pageSize: _pageSize);
      _allRequests = (res['data'] as List<PremiumRequestModel>?) ?? [];
      _totalCount = (res['totalCount'] as int?) ?? _allRequests.length;
      _totalPages = (res['totalPages'] as int?) ?? 1;
    } catch (e) {
      debugPrint("Error loading customer premium requests: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<PremiumRequestModel> get _filteredRequests {
    if (_selectedFilter == 'All') return _allRequests;
    return _allRequests.where((r) {
      final st = r.status.toLowerCase().trim();
      return st == _selectedFilter.toLowerCase().trim();
    }).toList();
  }

  void _openConversationSheet(PremiumRequestModel request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PremiumConversationSheet(
        request: request,
        premiumService: _premiumService,
      ),
    );
  }

  void _openDetailsSheet(PremiumRequestModel request) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgDarkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      request.title,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildStatusBadge(request.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person_outline, color: AppColors.accentGold, size: 16),
                  const SizedBox(width: 6),
                  Text("Advisor: ${request.advisorDisplayName}", style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 14)),
                  const Spacer(),
                  Text("\$${request.price.toStringAsFixed(2)}", style: const TextStyle(color: AppColors.accentGold, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "Ordered on: ${DateFormat('MMM dd, yyyy • hh:mm a').format(request.createdOn)}",
                style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
              ),
              if (request.completedOn != null) ...[
                const SizedBox(height: 4),
                Text(
                  "Completed on: ${DateFormat('MMM dd, yyyy • hh:mm a').format(request.completedOn!)}",
                  style: const TextStyle(color: AppColors.onlineGreen, fontSize: 12),
                ),
              ],
              const Divider(color: AppColors.borderDark, height: 24),
              const Text("Service Details", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                request.serviceDescription.isNotEmpty ? request.serviceDescription : "No additional description provided.",
                style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGold,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.black, size: 18),
                  label: const Text("Open Clarification Chat", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openConversationSheet(request);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    IconData icon;

    switch (status.toLowerCase().trim()) {
      case 'pending':
        bg = Colors.amber.withOpacity(0.18);
        text = Colors.amber;
        icon = Icons.hourglass_top_rounded;
        break;
      case 'processing':
        bg = Colors.blue.withOpacity(0.18);
        text = Colors.lightBlueAccent;
        icon = Icons.sync_rounded;
        break;
      case 'completed':
        bg = Colors.green.withOpacity(0.18);
        text = Colors.greenAccent;
        icon = Icons.check_circle_rounded;
        break;
      case 'cancelled':
        bg = Colors.red.withOpacity(0.18);
        text = Colors.redAccent;
        icon = Icons.cancel_outlined;
        break;
      default:
        bg = Colors.white12;
        text = Colors.white;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: text.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: text, size: 12),
          const SizedBox(width: 4),
          Text(status, style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDarkHeader,
        title: const Text("My Premium Orders", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.accentGold),
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          _buildFilterTabs(),

          // Request List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accentGold))
                : RefreshIndicator(
                    onRefresh: _loadRequests,
                    color: AppColors.accentGold,
                    child: _filteredRequests.isEmpty ? _buildEmptyState() : _buildRequestList(),
                  ),
          ),

          // Pagination Bar
          if (!_isLoading && _totalPages > 1) _buildPaginationBar(),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['All', 'Pending', 'Processing', 'Completed', 'Cancelled'];

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      color: AppColors.bgDarkCard,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = _selectedFilter == f;
          return ChoiceChip(
            label: Text(f),
            selected: isSelected,
            selectedColor: AppColors.accentGold,
            backgroundColor: AppColors.bgDark,
            labelStyle: TextStyle(
              color: isSelected ? Colors.black : AppColors.textSecondaryDark,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (_) => setState(() => _selectedFilter = f),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.diamond_outlined, size: 56, color: Colors.white24),
              const SizedBox(height: 16),
              Text(
                _selectedFilter == 'All' ? "No premium orders found" : "No $_selectedFilter orders found",
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Orders placed for custom platinum rituals and services appear here.",
                style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequestList() {
    final list = _filteredRequests;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final r = list[index];
        final advPhotoUrl = ApiEndpoints.resolveImageUrl(r.advisorPhoto);

        return InkWell(
          onTap: () => _openDetailsSheet(r),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgDarkCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary,
                      backgroundImage: advPhotoUrl.isNotEmpty ? NetworkImage(advPhotoUrl) : null,
                      child: advPhotoUrl.isEmpty
                          ? Text(r.advisorDisplayName.isNotEmpty ? r.advisorDisplayName[0].toUpperCase() : 'A',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.advisorDisplayName,
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('MMM dd, yyyy • hh:mm a').format(r.createdOn),
                            style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(r.status),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  r.title,
                  style: const TextStyle(color: AppColors.accentGold, fontSize: 15, fontWeight: FontWeight.w600),
                ),
                if (r.serviceDescription.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    r.serviceDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 12, height: 1.3),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      "\$${r.price.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.accentGold),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.accentGold, size: 14),
                      label: const Text(
                        "Messages",
                        style: TextStyle(color: AppColors.accentGold, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _openConversationSheet(r),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaginationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.bgDarkCard,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: _pageNumber > 1
                ? () {
                    setState(() => _pageNumber--);
                    _loadRequests();
                  }
                : null,
          ),
          Text(
            "Page $_pageNumber of $_totalPages",
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: _pageNumber < _totalPages
                ? () {
                    setState(() => _pageNumber++);
                    _loadRequests();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

/// Conversation Bottom Sheet for customer <-> advisor clarification messaging (EntityType 1)
class _PremiumConversationSheet extends StatefulWidget {
  final PremiumRequestModel request;
  final PremiumService premiumService;

  const _PremiumConversationSheet({
    Key? key,
    required this.request,
    required this.premiumService,
  }) : super(key: key);

  @override
  State<_PremiumConversationSheet> createState() => _PremiumConversationSheetState();
}

class _PremiumConversationSheetState extends State<_PremiumConversationSheet> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isSending = false;
  List<ServiceMessageModel> _messages = [];
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _silentPollMessages());
  }

  Future<void> _silentPollMessages() async {
    if (!mounted) return;
    try {
      final res = await widget.premiumService.getServiceMessages(widget.request.id);
      if (!mounted) return;
      if (res.length > _messages.length) {
        final hasNewAdvisorMsg = res.skip(_messages.length).any((m) => m.isAdvisor == true);
        if (hasNewAdvisorMsg) {
          AudioService.playMessageChime();
        }
        setState(() {
          _messages = res;
        });
        _scrollToBottom();
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final res = await widget.premiumService.getServiceMessages(widget.request.id);
      _messages = res;
      _scrollToBottom();
    } catch (e) {
      debugPrint("Error loading service messages: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final userProv = Provider.of<UserProvider>(context, listen: false);
    final user = userProv.user;
    final userName = user?.displayName ?? user?.screenName ?? "Customer";
    final userId = user?.id ?? widget.request.userId;

    // Optimistic UI Append - Message shows immediately with zero wait!
    final localMsg = ServiceMessageModel(
      id: DateTime.now().millisecondsSinceEpoch,
      entityId: widget.request.id,
      entityTypeId: 1,
      messageText: text,
      userId: userId,
      userName: userName,
      isAdvisor: false,
      createDate: DateTime.now(),
    );

    setState(() {
      _messages.add(localMsg);
      _isSending = true;
    });
    _messageController.clear();
    _scrollToBottom();

    final payload = {
      'requestId': widget.request.id,
      'messageText': text,
      'entityTypeId': 1, // 1 for premium service
      'entityId': widget.request.id,
      'clientId': userId,
      'userName': userName,
      'advisorLoginId': widget.request.advisorUserId,
    };

    try {
      await widget.premiumService.createServiceMessage(payload);
      final res = await widget.premiumService.getServiceMessages(widget.request.id);
      if (mounted) {
        setState(() => _messages = res);
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send message: $e"), backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.bgDarkCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderDark)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Clarification with ${widget.request.advisorDisplayName}",
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.request.title,
                        style: const TextStyle(color: AppColors.accentGold, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Message Thread
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accentGold))
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.forum_outlined, color: Colors.white24, size: 48),
                            SizedBox(height: 12),
                            Text("No clarification messages yet.", style: TextStyle(color: AppColors.textSecondaryDark)),
                            SizedBox(height: 4),
                            Text("You or your advisor can post queries here.", style: TextStyle(color: Colors.white38, fontSize: 11)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, idx) {
                          final msg = _messages[idx];
                          final isMe = !(msg.isAdvisor == true);
                          final senderName = isMe
                              ? "You"
                              : ((msg.userName != null && msg.userName!.isNotEmpty)
                                  ? msg.userName!
                                  : widget.request.advisorDisplayName);

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.all(12),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                              decoration: BoxDecoration(
                                color: isMe ? const Color(0xFF2E7D32) : const Color(0xFF24153E),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isMe ? Colors.green.shade400 : AppColors.borderDark),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        senderName,
                                        style: TextStyle(
                                          color: isMe ? Colors.white : AppColors.accentGold,
                                          fontSize: 11,
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
                                  const SizedBox(height: 4),
                                  Text(
                                    msg.messageText,
                                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Composer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.bgDark,
              border: Border(top: BorderSide(color: AppColors.borderDark)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "Reply to advisor...",
                      hintStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: AppColors.bgDarkCard,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isSending
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.accentGold, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, color: AppColors.accentGold),
                  onPressed: _isSending ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
