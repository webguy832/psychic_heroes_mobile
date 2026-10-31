import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';

class HomeTestimonialsWidget extends StatelessWidget {
  const HomeTestimonialsWidget({Key? key}) : super(key: key);

  final List<Map<String, String>> _reviews = const [
    {
      'client': 'Jessica M.',
      'rating': '5.0',
      'text': 'Psychic Serena was spot-on regarding my relationship! She gave me peace of mind when I needed it most.',
      'advisor': 'Psychic Serena'
    },
    {
      'client': 'David K.',
      'rating': '5.0',
      'text': 'Master Orion predicted my promotion timeline accurately. Highly recommended astrology reader!',
      'advisor': 'Master Orion'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Client Feedback & Reviews",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark),
        ),
        const SizedBox(height: 12),
        Column(
          children: _reviews.map((r) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: AppStyles.paddingCard,
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
                      Text(r['client']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      Row(
                        children: const [
                          Icon(Icons.star_rounded, color: AppColors.accentGold, size: 16),
                          Icon(Icons.star_rounded, color: AppColors.accentGold, size: 16),
                          Icon(Icons.star_rounded, color: AppColors.accentGold, size: 16),
                          Icon(Icons.star_rounded, color: AppColors.accentGold, size: 16),
                          Icon(Icons.star_rounded, color: AppColors.accentGold, size: 16),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text("\"${r['text']!}\"", style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 6),
                  Text("Reading with ${r['advisor']!}", style: const TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
