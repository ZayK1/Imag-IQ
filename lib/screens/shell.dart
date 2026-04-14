import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme.dart';
import '../widgets/pattern_background.dart';
import 'student/student_home.dart';
import 'teacher/teacher_home.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  bool _dismissIntro = false;
  bool _showIntro = true;
  Timer? _introDismissTimer;
  Timer? _introRemoveTimer;

  @override
  void initState() {
    super.initState();
    _introDismissTimer = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      setState(() => _dismissIntro = true);
    });
    _introRemoveTimer = Timer(const Duration(milliseconds: 2240), () {
      if (!mounted) return;
      setState(() => _showIntro = false);
    });
  }

  @override
  void dispose() {
    _introDismissTimer?.cancel();
    _introRemoveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = _currentIndex == 0;
    final pattern = isTeacher
        ? BackgroundPattern.graph
        : BackgroundPattern.dotted;
    final accent = isTeacher ? AppColors.orange : AppColors.blue;

    return Scaffold(
      body: PatternBackground(
        pattern: pattern,
        patternColor: AppColors.ink,
        child: Stack(
          children: [
            AnimatedOpacity(
              opacity: _dismissIntro ? 1 : 0,
              duration: const Duration(milliseconds: 340),
              curve: Curves.easeOutCubic,
              child: AnimatedSlide(
                offset: _dismissIntro ? Offset.zero : const Offset(0, 0.025),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                child: SafeArea(
                  child: Column(
                    children: [
                      _ShellHeader(
                        currentIndex: _currentIndex,
                        accent: accent,
                        onRoleChanged: (index) =>
                            setState(() => _currentIndex = index),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final maxContentWidth = constraints.maxWidth >= 1850
                                ? 1780.0
                                : constraints.maxWidth >= 1600
                                ? 1660.0
                                : constraints.maxWidth;
                            final horizontalPadding =
                                constraints.maxWidth >= 1600
                                ? 28.0
                                : constraints.maxWidth >= 1200
                                ? 22.0
                                : 18.0;

                            return Padding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                22,
                                horizontalPadding,
                                22,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: maxContentWidth,
                                  ),
                                  child: IndexedStack(
                                    index: _currentIndex,
                                    children: const [
                                      TeacherHome(),
                                      StudentHome(),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_showIntro)
              IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _dismissIntro ? 0 : 1,
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  child: const _EntrySplash(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShellHeader extends StatelessWidget {
  final int currentIndex;
  final Color accent;
  final ValueChanged<int> onRoleChanged;

  const _ShellHeader({
    required this.currentIndex,
    required this.accent,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 3),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            offset: Offset(0, 5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 14,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.purple,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  PhosphorIconsRegular.chalkboardTeacher,
                  color: AppColors.ink,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Imag-IQ',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(fontSize: 28),
              ),
            ],
          ),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      offset: Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RolePill(
                      label: 'Teacher',
                      isSelected: currentIndex == 0,
                      activeColor: AppColors.ink,
                      inactiveColor: AppColors.canvas,
                      foregroundColor: currentIndex == 0
                          ? AppColors.white
                          : AppColors.ink,
                      onTap: () => onRoleChanged(0),
                    ),
                    _RolePill(
                      label: 'Student',
                      isSelected: currentIndex == 1,
                      activeColor: AppColors.ink,
                      inactiveColor: AppColors.canvas,
                      foregroundColor: currentIndex == 1
                          ? AppColors.white
                          : AppColors.ink,
                      onTap: () => onRoleChanged(1),
                    ),
                  ],
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EntrySplash extends StatelessWidget {
  const _EntrySplash();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.canvas.withValues(alpha: 0.96),
      child: Center(
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutCubic,
          offset: Offset.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Imag-IQ',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2.2,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: 90,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.purple,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.border, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  const _RolePill({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.foregroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : inactiveColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: foregroundColor,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
