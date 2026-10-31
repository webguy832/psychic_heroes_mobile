import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import 'app_logo.dart';

class AppFooterWidget extends StatelessWidget {
  const AppFooterWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.bgDarkCard,
        border: const Border(top: BorderSide(color: AppColors.borderDark, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & Brand Pitch
          const AppLogo(iconSize: 26, fontSize: 20, showSubtitle: true),
          const SizedBox(height: 12),
          const Text(
            "Trusted online psychic readings for love, career, tarot, astrology, and spiritual guidance. Connect with verified advisors anytime for clarity, comfort, and confidence.",
            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),

          // Services List
          const Text(
            "SERVICES",
            style: TextStyle(color: AppColors.accentGold, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.1),
          ),
          const SizedBox(height: 10),
          _buildFooterLink("Psychic Reading"),
          _buildFooterLink("Tarot Card Reading"),
          _buildFooterLink("Astrology & Horoscope"),
          _buildFooterLink("Love & Relationships Guidance"),
          _buildFooterLink("Career & Money Insight"),
          _buildFooterLink("Spiritual & Healing Sessions"),
          _buildFooterLink("Dreams & Numerology Readings"),

          const SizedBox(height: 24),

          // Contact Details
          const Text(
            "CONTACT US",
            style: TextStyle(color: AppColors.accentGold, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.1),
          ),
          const SizedBox(height: 10),
          _buildContactRow(Icons.email_outlined, "support@psychicheroes.com"),
          _buildContactRow(Icons.location_on_outlined, "244 Fifth Avenue, Suite 2322, New York, N.Y. 10001, USA"),
          _buildContactRow(Icons.business_outlined, "Shelton Street, Covent Garden London, WC2H 9JQ, UK"),

          const SizedBox(height: 24),
          const Divider(color: AppColors.borderDark),
          const SizedBox(height: 16),

          // Disclaimer & Copyright
          const Text(
            "For entertainment purposes only. Must be 18+ to use services.",
            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11),
          ),
          const SizedBox(height: 6),
          const Text(
            "© 2026 PsychicHeroes. All Rights Reserved. | Terms of Service | Privacy Policy",
            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.chevron_right_rounded, color: AppColors.primaryLight, size: 16),
          const SizedBox(width: 4),
          Text(
            title,
            style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accentGold, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
