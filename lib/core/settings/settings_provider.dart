import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in main() with the loaded instance.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences not initialised'),
);

@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.arabicFontSize = 30,
    this.banglaFontSize = 16,
    this.showPronunciation = true,
    this.showTranslation = true,
    this.reciterId = 7,
  });

  final ThemeMode themeMode;
  final double arabicFontSize;
  final double banglaFontSize;
  final bool showPronunciation;
  final bool showTranslation;

  /// Quran.com recitation id (see assets/quran/reciters.json).
  final int reciterId;

  AppSettings copyWith({
    ThemeMode? themeMode,
    double? arabicFontSize,
    double? banglaFontSize,
    bool? showPronunciation,
    bool? showTranslation,
    int? reciterId,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        arabicFontSize: arabicFontSize ?? this.arabicFontSize,
        banglaFontSize: banglaFontSize ?? this.banglaFontSize,
        showPronunciation: showPronunciation ?? this.showPronunciation,
        showTranslation: showTranslation ?? this.showTranslation,
        reciterId: reciterId ?? this.reciterId,
      );
}

class SettingsNotifier extends Notifier<AppSettings> {
  static const _kTheme = 'theme_mode';
  static const _kArabic = 'arabic_font_size';
  static const _kBangla = 'bangla_font_size';
  static const _kPron = 'show_pronunciation';
  static const _kTrans = 'show_translation';
  static const _kReciter = 'reciter_id';

  SharedPreferences get _prefs => ref.read(sharedPrefsProvider);

  @override
  AppSettings build() {
    final p = ref.watch(sharedPrefsProvider);
    return AppSettings(
      themeMode: ThemeMode.values[p.getInt(_kTheme) ?? ThemeMode.system.index],
      arabicFontSize: p.getDouble(_kArabic) ?? 30,
      banglaFontSize: p.getDouble(_kBangla) ?? 16,
      showPronunciation: p.getBool(_kPron) ?? true,
      showTranslation: p.getBool(_kTrans) ?? true,
      reciterId: p.getInt(_kReciter) ?? 7,
    );
  }

  void setThemeMode(ThemeMode m) {
    state = state.copyWith(themeMode: m);
    _prefs.setInt(_kTheme, m.index);
  }

  void setArabicFontSize(double v) {
    state = state.copyWith(arabicFontSize: v);
    _prefs.setDouble(_kArabic, v);
  }

  void setBanglaFontSize(double v) {
    state = state.copyWith(banglaFontSize: v);
    _prefs.setDouble(_kBangla, v);
  }

  void setShowPronunciation(bool v) {
    state = state.copyWith(showPronunciation: v);
    _prefs.setBool(_kPron, v);
  }

  void setReciter(int id) {
    state = state.copyWith(reciterId: id);
    _prefs.setInt(_kReciter, id);
  }

  void setShowTranslation(bool v) {
    state = state.copyWith(showTranslation: v);
    _prefs.setBool(_kTrans, v);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
