import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Subtle repeating eight-point star (Rub el Hizb style) geometric pattern.
class IslamicPattern extends StatelessWidget {
  const IslamicPattern({
    super.key,
    this.color = const Color(0xFFC6A15B),
    this.opacity = 0.12,
    this.tile = 56,
  });

  final Color color;
  final double opacity;
  final double tile;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: CustomPaint(
          size: Size.infinite,
          painter: _PatternPainter(color.withValues(alpha: opacity), tile),
        ),
      );
}

class _PatternPainter extends CustomPainter {
  _PatternPainter(this.color, this.tile);
  final Color color;
  final double tile;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (double y = 0; y < size.height + tile; y += tile) {
      for (double x = 0; x < size.width + tile; x += tile) {
        final offset = ((y / tile).round().isOdd) ? tile / 2 : 0.0;
        drawStar(canvas, Offset(x + offset, y), tile * 0.32, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_PatternPainter old) =>
      old.color != color || old.tile != tile;
}

/// Draws an eight-point star made of two overlapping squares.
void drawStar(Canvas canvas, Offset c, double r, Paint paint) {
  for (final rot in [0.0, math.pi / 4]) {
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final a = rot + i * math.pi / 2 + math.pi / 4;
      final p = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }
  canvas.drawCircle(c, r * 0.28, paint);
}

/// A single decorative star badge, e.g. for surah numbers.
class StarBadge extends StatelessWidget {
  const StarBadge({
    super.key,
    required this.label,
    this.size = 44,
    this.color,
  });

  final String label;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.secondary;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _BadgePainter(c),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: size * 0.3,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgePainter extends CustomPainter {
  _BadgePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 1;
    for (final rot in [0.0, math.pi / 4]) {
      final path = Path();
      for (var i = 0; i < 4; i++) {
        final a = rot + i * math.pi / 2 + math.pi / 4;
        final p = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_BadgePainter old) => old.color != color;
}
