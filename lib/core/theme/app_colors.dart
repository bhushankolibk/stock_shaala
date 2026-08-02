import 'package:flutter/material.dart';

/// StockShaala color palette — dark-first financial theme.
class AppColors {
  AppColors._();

  static const bg = Color(0xFF08101E);
  static const surface = Color(0xFF0F1923);
  static const card = Color(0xFF141F2E);
  static const card2 = Color(0xFF192435);
  static const border = Color(0xFF1C2B3E);
  static const border2 = Color(0xFF243347);

  static const up = Color(0xFF00C896);
  static const down = Color(0xFFFF4D6A);
  static const accent = Color(0xFFF5A623);
  static const purple = Color(0xFF8A5CF5);
  static const blue = Color(0xFF3B82F6);

  static const text = Color(0xFFE6EDF7);
  static const muted = Color(0xFF5D7290);
  static const dim = Color(0xFF1A2840);
  static const dim2 = Color(0xFF223050);

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF5A623), Color(0xFFFF8C42)],
  );
}
