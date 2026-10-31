import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';

class HomeServicesWidget extends StatelessWidget {
  const HomeServicesWidget({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> _services = const [
    {'title': 'Psychic Reading', 'icon': Icons.auto_awesome_rounded, 'desc': 'Clairvoyant insights on life path & destiny'},
    {'title': 'Tarot Card Reading', 'icon': Icons.style_rounded, 'desc': 'Deep guidance through mystical tarot spreads'},
    {'title': 'Astrology & Horoscope', 'icon': Icons.brightness_7_rounded, 'desc': 'Natal chart & planetary transit analysis'},
    {'title': 'Love & Relationships', 'icon': Icons.favorite_rounded, 'desc': 'Soulmate, twin flame & relationship clarity'},
    {'title': 'Career & Money Insight', 'icon': Icons.account_balance_rounded, 'desc': 'Financial opportunities & career moves'},
    {'title': 'Spiritual Healing', 'icon': Icons.spa_rounded, 'desc': 'Energy cleansing & spirit guide connection'},
    {'title': 'Dream & Numerology', 'icon': Icons.nights_stay_rounded, 'desc': 'Uncover hidden dream symbols & numbers'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Our Specialized Services",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _services.length,
            itemBuilder: (ctx, idx) {
              final service = _services[idx];
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgDarkCard,
                  borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(service['icon'] as IconData, color: AppColors.accentGold, size: 22),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      service['title'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimaryDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      service['desc'] as String,
                      style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
