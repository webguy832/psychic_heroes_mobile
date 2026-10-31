import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';

class HomeHowItWorksWidget extends StatelessWidget {
  const HomeHowItWorksWidget({Key? key}) : super(key: key);

  final List<Map<String, String>> _steps = const [
    {'step': '1', 'title': 'Choose an Advisor', 'desc': 'Browse profiles, ratings, & specialties to find your ideal psychic.'},
    {'step': '2', 'title': 'Claim \$10 Free Credit', 'desc': 'Create your free account and receive introductory reading minutes.'},
    {'step': '3', 'title': 'Connect Live', 'desc': 'Start a instant live chat or voice call for direct spiritual clarity.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "How It Works",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark),
        ),
        const SizedBox(height: 12),
        Column(
          children: _steps.map((s) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: AppStyles.paddingCard,
              decoration: BoxDecoration(
                color: AppColors.bgDarkCard,
                borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                    ),
                    child: Center(
                      child: Text(
                        s['step']!,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimaryDark)),
                        const SizedBox(height: 2),
                        Text(s['desc']!, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                      ],
                    ),
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
