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
  int _logoTapCount = 0;

  void _showDevModeDialog(BuildContext context, NavigationProvider nav) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgDarkCard,
        title: Row(
          children: const [
            Icon(Icons.developer_mode_rounded, color: AppColors.accentGold),
            SizedBox(width: 8),
            Text("Mode Switcher", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          nav.isDevMode
              ? "You are currently in Developer Mode (All 5 tabs & all menu items visible).\n\nSwitch to Demo Mode (only Home & Profile visible)?"
              : "You are currently in Demo Mode (only Home & Profile visible).\n\nSwitch to Developer Mode (all 5 tabs & all menu items visible)?",
          style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: nav.isDevMode ? Colors.grey[800] : AppColors.accentGold,
              foregroundColor: nav.isDevMode ? Colors.white : AppColors.primary,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              nav.toggleDevMode();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    nav.isDevMode
                        ? "🚀 Development Mode Enabled! All menus unlocked."
                        : "🔒 Demo Mode Enabled: Restricted to Home & Profile.",
                  ),
                  backgroundColor: nav.isDevMode ? AppColors.primary : Colors.grey[850],
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text(nav.isDevMode ? "Switch to Demo Mode" : "Switch to Dev Mode"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nav = Provider.of<NavigationProvider>(context);
    final userProv = Provider.of<UserProvider>(context);
    final isAdvisor = userProv.isAdvisor;
    final isDev = nav.isDevMode;

    final List<Widget> screens = !isDev
        ? (isAdvisor
            ? const [
                AdvisorDashboardScreen(),
                ProfileScreen(),
              ]
            : const [
                HomeScreen(),
                ProfileScreen(),
              ])
        : (isAdvisor
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
              ]);

    final List<BottomNavigationBarItem> navItems = !isDev
        ? const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: "Profile",
            ),
          ]
        : [
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
        title: GestureDetector(
          onTap: () {
            _logoTapCount++;
            if (_logoTapCount >= 3) {
              _logoTapCount = 0;
              nav.toggleDevMode();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    nav.isDevMode
                        ? "🚀 Development Mode Enabled! (All 5 tabs & all menus unlocked)"
                        : "🔒 Demo Mode Enabled! (Restricted to Home & Profile)",
                  ),
                  backgroundColor: nav.isDevMode ? AppColors.primary : Colors.grey[850],
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
          child: const AppLogo(iconSize: 22, fontSize: 18),
        ),
        actions: [
          // Dev Mode Active Badge in AppBar
          if (isDev)
            InkWell(
              onTap: () => _showDevModeDialog(context, nav),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentGold, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.developer_mode_rounded, color: AppColors.accentGold, size: 13),
                    SizedBox(width: 3),
                    Text(
                      "DEV",
                      style: TextStyle(
                        color: AppColors.accentGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 2),

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


