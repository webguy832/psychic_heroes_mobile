import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/navigation_provider.dart';
import '../main_navigation_screen.dart';
import '../advisors/advisor_dashboard_screen.dart';
import '../user/login_screen.dart';
import '../user/profile_screen.dart';
import '../user/billing_address_screen.dart';
import '../user/notifications_screen.dart';
import '../menu_pages/referral_screen.dart';
import '../menu_pages/advisor_messages_screen.dart';
import '../menu_pages/add_funds_screen.dart';
import '../menu_pages/wallet_screen.dart';
import '../menu_pages/reading_history_screen.dart';
import '../menu_pages/insights_screen.dart';
import '../menu_pages/my_services_screen.dart';
import '../menu_pages/settings_screen.dart';
import '../menu_pages/help_support_screen.dart';
import '../shared/app_logo.dart';

class AppDrawerMenu extends StatefulWidget {
  const AppDrawerMenu({Key? key}) : super(key: key);

  @override
  State<AppDrawerMenu> createState() => _AppDrawerMenuState();
}

class _AppDrawerMenuState extends State<AppDrawerMenu> {
  bool _isServicesExpanded = false;

  final List<String> _servicesList = [
    "Tarot Reading",
    "Love & Relationship",
    "Astrology & Zodiac",
    "Mediumship & Spirit",
    "Psychic Readings",
    "Palmistry & Fortune",
    "Crystal Healing",
    "Dream Analysis"
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final userProv = Provider.of<UserProvider>(context);
    final nav = Provider.of<NavigationProvider>(context, listen: false);
    final user = auth.isLoggedIn ? userProv.user : null;
    final isAdvisor = userProv.isAdvisor;

    return Drawer(
      backgroundColor: AppColors.bgDark,
      child: Column(
        children: [
          // Drawer Header with Brand Logo & User Info
          Container(
            padding: const EdgeInsets.only(top: 48, bottom: 20, left: 18, right: 18),
            decoration: BoxDecoration(
              gradient: AppColors.cardGradient,
              border: const Border(bottom: BorderSide(color: AppColors.borderDark)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const AppLogo(fontSize: 20),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.bgDarkCardElevated,
                      child: Text(
                        (user != null && user.displayName.isNotEmpty == true) ? user.displayName[0].toUpperCase() : 'P',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.accentGold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? "Welcome to PsychicHeroes",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (user?.email != null && user!.email.isNotEmpty) ? user.email : "Sign in for 45s Free Reading",
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (auth.isLoggedIn)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isAdvisor ? AppColors.accentGold : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isAdvisor ? "ADVISOR" : "MEMBER",
                          style: TextStyle(
                            color: isAdvisor ? Colors.black : Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Scrollable Menu Options
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: isAdvisor
                  ? _buildAdvisorMenuItems(context, nav)
                  : _buildCustomerMenuItems(context, nav),
            ),
          ),

          // Contact Us Web-Parity Info Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.bgDarkCard,
              border: Border(top: BorderSide(color: AppColors.borderDark)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Contact Us", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                Row(
                  children: const [
                    Icon(Icons.email_outlined, color: AppColors.onlineGreen, size: 14),
                    SizedBox(width: 6),
                    Text("support@psychicheroes.com", style: TextStyle(color: AppColors.onlineGreen, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: const [
                    Icon(Icons.location_on_outlined, color: AppColors.textSecondaryDark, size: 14),
                    SizedBox(width: 6),
                    Text("New York • London (Mon-Fri 7AM-4PM EST)", style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 12),
                auth.isLoggedIn
                    ? ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.logout_rounded, color: AppColors.errorRed, size: 20),
                        title: const Text("Sign Out", style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold, fontSize: 13)),
                        onTap: () async {
                          Navigator.pop(context);
                          await auth.logout();
                          userProv.clearUser();
                          nav.setTab(0);
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                            (route) => false,
                          );
                        },
                      )
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4E7E2A),
                          minimumSize: const Size(double.infinity, 42),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.login_rounded, size: 18),
                        label: const Text("Sign In / Sign Up", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCustomerMenuItems(BuildContext context, NavigationProvider nav) {
    return [
      _buildDrawerTile(
        icon: Icons.home_rounded,
        title: "Home",
        onTap: () {
          nav.setTab(0);
          Navigator.pop(context);
        },
      ),

      // Expandable Web Services Dropdown
      Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.accentGold,
          collapsedIconColor: AppColors.textSecondaryDark,
          leading: const Icon(Icons.psychology_rounded, color: AppColors.accentCyan, size: 20),
          title: const Text(
            "Services",
            style: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w500, fontSize: 13.5),
          ),
          children: _servicesList.map((service) {
            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 48, right: 16),
              title: Text(
                service,
                style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12.5),
              ),
              onTap: () {
                nav.setTab(0);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),

      _buildDrawerTile(
        icon: Icons.forum_rounded,
        title: "Advisor Chat Inbox",
        onTap: () {
          nav.setTab(1);
          Navigator.pop(context);
        },
      ),
      _buildDrawerTile(
        icon: Icons.add_card_rounded,
        title: "Add Funds & Recharge",
        badgeText: "POPULAR",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddFundsScreen()));
        },
      ),
      _buildDrawerTile(
        icon: Icons.account_balance_wallet_rounded,
        title: "Wallet & History",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
        },
      ),
      _buildDrawerTile(
        icon: Icons.card_giftcard_rounded,
        title: "Referrals & Rewards",
        badgeText: "BONUS",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralScreen()));
        },
      ),
      _buildDrawerTile(
        icon: Icons.auto_stories_rounded,
        title: "Reading History",
        onTap: () {
          nav.setTab(2);
          Navigator.pop(context);
        },
      ),
      _buildDrawerTile(
        icon: Icons.insights_rounded,
        title: "Insights & Horoscopes",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const InsightsScreen()));
        },
      ),
      _buildDrawerTile(
        icon: Icons.location_on_rounded,
        title: "Billing Addresses",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const BillingAddressScreen()));
        },
      ),
      _buildDrawerTile(
        icon: Icons.notifications_active_rounded,
        title: "Notifications",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
        },
      ),
      _buildDrawerTile(
        icon: Icons.person_rounded,
        title: "Profile",
        onTap: () {
          nav.setTab(3);
          Navigator.pop(context);
        },
      ),
      _buildDrawerTile(
        icon: Icons.settings_rounded,
        title: "Settings",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
        },
      ),
      _buildDrawerTile(
        icon: Icons.help_outline_rounded,
        title: "Help & Support",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
        },
      ),
    ];
  }

  List<Widget> _buildAdvisorMenuItems(BuildContext context, NavigationProvider nav) {
    return [
      _buildDrawerTile(
        icon: Icons.dashboard_rounded,
        title: "Advisor Dashboard",
        onTap: () {
          nav.setTab(0);
          Navigator.pop(context);
        },
      ),
      _buildDrawerTile(
        icon: Icons.forum_rounded,
        title: "Client Messages",
        onTap: () {
          nav.setTab(1);
          Navigator.pop(context);
        },
      ),
      _buildDrawerTile(
        icon: Icons.workspace_premium_rounded,
        title: "My Services & Rates",
        onTap: () {
          nav.setTab(2);
          Navigator.pop(context);
        },
      ),
      _buildDrawerTile(
        icon: Icons.auto_stories_rounded,
        title: "Reading History",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ReadingHistoryScreen()));
        },
      ),
      _buildDrawerTile(
        icon: Icons.person_rounded,
        title: "Profile",
        onTap: () {
          nav.setTab(3);
          Navigator.pop(context);
        },
      ),
      _buildDrawerTile(
        icon: Icons.notifications_active_rounded,
        title: "Notifications",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
        },
      ),
      _buildDrawerTile(
        icon: Icons.settings_rounded,
        title: "Settings",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
        },
      ),
      _buildDrawerTile(
        icon: Icons.help_outline_rounded,
        title: "Help & Support",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
        },
      ),
    ];
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: AppColors.accentCyan, size: 20),
      title: Text(
        title,
        style: const TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w500, fontSize: 13.5),
      ),
      trailing: badgeText != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF4E7E2A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            )
          : const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryDark, size: 18),
      onTap: onTap,
    );
  }
}
