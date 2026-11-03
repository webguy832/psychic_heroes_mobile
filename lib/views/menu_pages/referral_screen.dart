import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../providers/user_provider.dart';
import '../shared/custom_button.dart';
import '../shared/app_footer_widget.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({Key? key}) : super(key: key);

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final List<Map<String, dynamic>> _rewardItems = [
    {'title': '5 Free Reading Minutes', 'points': 250, 'icon': Icons.timer_rounded, 'badge': 'Popular'},
    {'title': '\$10 Wallet Top-Up Credit', 'points': 500, 'icon': Icons.account_balance_wallet_rounded, 'badge': 'Best Value'},
    {'title': 'Tarot Card 3-Spread Deck', 'points': 150, 'icon': Icons.style_rounded, 'badge': 'Bonus'},
    {'title': 'VIP Gold Advisor Badge', 'points': 800, 'icon': Icons.workspace_premium_rounded, 'badge': 'Exclusive'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProv = Provider.of<UserProvider>(context, listen: false);
      userProv.fetchUserProfile();
      userProv.fetchTransactions();
    });
  }

  void _claimReward(Map<String, dynamic> item, UserProvider userProv) {
    final pointsNeeded = item['points'] as int;
    if (userProv.karmaPoints < pointsNeeded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You need $pointsNeeded Karma Points to claim this reward. You have ${userProv.karmaPoints} pts."),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    userProv.addKarmaPoints(-pointsNeeded);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgDarkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.stars_rounded, color: AppColors.accentGold, size: 28),
            SizedBox(width: 8),
            Text("Reward Redeemed!", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "Successfully redeemed '${item['title']}' for $pointsNeeded Karma Points! Your reward bonus has been added to your profile.",
          style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryLight),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Awesome!", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProv = Provider.of<UserProvider>(context);
    final u = userProv.user;

    final referralCode = (u?.screenName != null && u!.screenName!.isNotEmpty)
        ? u.screenName!
        : (u?.id != null && u!.id.isNotEmpty
            ? (u.id.length > 8 ? u.id.substring(0, 8).toUpperCase() : u.id.toUpperCase())
            : "HERO10");

    final referralLink = (u?.affiliateLink != null && u!.affiliateLink!.isNotEmpty)
        ? u.affiliateLink!
        : "https://psychicheroes.com/register?ref=$referralCode";

    double referralEarned = 0.0;
    int referralCount = 0;
    for (var t in userProv.transactions) {
      if (t.transactionType.toLowerCase().contains("referral") || t.description.toLowerCase().contains("referral")) {
        referralEarned += t.credit;
        referralCount += 1;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDarkCard,
        elevation: 1,
        title: const Text("Referrals & Karma Rewards", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: AppStyles.paddingPage,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Hero Referral Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.card_giftcard_rounded, size: 58, color: AppColors.accentGold),
                        SizedBox(height: 12),
                        Text(
                          "Invite Friends & Earn \$10 Credit!",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Share your personal invite link. When your friends complete their first reading, both of you earn 250 Karma Points + \$10 bonus credit!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Referral Stats Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatTile("Total Earned", "\$${referralEarned.toStringAsFixed(2)}", Icons.payments_rounded, AppColors.onlineGreen),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatTile("Friends Joined", "$referralCount ${referralCount == 1 ? 'Friend' : 'Friends'}", Icons.people_alt_rounded, AppColors.accentCyan),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatTile("Karma Points", "${userProv.karmaPoints} Pts", Icons.stars_rounded, AppColors.accentGold),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Referral Code Box
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.bgDarkCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderGold.withOpacity(0.5)),
                    ),
                    child: Column(
                      children: [
                        const Text("Your Unique Referral Code", style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.bgDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderDark),
                          ),
                          child: SelectableText(
                            referralCode,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.accentGold, letterSpacing: 2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: "Copy Code",
                                icon: Icons.copy_rounded,
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: referralCode));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Referral code '$referralCode' copied to clipboard!"), backgroundColor: AppColors.successGreen),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomButton(
                                text: "Share Link",
                                icon: Icons.share_rounded,
                                backgroundColor: AppColors.accentCyan,
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: referralLink));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Referral link copied to clipboard: $referralLink"), backgroundColor: AppColors.accentCyan),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Text("Redeem Karma Rewards Catalog", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),

                  // Rewards Catalog Grid
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _rewardItems.length,
                    itemBuilder: (ctx, i) {
                      final item = _rewardItems[i];
                      final canClaim = userProv.karmaPoints >= (item['points'] as int);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.bgDarkCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), shape: BoxShape.circle),
                              child: Icon(item['icon'] as IconData, color: AppColors.accentGold, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: AppColors.accentCyan.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                        child: Text(item['badge'] as String, style: const TextStyle(color: AppColors.accentCyan, fontSize: 8, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.stars_rounded, color: AppColors.accentGold, size: 14),
                                      const SizedBox(width: 4),
                                      Text("${item['points']} Points Required", style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canClaim ? AppColors.onlineGreen : Colors.white12,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _claimReward(item, userProv),
                              child: Text(canClaim ? "Redeem" : "Locked", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.bgDarkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 9), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

