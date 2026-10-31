import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';

class HomeGamificationWidget extends StatelessWidget {
  const HomeGamificationWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppStyles.paddingCard,
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusLarge),
        border: Border.all(color: AppColors.borderDark),
        boxShadow: [AppStyles.cardShadow],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentGold,
                ),
                child: const Icon(Icons.casino_rounded, color: Colors.black, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Daily Rewards & Spin Wheel",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Spin daily to win free reading minutes & Karma points!",
                      style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.rotate_right_rounded, size: 18),
                  label: const Text("Spin Wheel", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Spinning Daily Reward Wheel... You won 50 Karma Points!"), backgroundColor: AppColors.successGreen),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.remove_red_eye_rounded, size: 18),
                  label: const Text("Crystal Ball", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Crystal Ball Reading: Great clarity and joy are heading your way."), backgroundColor: AppColors.accentGold),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
