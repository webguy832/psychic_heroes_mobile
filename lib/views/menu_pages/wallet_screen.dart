import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../shared/app_footer_widget.dart';
import 'add_funds_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  String _selectedFilter = "all"; // "all", "credits", "debits"

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final userProv = Provider.of<UserProvider>(context, listen: false);
    userProv.loadWalletData();
  }

  String _formatDate(String rawDate) {
    if (rawDate.isEmpty) return '—';
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      return DateFormat('dd MMM, hh:mm a').format(dt);
    } catch (_) {
      return rawDate;
    }
  }

  String _formatUpdatedDate(String rawDate) {
    if (rawDate.isEmpty) return 'Just now';
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return rawDate;
    }
  }

  bool _isFreeFee(TransactionHistoryDto t) {
    final tt = t.transType.trim().toLowerCase();
    return tt == '5' ||
        tt == '6' ||
        tt == 'chatfee' ||
        tt == 'callingfee' ||
        t.description.contains('\$0.00') ||
        t.description.toLowerCase().contains('free');
  }

  @override
  Widget build(BuildContext context) {
    final userProv = Provider.of<UserProvider>(context);
    final isAdvisor = userProv.isAdvisor;
    final summary = userProv.walletSummary ??
        UserWalletSummary(
          balance: userProv.userBalance,
          minBalance: userProv.freeMinutes.toDouble(),
          ratePerMin: isAdvisor ? 0.49 : 0.0,
          updatedAt: DateTime.now().toIso8601String(),
        );

    final rawMinBalance = summary.minBalance;
    final freeMinutesOver = rawMinBalance <= 0;

    final allTxns = userProv.transactions;
    final filteredTxns = allTxns.where((t) {
      if (_selectedFilter == "credits") return t.credit > 0;
      if (_selectedFilter == "debits") return t.debit > 0 || _isFreeFee(t);
      return true;
    }).toList();

    final isLoading = userProv.isLoading && userProv.walletSummary == null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Matching web slate-50/slate-100 background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Text(
          isAdvisor ? "Advisor Wallet & Payout History" : "My Wallet & Transaction History",
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Refresh Wallet",
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        color: const Color(0xFF4F46E5),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Optional Error Message
                        if (userProv.errorMessage != null && userProv.errorMessage!.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Color(0xFFB91C1C), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    userProv.errorMessage!,
                                    style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // TOP SUMMARY CARDS (Matching web_angular_2025 wallet.component.html)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 768;

                            final card1 = _buildCurrentBalanceCard(summary, isAdvisor);
                            final card2 = isAdvisor
                                ? _buildAdvisorEarningsStatusCard(summary)
                                : _buildFreeMinutesCard(rawMinBalance, freeMinutesOver);
                            final card3 = _buildRateCard(summary, isAdvisor);

                            if (isWide) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: card1),
                                  const SizedBox(width: 16),
                                  Expanded(child: card2),
                                  const SizedBox(width: 16),
                                  Expanded(child: card3),
                                ],
                              );
                            }

                            return Column(
                              children: [
                                card1,
                                const SizedBox(height: 12),
                                card2,
                                const SizedBox(height: 12),
                                card3,
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // TRANSACTIONS SECTION (Matching web_angular_2025)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Card Header
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                child: Column(
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.playfairDisplay(
                                          fontSize: 24,
                                          color: const Color(0xFF0F172A),
                                        ),
                                        children: const [
                                          TextSpan(text: "Transaction "),
                                          TextSpan(
                                            text: "History",
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Updated ${_formatUpdatedDate(summary.updatedAt)}",
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                    ),
                                    const SizedBox(height: 14),

                                    // Filter Tabs
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        _buildFilterChip("all", "All Activity (${allTxns.length})"),
                                        _buildFilterChip("credits", "Credits"),
                                        _buildFilterChip("debits", "Debits"),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const Divider(height: 1, color: Color(0xFFE2E8F0)),

                              // Body: Loading / Empty / Data Table
                              if (isLoading)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 60),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF4F46E5),
                                      strokeWidth: 3,
                                    ),
                                  ),
                                )
                              else if (filteredTxns.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.receipt_long_outlined, size: 42, color: Color(0xFFCBD5E1)),
                                      SizedBox(height: 12),
                                      Text(
                                        "No transactions found",
                                        style: TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else ...[
                                // Full Web-Table layout with Horizontal Scroll support
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(minWidth: 620),
                                    child: DataTable(
                                      headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
                                      dividerThickness: 1,
                                      horizontalMargin: 20,
                                      columnSpacing: 24,
                                      headingTextStyle: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                      columns: const [
                                        DataColumn(label: Text("Date")),
                                        DataColumn(label: Text("Description")),
                                        DataColumn(label: Text("Credit"), numeric: true),
                                        DataColumn(label: Text("Debit"), numeric: true),
                                        DataColumn(label: Text("Balance"), numeric: true),
                                      ],
                                      rows: filteredTxns.map((t) {
                                        final isCredit = t.credit > 0;
                                        final isDebit = t.debit > 0;
                                        final isFree = _isFreeFee(t);

                                        return DataRow(
                                          cells: [
                                            // Date
                                            DataCell(
                                              Text(
                                                _formatDate(t.createdAt),
                                                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                                              ),
                                            ),

                                            // Description
                                            DataCell(
                                              Container(
                                                constraints: const BoxConstraints(maxWidth: 240),
                                                child: Text(
                                                  t.description.isNotEmpty ? t.description : 'Reading Session',
                                                  style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 2,
                                                ),
                                              ),
                                            ),

                                            // Credit
                                            DataCell(
                                              Text(
                                                isCredit ? "\$ ${t.credit.toStringAsFixed(2)}" : "—",
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: isCredit ? const Color(0xFF15803D) : const Color(0xFF94A3B8),
                                                ),
                                              ),
                                            ),

                                            // Debit
                                            DataCell(
                                              Text(
                                                isDebit
                                                    ? "\$ ${t.debit.toStringAsFixed(2)}"
                                                    : (isFree ? "\$ 0.00" : "—"),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDebit
                                                      ? const Color(0xFFB91C1C)
                                                      : (isFree ? const Color(0xFFD97706) : const Color(0xFF94A3B8)),
                                                ),
                                              ),
                                            ),

                                            // Running Balance
                                            DataCell(
                                              Text(
                                                "\$ ${t.balance.toStringAsFixed(2)}",
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF334155),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
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

  // Card 1: Current Balance
  Widget _buildCurrentBalanceCard(UserWalletSummary summary, bool isAdvisor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFF8FAFC)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAdvisor ? "Available Earnings Balance" : "Current Balance",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              if (!isAdvisor)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5), // Indigo matching web action
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 15),
                  label: const Text(
                    "Add Funds",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddFundsScreen()),
                    ).then((_) => _loadData());
                  },
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.verified_user_rounded, size: 14, color: Color(0xFF4F46E5)),
                      SizedBox(width: 4),
                      Text(
                        "Advisor Wallet",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF4F46E5)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "\$ ${summary.balance.toStringAsFixed(2)}",
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  // Advisor Card 2: Readings & Payouts
  Widget _buildAdvisorEarningsStatusCard(UserWalletSummary summary) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Readings & Payouts",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Text(
                  "Active",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF065F46),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "Live Earnings",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF047857),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Recorded from client reading sessions",
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  // Card 2: Free Minutes Balance (Active / Over)
  Widget _buildFreeMinutesCard(double rawMinBalance, bool isOver) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Free Minutes Balance",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: !isOver ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: !isOver ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                  ),
                ),
                child: Text(
                  !isOver ? "Active" : "Over",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: !isOver ? const Color(0xFF065F46) : const Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "${rawMinBalance.toStringAsFixed(rawMinBalance.truncateToDouble() == rawMinBalance ? 0 : 1)} Mins",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: !isOver ? const Color(0xFF047857) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            !isOver ? "Available for your reading sessions" : "Your free minutes are over",
            style: TextStyle(
              fontSize: 11,
              fontWeight: isOver ? FontWeight.w600 : FontWeight.normal,
              color: !isOver ? const Color(0xFF64748B) : const Color(0xFFB45309),
            ),
          ),
        ],
      ),
    );
  }

  // Card 3: Rate / Min
  Widget _buildRateCard(UserWalletSummary summary, bool isAdvisor) {
    final displayRate = summary.ratePerMin > 0 ? summary.ratePerMin : (isAdvisor ? 0.49 : 0.0);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAdvisor ? "Advisor Rate" : "Rate / Min",
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "\$ ${displayRate.toStringAsFixed(2)}${isAdvisor ? ' / min' : ''}",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isAdvisor ? "Your standard reading session rate" : "Default per-minute service rate",
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  // Filter Chip Widget
  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
