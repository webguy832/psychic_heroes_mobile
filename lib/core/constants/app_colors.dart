import 'package:flutter/material.dart';

class AppColors {
  // Primary Web App Brand Palette
  static const Color primary = Color(0xFF2B0844);         // Deep Cosmic Royal Purple (Web Main Brand)
  static const Color primaryDark = Color(0xFF1F0433);     // Darker Cosmic Purple
  static const Color primaryLight = Color(0xFF5A2D82);    // Royal Violet Highlight
  
  // Secondary / Action CTAs (Matching Original Web App)
  static const Color ctaGreen = Color(0xFF2E7D32);        // Web Primary Green CTA Button
  static const Color ctaGreenHover = Color(0xFF256428);   // Web Green Hover State
  static const Color accentGold = Color(0xFFD1AB75);      // Web Mystic Gold Accent
  static const Color accentGoldDark = Color(0xFFC5A059);  // Web Dark Gold Accent
  static const Color accentPurple = Color(0xFF7A2D91);    // Web Purple Highlight
  static const Color accentCyan = Color(0xFF00CEC9);      // Glowing Cyan Accent
  
  // Backgrounds (Matching Web App Light & Deep Purple Layouts)
  static const Color bgDark = Color(0xFF2B0844);          // Deep Purple Body / Header Background
  static const Color bgDarkCard = Color(0xFF1F0433);      // Card Background Dark
  static const Color bgDarkCardElevated = Color(0xFF3B0D5D); // Elevated Card Dark
  static const Color bgLight = Color(0xFFF9F7FF);         // Web Soft Lavender Light Background
  static const Color bgLightCard = Color(0xFFFFFFFF);     // Card Background White
  
  // Status Colors (Matching Web Advisor Cards)
  static const Color onlineGreen = Color(0xFF2E7D32);     // Advisor Online Status
  static const Color busyOrange = Color(0xFFF59E0B);      // Advisor Busy Status
  static const Color offlineGrey = Color(0xFF6B7280);     // Advisor Offline Status
  static const Color errorRed = Color(0xFFDC2626);        // Error Red
  static const Color successGreen = Color(0xFF16A34A);    // Success Green
  
  // Text Colors
  static const Color textPrimaryDark = Color(0xFFFFFFFF); // White Text on Dark
  static const Color textSecondaryDark = Color(0xFFD1D5DB); // Muted Text on Dark
  static const Color textPrimaryLight = Color(0xFF1F2937); // Dark Charcoal Text on Light
  static const Color textSecondaryLight = Color(0xFF6B7280); // Muted Text on Light
  static const Color textGold = Color(0xFFD1AB75);        // Mystic Gold Text
  
  // Borders & Dividers
  static const Color borderDark = Color(0xFF4B1361);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderGold = Color(0xFFD1AB75);

  // Gradients (Matching Original Web App)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2B0844), Color(0xFF4B1361)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF2B0844), Color(0xFF1F0433)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient ctaGreenGradient = LinearGradient(
    colors: [Color(0xFF2E7D32), Color(0xFF256428)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD1AB75), Color(0xFFC5A059)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF2B0844), Color(0xFF1F0433)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

