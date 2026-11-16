import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/notification_model.dart';
import '../../providers/user_provider.dart';
import '../shared/app_footer_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _activeFilter = 'all'; // 'all', 'unread', 'read'
  bool _isMarkingAll = false;
  final Set<int> _markingIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  void _loadNotifications() {
    final userProv = Provider.of<UserProvider>(context, listen: false);
    userProv.fetchNotifications();
  }

  Future<void> _handleMarkRead(NotificationDto item) async {
    if (item.id <= 0 || _markingIds.contains(item.id)) return;
    setState(() => _markingIds.add(item.id));
    try {
      final userProv = Provider.of<UserProvider>(context, listen: false);
      await userProv.markNotificationAsRead(item.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to mark notification as read')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _markingIds.remove(item.id));
      }
    }
  }

  Future<void> _handleMarkAllRead() async {
    final userProv = Provider.of<UserProvider>(context, listen: false);
    if (userProv.unreadNotificationsCount == 0 || _isMarkingAll) return;
    setState(() => _isMarkingAll = true);
    try {
      await userProv.markAllNotificationsAsRead();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to mark all as read')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isMarkingAll = false);
      }
    }
  }

  String _formatDate(String rawDate) {
    if (rawDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) {
        return 'Just now';
      } else if (diff.inHours < 1) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inDays < 1 && dt.day == now.day) {
        return 'Today, ${DateFormat('hh:mm a').format(dt)}';
      } else if (diff.inDays < 2 && dt.day == now.subtract(const Duration(days: 1)).day) {
        return 'Yesterday, ${DateFormat('hh:mm a').format(dt)}';
      } else {
        return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
      }
    } catch (_) {
      return rawDate;
    }
  }

  IconData _getNotificationIcon(NotificationDto n) {
    final type = n.notificationType;
    final text = '${n.title} ${n.message}'.toLowerCase();

    if (type == 1 || text.contains('chat')) {
      return Icons.chat_bubble_outline_rounded;
    } else if (type == 2 || text.contains('voice') || text.contains('call')) {
      return Icons.phone_in_talk_outlined;
    } else if (type == 3 || text.contains('video')) {
      return Icons.videocam_outlined;
    } else if (text.contains('wallet') || text.contains('payment') || text.contains('recharge') || text.contains('balance') || text.contains('fund')) {
      return Icons.account_balance_wallet_outlined;
    } else if (text.contains('review') || text.contains('rating')) {
      return Icons.star_outline_rounded;
    }
    return Icons.notifications_none_rounded;
  }

  Color _getIconBackgroundColor(NotificationDto n) {
    if (n.isRead) return const Color(0xFFF1F5F9);
    final type = n.notificationType;
    final text = '${n.title} ${n.message}'.toLowerCase();

    if (type == 1 || text.contains('chat')) {
      return const Color(0xFFEFF6FF); // blue
    } else if (type == 2 || text.contains('voice') || text.contains('call')) {
      return const Color(0xFFF0FDF4); // green
    } else if (type == 3 || text.contains('video')) {
      return const Color(0xFFFAF5FF); // purple
    } else if (text.contains('wallet') || text.contains('payment')) {
      return const Color(0xFFFEF3C7); // amber
    }
    return const Color(0xFFF1F5F9);
  }

  Color _getIconColor(NotificationDto n) {
    if (n.isRead) return const Color(0xFF64748B);
    final type = n.notificationType;
    final text = '${n.title} ${n.message}'.toLowerCase();

    if (type == 1 || text.contains('chat')) {
      return const Color(0xFF2563EB); // blue
    } else if (type == 2 || text.contains('voice') || text.contains('call')) {
      return const Color(0xFF16A34A); // green
    } else if (type == 3 || text.contains('video')) {
      return const Color(0xFF9333EA); // purple
    } else if (text.contains('wallet') || text.contains('payment')) {
      return const Color(0xFFD97706); // amber
    }
    return const Color(0xFF4F46E5);
  }

  @override
  Widget build(BuildContext context) {
    final userProv = Provider.of<UserProvider>(context);
    final allNotifications = userProv.notifications;
    final unreadCount = userProv.unreadNotificationsCount;
    final readCount = allNotifications.length - unreadCount;
    final isLoading = userProv.isLoading && allNotifications.isEmpty;

    final filteredList = allNotifications.where((n) {
      if (_activeFilter == 'unread') return !n.isRead;
      if (_activeFilter == 'read') return n.isRead;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Web app slate-50 background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Color(0xFF0F172A),
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Reload',
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
            onPressed: _loadNotifications,
          ),
          if (unreadCount > 0)
            IconButton(
              tooltip: 'Mark all read',
              icon: _isMarkingAll
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
                    )
                  : const Icon(Icons.done_all_rounded, color: Color(0xFF4F46E5)),
              onPressed: _handleMarkAllRead,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadNotifications(),
        color: const Color(0xFF4F46E5),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Card container matching Angular web app
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Action Row: Reload + Mark all read (matching Angular notifications.component.html)
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  // Left side buttons
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: _loadNotifications,
                                        icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF334155)),
                                        label: const Text(
                                          'Reload',
                                          style: TextStyle(
                                            color: Color(0xFF334155),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: unreadCount > 0 && !_isMarkingAll ? _handleMarkAllRead : null,
                                        icon: _isMarkingAll
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
                                              )
                                            : Icon(
                                                Icons.done_all_rounded,
                                                size: 16,
                                                color: unreadCount > 0 ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
                                              ),
                                        label: Text(
                                          'Mark all read',
                                          style: TextStyle(
                                            color: unreadCount > 0 ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: unreadCount > 0 ? const Color(0xFFC7D2FE) : const Color(0xFFE2E8F0),
                                          ),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Right side filter chips
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      _buildFilterChip('All', 'all', allNotifications.length),
                                      _buildFilterChip('Unread', 'unread', unreadCount),
                                      _buildFilterChip('Read', 'read', readCount),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),
                              const Divider(color: Color(0xFFF1F5F9), height: 1),
                              const SizedBox(height: 8),

                              // Content State
                              if (isLoading)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 48),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF4F46E5),
                                    ),
                                  ),
                                )
                              else if (filteredList.isEmpty)
                                _buildEmptyState(allNotifications.isEmpty)
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filteredList.length,
                                  separatorBuilder: (_, __) => const Divider(
                                    color: Color(0xFFF1F5F9),
                                    height: 1,
                                    indent: 52,
                                  ),
                                  itemBuilder: (ctx, i) => _buildNotificationTile(filteredList[i]),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const AppFooterWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String key, int count) {
    final isSelected = _activeFilter == key;
    return InkWell(
      onTap: () => setState(() => _activeFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(NotificationDto n) {
    final isMarking = _markingIds.contains(n.id);
    final dateStr = _formatDate(n.createdAt);

    return Opacity(
      opacity: n.isRead ? 0.65 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _getIconBackgroundColor(n),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getNotificationIcon(n),
                size: 20,
                color: _getIconColor(n),
              ),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Head: Sender Name + Date (matching Angular note-head)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          n.senderName.isNotEmpty ? n.senderName : 'System',
                          style: TextStyle(
                            fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w700,
                            fontSize: 14,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (dateStr.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Body: notificationDetail (matching Angular note-body)
                  Text(
                    n.message.isNotEmpty ? n.message : 'No additional details.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: n.isRead ? const Color(0xFF64748B) : const Color(0xFF334155),
                    ),
                  ),

                  // Action: Mark read button if unread (matching Angular)
                  if (!n.isRead && n.id > 0) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: isMarking ? null : () => _handleMarkRead(n),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isMarking)
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
                              )
                            else
                              const Icon(Icons.check_rounded, size: 14, color: Color(0xFF4F46E5)),
                            const SizedBox(width: 4),
                            const Text(
                              'Mark read',
                              style: TextStyle(
                                color: Color(0xFF4F46E5),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isCompletelyEmpty) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 36,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isCompletelyEmpty
                ? 'No notifications.'
                : 'No ${_activeFilter.toLowerCase()} notifications.',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isCompletelyEmpty
                ? 'When you receive messages, call invites, or updates, they will appear here.'
                : 'Switch filters or reload to see other notifications.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Reload'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4F46E5),
              side: const BorderSide(color: Color(0xFFC7D2FE)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
