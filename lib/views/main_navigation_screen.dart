import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/navigation_provider.dart';
import '../providers/user_provider.dart';
import 'menu/app_drawer_menu.dart';
import 'home/home_screen.dart';
import 'advisors/advisor_dashboard_screen.dart';
import 'user/profile_screen.dart';
import 'user/notifications_screen.dart';
import 'menu_pages/advisor_messages_screen.dart';
import 'menu_pages/reading_history_screen.dart';
import 'menu_pages/my_services_screen.dart';
import 'menu_pages/wallet_screen.dart';
import 'shared/app_logo.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  @override
  Widget build(BuildContext context) {
    final nav = Provider.of<NavigationProvider>(context);
    final userProv = Provider.of<UserProvider>(context);
    final isAdvisor = userProv.isAdvisor;

    // 5 Screens matching Pocket Insight Architecture: Insight, Service, Inbox, Prediction, Mine
    final List<Widget> screens = isAdvisor
        ? const [
            AdvisorDashboardScreen(),
            MyServicesScreen(),
            AdvisorMessagesScreen(),
            ReadingHistoryScreen(),
            ProfileScreen(),
          ]
        : const [
            HomeScreen(),
            MyServicesScreen(),
            AdvisorMessagesScreen(),
            ReadingHistoryScreen(),
            ProfileScreen(),
          ];

    // 5 Tabs matching Pocket Insight Architecture: Insight, Service, Inbox, Prediction, Mine
    final List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.auto_awesome_outlined),
        activeIcon: Icon(Icons.auto_awesome_rounded),
        label: "Insight",
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.diamond_outlined),
        activeIcon: Icon(Icons.diamond_rounded),
        label: "Service",
      ),
      BottomNavigationBarItem(
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded),
            if (userProv.unreadNotificationsCount > 0)
              Positioned(
                top: -2,
                right: -3,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.errorRed,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        activeIcon: const Icon(Icons.chat_bubble_rounded),
        label: "Inbox",
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.style_outlined),
        activeIcon: Icon(Icons.style_rounded),
        label: "Prediction",
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline_rounded),
        activeIcon: Icon(Icons.person_rounded),
        label: "Mine",
      ),
    ];

    final safeIndex = nav.currentIndex.clamp(0, screens.length - 1);

    return Scaffold(
      drawer: const AppDrawerMenu(),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const AppLogo(iconSize: 22, fontSize: 18),
        actions: [
          // Pocket Insight Coin Wallet Balance Badge (🪙 Balance)
          InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accentGold.withOpacity(0.6), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on_rounded, color: AppColors.accentGold, size: 17),
                  const SizedBox(width: 4),
                  Text(
                    userProv.userBalance > 0 ? "\$${userProv.userBalance.toStringAsFixed(2)}" : "0",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Notification Bell
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                },
              ),
              if (userProv.unreadNotificationsCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.errorRed,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "${userProv.unreadNotificationsCount}",
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: safeIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: (idx) => nav.setTab(idx),
        items: navItems,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.accentGoldDark,
        unselectedItemColor: const Color(0xFF9CA3AF),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
    );
  }
}


