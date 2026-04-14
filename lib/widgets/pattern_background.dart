import 'package:flutter/material.dart';
import '../theme.dart';

class PatternBackground extends StatelessWidget {
  final BackgroundPattern pattern;
  final Widget child;
  final Color backgroundColor;
  final Color patternColor;

  const PatternBackground({
    super.key,
    required this.pattern,
    required this.child,
    this.backgroundColor = AppColors.canvas,
    this.patternColor = AppColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: CustomPaint(
        painter: _PatternPainter(pattern: pattern, color: patternColor),
        child: child,
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  final BackgroundPattern pattern;
  final Color color;

  const _PatternPainter({required this.pattern, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    switch (pattern) {
      case BackgroundPattern.graph:
        _paintGraph(canvas, size);
        break;
      case BackgroundPattern.stripes:
        _paintStripes(canvas, size);
        break;
      case BackgroundPattern.bold:
        _paintBoldDots(canvas, size);
        break;
      case BackgroundPattern.solid:
        break;
      case BackgroundPattern.dotted:
        _paintDotted(canvas, size);
        break;
    }
  }

  void _paintGraph(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..strokeWidth = 1;
    const step = 30.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _paintStripes(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.06)
      ..strokeWidth = 2;
    const step = 18.0;
    for (double x = -size.height; x < size.width; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  void _paintBoldDots(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.16);
    const spacing = 40.0;
    for (double x = 0; x <= size.width; x += spacing) {
      for (double y = 0; y <= size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 3, paint);
      }
    }
  }

  void _paintDotted(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.12);
    const spacing = 24.0;
    for (double x = 0; x <= size.width; x += spacing) {
      for (double y = 0; y <= size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) {
    return oldDelegate.pattern != pattern || oldDelegate.color != color;
  }
}
