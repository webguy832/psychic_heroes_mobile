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

    final List<Widget> screens = isAdvisor
        ? const [
            AdvisorDashboardScreen(),
            AdvisorMessagesScreen(),
            MyServicesScreen(),
            ProfileScreen(),
          ]
        : const [
            HomeScreen(),
            AdvisorMessagesScreen(),
            ReadingHistoryScreen(),
            ProfileScreen(),
          ];

    final List<BottomNavigationBarItem> navItems = isAdvisor
        ? const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: "Dashboard",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.forum_outlined),
              activeIcon: Icon(Icons.forum_rounded),
              label: "Client Messages",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.workspace_premium_outlined),
              activeIcon: Icon(Icons.workspace_premium_rounded),
              label: "My Services",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined),
              activeIcon: Icon(Icons.account_circle_rounded),
              label: "Profile",
            ),
          ]
        : const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.forum_outlined),
              activeIcon: Icon(Icons.forum_rounded),
              label: "Advisor Chat",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_stories_outlined),
              activeIcon: Icon(Icons.auto_stories_rounded),
              label: "Readings",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined),
              activeIcon: Icon(Icons.account_circle_rounded),
              label: "Profile",
            ),
          ];

    final safeIndex = nav.currentIndex.clamp(0, screens.length - 1);

    return Scaffold(
      drawer: const AppDrawerMenu(),
      appBar: AppBar(
        title: const AppLogo(iconSize: 22, fontSize: 18),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
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
      ),
    );
  }
}

