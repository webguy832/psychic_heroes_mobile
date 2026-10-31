import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double height;
  final double iconSize;
  final double fontSize;
  final bool showSubtitle;
  final bool isDarkBackground;

  const AppLogo({
    Key? key,
    this.height = 36,
    this.iconSize = 28,
    this.fontSize = 20,
    this.showSubtitle = false,
    this.isDarkBackground = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          'assets/images/logo.png',
          height: height,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(iconSize * 0.2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.goldGradient,
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                    size: iconSize * 0.8,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "PsychicHeroes",
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: isDarkBackground ? Colors.white : AppColors.primary,
                  ),
                ),
              ],
            );
          },
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 2),
          Text(
            "Trusted Spiritual & Psychic Guidance",
            style: TextStyle(
              fontSize: 11,
              color: isDarkBackground ? AppColors.accentGold : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ],
    );
  }
}

