import 'package:material_ui/material_ui.dart';

/// PORI brand palette: emerald, cream and subtle gold.
abstract final class AppColors {
  // Emerald
  static const emerald950 = Color(0xFF042A21);
  static const emerald900 = Color(0xFF06392C);
  static const emerald800 = Color(0xFF0A4A3A);
  static const emerald700 = Color(0xFF0D5E49);
  static const emerald600 = Color(0xFF127558);
  static const emerald500 = Color(0xFF1A8F6C);
  static const emerald100 = Color(0xFFDCEFE6);
  static const emerald50 = Color(0xFFEEF7F2);

  // Cream
  static const cream = Color(0xFFFBF7EE);
  static const cream200 = Color(0xFFF4ECDA);
  static const cream300 = Color(0xFFEADFC4);

  // Gold
  static const gold = Color(0xFFC6A15B);
  static const goldLight = Color(0xFFE5CF97);
  static const goldDeep = Color(0xFF9C7A36);

  // Text
  static const ink = Color(0xFF1B2620);
  static const inkSoft = Color(0xFF5E6B63);

  // Dark mode surfaces
  static const night = Color(0xFF08130F);
  static const nightSurface = Color(0xFF0F1F19);
  static const nightCard = Color(0xFF152A22);

  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [emerald700, emerald900],
  );
}
