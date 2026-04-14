import 'package:flutter/material.dart';
import '../theme.dart';

class NeoButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool compact;
  final bool expand;
  final EdgeInsetsGeometry? padding;

  const NeoButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
    this.icon,
    this.trailingIcon,
    this.compact = false,
    this.expand = false,
    this.padding,
  });

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;
    final bgColor = isDisabled
        ? Colors.grey.shade300
        : (widget.color ?? AppColors.yellow);
    final shadowOffset = isDisabled
        ? 4.0
        : _pressed
        ? 2.0
        : _hovered
        ? 5.0
        : 4.0;

    return MouseRegion(
      onEnter: isDisabled ? null : (_) => setState(() => _hovered = true),
      onExit: isDisabled ? null : (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _pressed
            ? 0.992
            : _hovered
            ? 1.0
            : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            onHighlightChanged: isDisabled
                ? null
                : (value) => setState(() => _pressed = value),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutCubic,
              width: widget.expand ? double.infinity : null,
              padding:
                  widget.padding ??
                  (widget.compact
                      ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
                      : const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        )),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDisabled ? Colors.grey.shade500 : AppColors.border,
                  width: 2.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDisabled ? Colors.grey.shade500 : AppColors.shadow,
                    offset: Offset(shadowOffset, shadowOffset),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: widget.expand
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: widget.compact ? 16 : 18,
                      color: AppColors.ink,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isDisabled
                            ? Colors.grey.shade600
                            : AppColors.ink,
                        fontSize: widget.compact ? 13 : 15,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  if (widget.trailingIcon != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      widget.trailingIcon,
                      size: widget.compact ? 16 : 18,
                      color: AppColors.ink,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
