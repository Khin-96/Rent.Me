import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette — near-black, inspired by Uber
  static const Color primary   = Color(0xFF0A0A0A);
  static const Color white     = Color(0xFFFFFFFF);

  // Supporting colors remain within the existing black-and-white palette.
  static const Color accent    = Color(0xFF2A2A2A);
  static const Color routeBlue = Color(0xFF0A0A0A);
  static const Color surface   = Color(0xFFF8F8F8);

  // Gray scale
  static const Color gray50  = Color(0xFFF9F9F9);
  static const Color gray100 = Color(0xFFF3F3F3);
  static const Color gray200 = Color(0xFFE8E8E8);
  static const Color gray300 = Color(0xFFD1D1D1);
  static const Color gray400 = Color(0xFFAAAAAA);
  static const Color gray500 = Color(0xFF8A8A8A);
  static const Color gray600 = Color(0xFF636363);
  static const Color gray700 = Color(0xFF3D3D3D);
  static const Color gray800 = Color(0xFF2A2A2A);
  static const Color gray900 = Color(0xFF1A1A1A);

  // Semantic
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFE65100);
  static const Color error   = Color(0xFFD32F2F);
  static const Color info    = Color(0xFF1565C0);

  // Map-specific
  static const Color markerDefault  = Color(0xFF0A0A0A);
  static const Color markerSelected = Color(0xFF0A0A0A);
  static const Color locationPulse  = Color(0xFF2A2A2A);
  static const Color routeStroke    = Color(0xFF0A0A0A);
  static const Color routeBorder    = Color(0xFFFFFFFF);
}
