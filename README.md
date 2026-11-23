# PORI (পড়ি)

A Quran learning app for Android, built with Flutter.

## Structure
```
lib/
  core/       theme, router, settings, shared widgets, utils
  features/   splash, shell (bottom nav), home, quran, learn, bookmarks, profile
assets/fonts/ Amiri (Arabic), Hind Siliguri (Bengali), both OFL
docs/screenshots/
```
Stack: Flutter 3.50 · Riverpod · go_router · shared_preferences.

Religious content rules and source tracking: see [CONTENT_SOURCES.md](CONTENT_SOURCES.md).

## Commands
```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```
