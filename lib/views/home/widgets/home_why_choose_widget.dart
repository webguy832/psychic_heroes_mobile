import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';

class HomeWhyChooseWidget extends StatelessWidget {
  const HomeWhyChooseWidget({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> _features = const [
    {'title': '100% Confidential', 'desc': 'Private, encrypted 1-on-1 sessions', 'icon': Icons.lock_outline_rounded},
    {'title': 'Verified Expert Psychics', 'desc': 'Screened & background-checked readers', 'icon': Icons.verified_user_outlined},
    {'title': '24/7 Live Availability', 'desc': 'Instant guidance anytime day or night', 'icon': Icons.access_time_rounded},
    {'title': 'Satisfaction Guarantee', 'desc': 'Loved by thousands of repeat clients', 'icon': Icons.thumb_up_alt_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Why Choose PsychicHeroes",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _features.length,
          itemBuilder: (ctx, idx) {
            final f = _features[idx];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgDarkCard,
                borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(f['icon'] as IconData, color: AppColors.accentGold, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    f['title'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimaryDark),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    f['desc'] as String,
                    style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
