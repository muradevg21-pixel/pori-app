import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../features/bookmarks/bookmarks_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/learn/course_screen.dart';
import '../../features/learn/learn_screen.dart';
import '../../features/learn/lesson_screen.dart';
import '../../features/learn/quiz_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/quran/quran_screen.dart';
import '../../features/quran/reader_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/splash/splash_screen.dart';

abstract final class Routes {
  static const splash = '/';
  static const home = '/home';
  static const quran = '/quran';
  static const learn = '/learn';
  static const bookmarks = '/bookmarks';
  static const profile = '/profile';
  static String reader(int surah, {int? verse}) =>
      '/read/$surah${verse != null ? '?verse=$verse' : ''}';
}

final appRouter = GoRouter(
  initialLocation: Routes.splash,
  routes: [
    GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
    GoRoute(
      path: '/learn/:course',
      builder: (_, s) => CourseScreen(courseId: s.pathParameters['course']!),
    ),
    GoRoute(
      path: '/learn/:course/:lesson',
      builder: (_, s) => LessonScreen(
          courseId: s.pathParameters['course']!,
          lessonId: s.pathParameters['lesson']!),
    ),
    GoRoute(
      path: '/learn/:course/:lesson/quiz',
      builder: (_, s) => QuizScreen(
          courseId: s.pathParameters['course']!,
          lessonId: s.pathParameters['lesson']!),
    ),
    GoRoute(
      path: '/read/:surah',
      builder: (_, state) => ReaderScreen(
        surah: int.parse(state.pathParameters['surah']!),
        initialVerse: int.tryParse(state.uri.queryParameters['verse'] ?? ''),
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => MainShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: Routes.quran,
            builder: (_, state) => QuranScreen(
              key: ValueKey(state.uri.queryParameters['search']),
              startSearching: state.uri.queryParameters['search'] == '1',
            ),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: Routes.learn, builder: (_, _) => const LearnScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
              path: Routes.bookmarks,
              builder: (_, _) => const BookmarksScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: Routes.profile, builder: (_, _) => const ProfileScreen()),
        ]),
      ],
    ),
  ],
);
