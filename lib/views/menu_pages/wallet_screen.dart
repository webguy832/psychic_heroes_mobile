import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../providers/user_provider.dart';
import 'add_funds_screen.dart';
import '../shared/app_footer_widget.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  String _selectedFilter = "all";

  final List<Map<String, dynamic>> _mockTransactions = [
    {
      'id': 'TXN-90821',
      'title': 'Wallet Recharge (Stripe)',
      'type': 'credit',
      'amount': 50.00,
      'date': 'Sept 28, 2026 • 04:15 PM',
      'icon': Icons.add_card_rounded,
      'status': 'Completed'
    },
    {
      'id': 'TXN-89102',
      'title': 'Live Session - Psychic Serena',
      'type': 'debit',
      'amount': 15.96,
      'date': 'Sept 25, 2026 • 08:30 PM',
      'icon': Icons.forum_rounded,
      'status': 'Billed'
    },
    {
      'id': 'TXN-87612',
      'title': 'Voice Call - Master Orion',
      'type': 'debit',
      'amount': 23.94,
      'date': 'Sept 20, 2026 • 02:45 PM',
      'icon': Icons.phone_in_talk_rounded,
      'status': 'Billed'
    },
    {
      'id': 'TXN-84511',
      'title': 'Welcome Bonus Credit',
      'type': 'credit',
      'amount': 10.00,
      'date': 'Sept 15, 2026 • 10:00 AM',
      'icon': Icons.card_giftcard_rounded,
      'status': 'Bonus'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final userProv = Provider.of<UserProvider>(context);

    final filteredTransactions = _mockTransactions.where((t) {
      if (_selectedFilter == "credits") return t['type'] == 'credit';
      if (_selectedFilter == "debits") return t['type'] == 'debit';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDarkCard,
        elevation: 1,
        title: const Text("My Wallet & Transaction History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: AppStyles.paddingPage,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wallet Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: AppColors.cardGradient,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderGold.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(color: AppColors.accentGold.withOpacity(0.18), blurRadius: 16, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Available Wallet Balance", style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13, fontWeight: FontWeight.bold)),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentGold,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                              label: const Text("Add Funds", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddFundsScreen()));
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "\$${userProv.userBalance.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: AppColors.accentGold),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: AppColors.borderDark, height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.stars_rounded, color: AppColors.accentCyan, size: 20),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Karma Rewards", style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 10)),
                                    Text("${userProv.karmaPoints} Points Available", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                              child: const Text("ACTIVE WALLET", style: TextStyle(color: AppColors.onlineGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Transaction History Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Transaction History", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      DropdownButton<String>(
                        value: _selectedFilter,
                        dropdownColor: AppColors.bgDarkCard,
                        style: const TextStyle(color: AppColors.accentGold, fontSize: 12, fontWeight: FontWeight.bold),
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: "all", child: Text("All Activity")),
                          DropdownMenuItem(value: "credits", child: Text("Recharges / Bonus")),
                          DropdownMenuItem(value: "debits", child: Text("Session Charges")),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedFilter = val);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Transactions List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredTransactions.length,
                    itemBuilder: (ctx, i) {
                      final txn = filteredTransactions[i];
                      final isCredit = txn['type'] == 'credit';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.bgDarkCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isCredit ? AppColors.onlineGreen.withOpacity(0.15) : AppColors.errorRed.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                txn['icon'] as IconData,
                                color: isCredit ? AppColors.onlineGreen : AppColors.errorRed,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(txn['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                                  const SizedBox(height: 2),
                                  Text("${txn['id']} • ${txn['date']}", style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "${isCredit ? '+' : '-'}\$${(txn['amount'] as double).toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isCredit ? AppColors.onlineGreen : AppColors.errorRed,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(txn['status'] as String, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 9)),
                                ),
                              ],
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

