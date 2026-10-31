import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../shared/custom_button.dart';
import '../shared/custom_text_field.dart';
import '../shared/app_footer_widget.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();

  String _selectedCategory = "General Inquiry";
  bool _isSubmitting = false;

  final List<Map<String, String>> _faqs = const [
    {
      'question': 'How does per-minute chat & call charging work?',
      'category': 'Billing',
      'answer': 'All live sessions have a 45-second free grace period. If a session ends under 45 seconds, it is 100% FREE. At 45 seconds, your wallet is billed for 1 minute, and every additional minute thereafter.'
    },
    {
      'question': 'How do I add funds to my PsychicHeroes wallet?',
      'category': 'Billing',
      'answer': 'Go to Menu > Add Funds, select a recharge package or enter a custom amount, and complete payment via Credit/Debit card (Stripe), PayPal, or Apple Pay.'
    },
    {
      'question': 'What happens if my wallet balance runs out during a reading?',
      'category': 'Readings',
      'answer': 'Your chat or call will automatically enter a 5-minute hold state. You can add funds to your wallet and instantly resume your session without losing your conversation.'
    },
    {
      'question': 'How are psychic advisors screened and verified?',
      'category': 'Advisors',
      'answer': 'All advisors undergo a strict background check, background verification of spiritual experience, and live test readings before joining our platform.'
    },
    {
      'question': 'Can I request a refund if I am unsatisfied?',
      'category': 'Refunds',
      'answer': 'Yes! We offer a Satisfaction Guarantee. Submit a support ticket within 24 hours of your reading with your session ID, and our team will review your request.'
    },
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _submitTicket() async {
    if (_subjectController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in both subject and message details."), backgroundColor: AppColors.errorRed),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() => _isSubmitting = false);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgDarkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.mark_email_read_rounded, color: AppColors.onlineGreen, size: 28),
            SizedBox(width: 8),
            Text("Ticket Submitted!", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "Thank you for contacting us! Support Ticket #TCK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)} has been created under category '$_selectedCategory'. Our support team will reply within 2 hours.",
          style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 13),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryLight),
            onPressed: () {
              Navigator.pop(ctx);
              _subjectController.clear();
              _messageController.clear();
            },
            child: const Text("Got it!", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filteredFaqs = _faqs.where((f) {
      if (query.isEmpty) return true;
      return f['question']!.toLowerCase().contains(query) || f['answer']!.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDarkCard,
        elevation: 1,
        title: const Text("Help Center & 24/7 Support", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: AppStyles.paddingPage,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Contact Support Banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.cardGradient,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderGold.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.accentGold.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.support_agent_rounded, color: AppColors.accentGold, size: 38),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text("24/7 Psychic Customer Care", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                              SizedBox(height: 4),
                              Text("We are here to assist with billing, session questions, or technical help anytime.", style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text("Frequently Asked Questions (FAQ)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 10),

                  // FAQ Search Box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.bgDarkCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        icon: Icon(Icons.search_rounded, color: AppColors.textSecondaryDark),
                        hintText: "Search help topics or questions...",
                        hintStyle: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
                        border: InputBorder.none,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // FAQ Expansion Tiles
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredFaqs.length,
                    itemBuilder: (ctx, i) {
                      final faq = filteredFaqs[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.bgDarkCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: ExpansionTile(
                          iconColor: AppColors.accentGold,
                          collapsedIconColor: AppColors.textSecondaryDark,
                          title: Text(faq['question']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Text(
                                faq['answer']!,
                                style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 12.5, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  const Text("Submit Support Ticket", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  const Text("Cannot find your answer above? Send a direct message to our support team.", style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                  const SizedBox(height: 14),

                  // Category Selector Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bgDarkCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        dropdownColor: AppColors.bgDarkCard,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                        items: const [
                          DropdownMenuItem(value: "General Inquiry", child: Text("General Inquiry")),
                          DropdownMenuItem(value: "Billing & Refunds", child: Text("Billing & Wallet Refund")),
                          DropdownMenuItem(value: "Session Technical Issue", child: Text("Live Chat / Call Audio Issue")),
                          DropdownMenuItem(value: "Advisor Feedback", child: Text("Advisor Reading Feedback")),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedCategory = v);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  CustomTextField(controller: _subjectController, labelText: "Subject Line"),
                  const SizedBox(height: 12),
                  CustomTextField(controller: _messageController, labelText: "Ticket Details & Message", maxLines: 4),

                  const SizedBox(height: 20),

                  CustomButton(
                    text: _isSubmitting ? "Submitting Ticket..." : "Submit Support Ticket",
                    icon: _isSubmitting ? Icons.sync_rounded : Icons.send_rounded,
                    isLoading: _isSubmitting,
                    onPressed: _submitTicket,
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

