import 'dart:math' as math;

import 'package:flutter/material.dart';

class ThinkingSurface extends StatefulWidget {
  final bool active;
  final Widget child;
  final double radius;
  final double pulseScale;
  final Color tintColor;

  const ThinkingSurface({
    super.key,
    required this.active,
    required this.child,
    this.radius = 20,
    this.pulseScale = 1.004,
    this.tintColor = Colors.white,
  });

  @override
  State<ThinkingSurface> createState() => _ThinkingSurfaceState();
}

class _ThinkingSurfaceState extends State<ThinkingSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.active) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ThinkingSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final wave = (math.sin(_controller.value * math.pi * 2) + 1) / 2;
        final scale = 1 + ((widget.pulseScale - 1) * wave);

        return Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : MediaQuery.sizeOf(context).width;
              final sweepWidth = math.max(84.0, width * 0.28);
              final left =
                  (-sweepWidth) +
                  ((width + (sweepWidth * 2)) * _controller.value);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  child!,
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(widget.radius),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: widget.tintColor.withValues(
                                  alpha: 0.05 + (wave * 0.03),
                                ),
                              ),
                            ),
                            Positioned(
                              left: left,
                              top: -16,
                              bottom: -16,
                              child: Transform.rotate(
                                angle: 0.20,
                                child: Container(
                                  width: sweepWidth,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        widget.tintColor.withValues(alpha: 0),
                                        widget.tintColor.withValues(
                                          alpha: 0.22,
                                        ),
                                        widget.tintColor.withValues(alpha: 0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
