import 'package:go_router/go_router.dart';

import '../../features/bookmarks/bookmarks_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/learn/learn_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/quran/quran_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/splash/splash_screen.dart';

abstract final class Routes {
  static const splash = '/';
  static const home = '/home';
  static const quran = '/quran';
  static const learn = '/learn';
  static const bookmarks = '/bookmarks';
  static const profile = '/profile';
}

final appRouter = GoRouter(
  initialLocation: Routes.splash,
  routes: [
    GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => MainShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: Routes.quran, builder: (_, _) => const QuranScreen()),
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
