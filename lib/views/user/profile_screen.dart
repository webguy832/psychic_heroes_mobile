import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/navigation_provider.dart';
import '../main_navigation_screen.dart';
import '../shared/loading_indicator.dart';
import 'edit_profile_screen.dart';
import 'billing_address_screen.dart';
import 'notifications_screen.dart';
import 'login_screen.dart';
import '../menu_pages/add_funds_screen.dart';
import '../menu_pages/help_support_screen.dart';
import '../menu_pages/reading_history_screen.dart';
import '../menu_pages/wallet_screen.dart';
import '../menu_pages/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProv = Provider.of<UserProvider>(context, listen: false);
      userProv.fetchUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final userProv = Provider.of<UserProvider>(context);
    final user = userProv.user;

    if (!auth.isLoggedIn) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle_outlined, size: 80, color: AppColors.primaryLight),
              const SizedBox(height: 16),
              const Text(
                "Sign in to view your profile",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
                child: const Text("Sign In Now"),
              ),
            ],
          ),
        ),
      );
    }

    if (userProv.isLoading && user == null) {
      return const Scaffold(
        body: LoadingIndicator(message: "Loading Profile..."),
      );
    }

    final isAdvisor = userProv.isAdvisor;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdvisor ? "Advisor Profile" : "User Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppStyles.paddingPage,
        child: Column(
          children: [
            // User Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(AppStyles.borderRadiusLarge),
                border: Border.all(color: AppColors.borderDark),
                boxShadow: [AppStyles.cardShadow],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary,
                    backgroundImage: user?.profilePhoto != null && user!.profilePhoto!.isNotEmpty
                        ? NetworkImage(user!.profilePhoto!.startsWith('http') ? user!.profilePhoto! : '${ApiEndpoints.imageBaseUrl}${user!.profilePhoto}')
                        : null,
                    child: (user?.profilePhoto == null || user!.profilePhoto!.isEmpty)
                        ? Text(
                            user?.displayName.isNotEmpty == true
                                ? user!.displayName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          user?.displayName ?? "Member",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isAdvisor ? AppColors.accentGold : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isAdvisor ? "ADVISOR" : "CUSTOMER",
                          style: TextStyle(
                            color: isAdvisor ? Colors.black : Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (user?.email != null && user!.email.isNotEmpty)
                    Text(
                      user!.email,
                      style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
                    ),
                  if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.phoneNumber!,
                      style: const TextStyle(color: AppColors.accentGold, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.borderDark),
                  const SizedBox(height: 12),
                  
                  // Balance & Points Stats (4 Dynamic items matching Angular)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem("Wallet Balance", "\$${(user?.walletBalance ?? 0.0).toStringAsFixed(2)}", AppColors.accentGold),
                      Container(width: 1, height: 36, color: AppColors.borderDark),
                      _buildStatItem("Free Minutes", "${user?.freeMinutes ?? 0} Mins", AppColors.accentCyan),
                      Container(width: 1, height: 36, color: AppColors.borderDark),
                      _buildStatItem("Karma Points", "${user?.karmaPoints ?? 0} Pts", AppColors.successGreen),
                      Container(width: 1, height: 36, color: AppColors.borderDark),
                      _buildStatItem("Tier", user?.tierLevel ?? "Member", AppColors.textPrimaryDark),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Profile Details Overview Card (All dynamic fields from Angular)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgDarkCard,
                borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Personal Details",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimaryDark),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.edit, size: 14, color: AppColors.accentGold),
                        label: const Text("Edit", style: TextStyle(color: AppColors.accentGold, fontSize: 13)),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.borderDark),
                  _buildDetailRow("Screen Name", (user?.screenName != null && user!.screenName!.isNotEmpty) ? user.screenName! : (user?.displayName ?? "Not set")),
                  _buildDetailRow("First Name", (user?.firstName != null && user!.firstName!.isNotEmpty) ? user.firstName! : "Not set"),
                  _buildDetailRow("Last Name", (user?.lastName != null && user!.lastName!.isNotEmpty) ? user.lastName! : "Not set"),
                  _buildDetailRow("Gender", (user?.gender != null && user!.gender!.isNotEmpty) ? user.gender! : "Not specified"),
                  _buildDetailRow("Date of Birth", (user?.dateOfBirth != null && user!.dateOfBirth!.isNotEmpty) ? user.dateOfBirth! : "Not set"),
                  _buildDetailRow("Mobile Number", (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty) ? user.phoneNumber! : "Not set"),
                  _buildDetailRow("Street Address", (user?.addressStreet != null && user!.addressStreet!.isNotEmpty) ? user.addressStreet! : "Not set"),
                  _buildDetailRow("City / State", (user?.addressCity != null || user?.addressState != null) ? "${user?.addressCity ?? ''} ${user?.addressState ?? ''}".trim() : "Not set"),
                  _buildDetailRow("Country", (user?.addressCountry != null && user!.addressCountry!.isNotEmpty) ? user.addressCountry! : (user?.country ?? "Not set")),
                  if (user?.affiliateLink != null && user!.affiliateLink!.isNotEmpty) ...[
                    const Divider(color: AppColors.borderDark),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Referral Link", style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
                        Row(
                          children: [
                            Text(
                              user.affiliateLink!.length > 24 ? '${user.affiliateLink!.substring(0, 22)}...' : user.affiliateLink!,
                              style: const TextStyle(color: AppColors.accentCyan, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.accentGold),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: user.affiliateLink!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Referral link copied to clipboard!")),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Actions List (Fully connected to real pages)
            _buildProfileTile(
              icon: Icons.notifications_none_rounded,
              title: "Notifications",
              subtitle: "Manage announcements & session updates",
              badgeCount: userProv.unreadNotificationsCount,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
            ),
            _buildProfileTile(
              icon: Icons.account_balance_wallet_outlined,
              title: "My Wallet & Transactions",
              subtitle: "View real statements & balance breakdown",
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
            ),
            if (!isAdvisor)
              _buildProfileTile(
                icon: Icons.add_card_rounded,
                title: "Add Funds / Recharge",
                subtitle: "Top up wallet balance for psychic sessions",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddFundsScreen())),
              ),
            _buildProfileTile(
              icon: Icons.history_edu_rounded,
              title: "Reading & Session History",
              subtitle: "View past chat, voice, and video consultations",
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReadingHistoryScreen())),
            ),
            _buildProfileTile(
              icon: Icons.location_on_outlined,
              title: "Billing Addresses",
              subtitle: "Saved billing and contact locations",
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BillingAddressScreen())),
            ),
            _buildProfileTile(
              icon: Icons.settings_outlined,
              title: "Settings & Preferences",
              subtitle: "Notification settings, account privacy & security",
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
            _buildProfileTile(
              icon: Icons.help_outline_rounded,
              title: "Help & Support",
              subtitle: "Contact support, FAQ, & disputes",
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
            ),

            const SizedBox(height: 24),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.errorRed),
                  foregroundColor: AppColors.errorRed,
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text("Sign Out", style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  final nav = Provider.of<NavigationProvider>(context, listen: false);
                  await auth.logout();
                  if (context.mounted) {
                    userProv.clearUser();
                    nav.setTab(0);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
          Text(value, style: const TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    int badgeCount = 0,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.bgDarkCard,
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryLight),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(
                  color: AppColors.errorRed,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  "$badgeCount",
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondaryDark),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
