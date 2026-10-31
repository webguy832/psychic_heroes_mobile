import 'package:flutter/material.dart';

class AppStyles {
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 14.0;
  static const double borderRadiusLarge = 20.0;
  
  static const EdgeInsets paddingPage = EdgeInsets.all(16.0);
  static const EdgeInsets paddingCard = EdgeInsets.all(16.0);
  
  static BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withOpacity(0.2),
    blurRadius: 10,
    offset: const Offset(0, 4),
  );
  
  static BoxShadow glowingShadow(Color color) => BoxShadow(
    color: color.withOpacity(0.3),
    blurRadius: 12,
    spreadRadius: 1,
    offset: const Offset(0, 4),
  );
}
