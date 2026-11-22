import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../models/premium_service_model.dart';
import '../../services/premium_service.dart';
import 'advisor_premium_order_detail_screen.dart';

class AdvisorPremiumRequestsScreen extends StatefulWidget {
  const AdvisorPremiumRequestsScreen({Key? key}) : super(key: key);

  @override
  State<AdvisorPremiumRequestsScreen> createState() => _AdvisorPremiumRequestsScreenState();
}

class _AdvisorPremiumRequestsScreenState extends State<AdvisorPremiumRequestsScreen> {
  final _premiumService = PremiumService();

  bool _isLoading = true;
  String _selectedFilter = 'All'; // All, Pending, Processing, Completed, Cancelled

  List<PremiumRequestModel> _allRequests = [];
  int _pageNumber = 1;
  final int _pageSize = 10;
  int _totalCount = 0;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final res = await _premiumService.getPremiumRequests(pageNumber: _pageNumber, pageSize: _pageSize);
      _allRequests = (res['data'] as List<PremiumRequestModel>?) ?? [];
      _totalCount = (res['totalCount'] as int?) ?? _allRequests.length;
      _totalPages = (res['totalPages'] as int?) ?? 1;
    } catch (e) {
      debugPrint("Error loading advisor premium requests: $e");
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

  Future<void> _handleAcceptOffer(PremiumRequestModel request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgDarkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text("Accept Premium Offer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          "Accept order '${request.title}' for \$${request.price.toStringAsFixed(2)} from ${request.customerDisplayName}?",
          style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondaryDark)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Accept Offer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _premiumService.acceptOffer(request.id);
      if (!mounted) return;
      _showActionCompletedDialog("Offer Accepted", "The premium order has been accepted. You may now perform the service and exchange clarification messages.");
      _loadRequests();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error accepting offer: $e"), backgroundColor: AppColors.errorRed),
      );
    }
  }

  Future<void> _handleMarkCompleted(PremiumRequestModel request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgDarkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text("Mark as Completed", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          "Have you completed the premium service for ${request.customerDisplayName}?",
          style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondaryDark)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E88E5)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Mark Completed", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _premiumService.markCompleted(request.id);
      if (!mounted) return;
      _showActionCompletedDialog("Service Completed", "The premium order has been successfully marked as completed.");
      _loadRequests();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error completing order: $e"), backgroundColor: AppColors.errorRed),
      );
    }
  }

  Future<void> _handleCancelRequest(PremiumRequestModel request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgDarkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text("Cancel Premium Request", style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold)),
        content: Text(
          "Are you sure you want to cancel the request '${request.title}'? The funds will be refunded to the client.",
          style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 13),
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

    try {
      await _premiumService.cancelRequest(request.id);
      if (!mounted) return;
      _showActionCompletedDialog("Request Cancelled", "The request has been cancelled and customer fees refunded.");
      _loadRequests();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error cancelling request: $e"), backgroundColor: AppColors.errorRed),
      );
    }
  }

  void _showActionCompletedDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgDarkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 24),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 13)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGold),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Done", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: text.withOpacity(0.5)),
      ),
      child: Text(status, style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDarkHeader,
        title: const Text("Premium Requests", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
              const Icon(Icons.workspace_premium_outlined, size: 56, color: Colors.white24),
              const SizedBox(height: 16),
              Text(
                _selectedFilter == 'All' ? "No premium requests found" : "No $_selectedFilter requests found",
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "When customers purchase your platinum rituals or services, they will appear here.",
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
        final custPhotoUrl = ApiEndpoints.resolveImageUrl(r.customerPhoto);
        final statusLower = r.status.toLowerCase().trim();

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgDarkCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer & Status Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF2E1A47),
                    backgroundImage: custPhotoUrl.isNotEmpty ? NetworkImage(custPhotoUrl) : null,
                    child: custPhotoUrl.isEmpty
                        ? Text(r.customerDisplayName.isNotEmpty ? r.customerDisplayName[0].toUpperCase() : 'C',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.customerDisplayName,
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
              const SizedBox(height: 10),

              // Service Title & Price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      r.title,
                      style: const TextStyle(color: AppColors.accentGold, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    "\$${r.price.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
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

              // Action Toolbar matching Web Angular
              Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.borderDark),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.visibility_outlined, color: Colors.white, size: 14),
                    label: const Text("Details & Chat", style: TextStyle(color: Colors.white, fontSize: 12)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdvisorPremiumOrderDetailScreen(requestId: r.id),
                        ),
                      ).then((_) => _loadRequests());
                    },
                  ),
                  const Spacer(),

                  // If Pending: Accept Offer & Cancel
                  if (statusLower == 'pending') ...[
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      ),
                      onPressed: () => _handleCancelRequest(r),
                      child: const Text("Cancel", style: TextStyle(color: AppColors.errorRed, fontSize: 12)),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _handleAcceptOffer(r),
                      child: const Text("Accept Offer", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],

                  // If Processing: Mark Completed
                  if (statusLower == 'processing') ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 14),
                      label: const Text("Mark Completed", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () => _handleMarkCompleted(r),
                    ),
                  ],

                  // If Completed
                  if (statusLower == 'completed') ...[
                    Row(
                      children: const [
                        Icon(Icons.check_circle_rounded, color: AppColors.onlineGreen, size: 16),
                        SizedBox(width: 4),
                        Text("Delivered", style: TextStyle(color: AppColors.onlineGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ],
              ),
            ],
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
