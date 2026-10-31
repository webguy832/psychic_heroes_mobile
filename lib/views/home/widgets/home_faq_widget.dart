import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';

class HomeFaqWidget extends StatelessWidget {
  const HomeFaqWidget({Key? key}) : super(key: key);

  final List<Map<String, String>> _faqs = const [
    {
      'question': 'How do online psychic readings work?',
      'answer': 'You select an advisor, connect via live chat or voice call, and receive real-time answers and spiritual guidance.'
    },
    {
      'question': 'How do I claim my 3 free minutes?',
      'answer': 'New users receive introductory free minutes automatically credited to their account upon sign-up.'
    },
    {
      'question': 'Are the psychic readers verified?',
      'answer': 'Yes! All advisors undergo rigorous screening, background checks, and accuracy evaluations before joining.'
    },
    {
      'question': 'Is my personal information kept private?',
      'answer': 'Absolutely. All sessions and personal billing details are 100% confidential and encrypted.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Frequently Asked Questions",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark),
        ),
        const SizedBox(height: 12),
        Column(
          children: _faqs.map((f) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.bgDarkCard,
                borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: ExpansionTile(
                iconColor: AppColors.accentGold,
                collapsedIconColor: AppColors.textSecondaryDark,
                title: Text(f['question']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimaryDark)),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 14),
                    child: Text(f['answer']!, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13, height: 1.4)),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
