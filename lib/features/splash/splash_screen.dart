import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/islamic_pattern.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
    ..forward();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) context.go(Routes.home);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: Stack(
          children: [
            const Positioned.fill(child: IslamicPattern(opacity: 0.14, tile: 64)),
            Center(
              child: FadeTransition(
                opacity: fade,
                child: ScaleTransition(
                  scale: Tween(begin: 0.92, end: 1.0).animate(fade),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.emerald950.withValues(alpha: 0.35),
                          border: Border.all(color: AppColors.gold, width: 1.5),
                        ),
                        child: const Icon(Icons.menu_book_rounded,
                            size: 56, color: AppColors.goldLight),
                      ),
                      const SizedBox(height: 28),
                      const Text('পড়ি',
                          style: TextStyle(
                              fontSize: 56,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                              color: AppColors.cream)),
                      const SizedBox(height: 4),
                      const Text('P O R I',
                          style: TextStyle(
                              fontSize: 16,
                              letterSpacing: 6,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gold)),
                      const SizedBox(height: 18),
                      Text('কুরআন পড়ি · কুরআন শিখি',
                          style: TextStyle(
                              fontSize: 15,
                              color: AppColors.cream.withValues(alpha: 0.8))),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
