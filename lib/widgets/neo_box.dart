import 'package:flutter/material.dart';
import '../theme.dart';

class NeoBox extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double borderWidth;
  final double shadowOffset;
  final double radius;
  final Color borderColor;
  final Color shadowColor;

  const NeoBox({
    super.key,
    required this.child,
    this.color = AppColors.white,
    this.padding = const EdgeInsets.all(20),
    this.borderWidth = 3,
    this.shadowOffset = 6,
    this.radius = 20,
    this.borderColor = AppColors.border,
    this.shadowColor = AppColors.shadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            offset: Offset(shadowOffset, shadowOffset),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}
