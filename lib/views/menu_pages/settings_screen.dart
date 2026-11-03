import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../shared/custom_button.dart';
import '../shared/app_footer_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _smsAlerts = false;
  bool _advisorOnlineAlerts = true;
  bool _darkMode = true;
  String _selectedCurrency = "USD (\$)";
  bool _isSaving = false;

  void _saveSettings() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 700));
    setState(() => _isSaving = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Account settings saved successfully!"), backgroundColor: AppColors.successGreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProv = Provider.of<UserProvider>(context);
    final user = userProv.user;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDarkCard,
        elevation: 1,
        title: const Text("Account Settings & Preferences", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: AppStyles.paddingPage,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Account Summary Tile
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgDarkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primary,
                          backgroundImage: user?.profilePhoto != null && user!.profilePhoto!.isNotEmpty
                              ? NetworkImage(user.profilePhoto!.startsWith('http') ? user.profilePhoto! : 'https://psychicheroes.com/${user.profilePhoto}')
                              : null,
                          child: (user?.profilePhoto == null || user!.profilePhoto!.isEmpty)
                              ? Text(
                                  (user?.displayName.isNotEmpty == true)
                                      ? user!.displayName[0].toUpperCase()
                                      : (user?.screenName?.isNotEmpty == true ? user!.screenName![0].toUpperCase() : 'U'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName.isNotEmpty == true
                                    ? user!.displayName
                                    : (user?.screenName?.isNotEmpty == true ? user!.screenName! : "Member"),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(user?.email ?? "", style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.primaryLight.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                          child: const Text("VERIFIED", style: TextStyle(color: AppColors.accentCyan, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text("Notification Preferences", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgDarkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          activeColor: AppColors.accentGold,
                          title: const Text("Email Reading Receipts & Summaries", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: const Text("Receive email confirmation after every chat/call", style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11)),
                          value: _emailNotifications,
                          onChanged: (v) => setState(() => _emailNotifications = v),
                        ),
                        const Divider(color: AppColors.borderDark, height: 1),
                        SwitchListTile(
                          activeColor: AppColors.accentGold,
                          title: const Text("Push Notifications", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: const Text("Instant alerts for live chat requests & messages", style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11)),
                          value: _pushNotifications,
                          onChanged: (v) => setState(() => _pushNotifications = v),
                        ),
                        const Divider(color: AppColors.borderDark, height: 1),
                        SwitchListTile(
                          activeColor: AppColors.accentGold,
                          title: const Text("Favorite Advisor Availability Alerts", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: const Text("Get notified when your favorite psychic comes online", style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11)),
                          value: _advisorOnlineAlerts,
                          onChanged: (v) => setState(() => _advisorOnlineAlerts = v),
                        ),
                        const Divider(color: AppColors.borderDark, height: 1),
                        SwitchListTile(
                          activeColor: AppColors.accentGold,
                          title: const Text("SMS Reading Reminders", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: const Text("Text notifications for appointment reminders", style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11)),
                          value: _smsAlerts,
                          onChanged: (v) => setState(() => _smsAlerts = v),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text("App & Display Preferences", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgDarkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Display Currency", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                            DropdownButton<String>(
                              value: _selectedCurrency,
                              dropdownColor: AppColors.bgDarkCard,
                              style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 13),
                              underline: const SizedBox(),
                              items: const [
                                DropdownMenuItem(value: "USD (\$)", child: Text("USD (\$)")),
                                DropdownMenuItem(value: "EUR (€)", child: Text("EUR (€)")),
                                DropdownMenuItem(value: "GBP (£)", child: Text("GBP (£)")),
                                DropdownMenuItem(value: "CAD (\$)", child: Text("CAD (\$)")),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _selectedCurrency = v);
                              },
                            ),
                          ],
                        ),
                        const Divider(color: AppColors.borderDark, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Dark Mystical Theme Mode", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                            Switch(
                              value: _darkMode,
                              activeColor: AppColors.accentGold,
                              onChanged: (v) => setState(() => _darkMode = v),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  CustomButton(
                    text: _isSaving ? "Saving Settings..." : "Save Preferences",
                    icon: Icons.save_rounded,
                    isLoading: _isSaving,
                    onPressed: _saveSettings,
                  ),

                  const SizedBox(height: 20),

                  // Danger zone: Logout & Delete Account
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.errorRed,
                      side: const BorderSide(color: AppColors.errorRed),
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.delete_forever_rounded, size: 18),
                    label: const Text("Delete Account Data", style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppColors.bgDarkCard,
                          title: const Text("Delete Account Data?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          content: const Text("This action will remove your reading history, preferences, and wallet connection. Contact support to request complete data deletion.", style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 13)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text("Request Deletion", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const AppFooterWidget(),
          ],
        ),
      ),
    );
  }
}

