import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../providers/user_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProv = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: "Mark all as read",
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("All notifications marked as read")),
              );
            },
          ),
        ],
      ),
      body: userProv.notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.notifications_none_rounded, size: 64, color: AppColors.textSecondaryDark),
                  SizedBox(height: 12),
                  Text("No new notifications", style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: AppStyles.paddingPage,
              itemCount: userProv.notifications.length,
              itemBuilder: (ctx, i) {
                final notif = userProv.notifications[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: AppStyles.paddingCard,
                  decoration: BoxDecoration(
                    color: notif.isRead ? AppColors.bgDarkCard : AppColors.bgDarkCardElevated,
                    borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
                    border: Border.all(color: notif.isRead ? AppColors.borderDark : AppColors.primary),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        notif.isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
                        color: notif.isRead ? AppColors.textSecondaryDark : AppColors.accentGold,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(notif.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text(notif.message, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
