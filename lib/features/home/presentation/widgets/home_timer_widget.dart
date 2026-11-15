import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/surfaces/app_glass_surface.dart';

class HomeTimerWidget extends StatelessWidget {
  const HomeTimerWidget({
    super.key,
    required this.taskName,
    required this.taskIcon,
    required this.elapsedTime,
    required this.isRunning,
    this.isPaused = false,
    required this.onToggle,
    this.onPause,
    this.onStop,
  });

  final String taskName;
  final IconData taskIcon;
  final String elapsedTime;
  final bool isRunning;
  final bool isPaused;
  final VoidCallback? onToggle;
  final VoidCallback? onPause;
  final VoidCallback? onStop;

  static const _dark = Color(0xFF111110);
  static const _light = Color(0xFFF5F1E8);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive = isRunning || isPaused;

    final inactiveForeground = isDark
        ? AppColors.darkText
        : AppColors.lightText;

    final inactiveButtonBackground = isDark ? AppColors.darkText : _dark;
    final inactiveButtonIcon = isDark ? _dark : AppColors.white;

    final activeForeground = _light;

    return SizedBox(
      width: double.infinity,
      height: 190,
      child: AppGlassSurface(
        variant: isActive
            ? AppSurfaceVariant.activeTimer
            : AppSurfaceVariant.inactiveTimer,
        padding: const EdgeInsets.fromLTRB(17, 30, 17, 17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  taskIcon,
                  size: 25,
                  color: isActive ? activeForeground : inactiveForeground,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    taskName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: isActive ? activeForeground : inactiveForeground,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            Padding(
              padding: const EdgeInsets.only(left: 35),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                style: theme.textTheme.displayMedium!.copyWith(
                  fontSize: 48,
                  height: 1,
                  fontWeight: FontWeight.w500,
                  color: isActive ? activeForeground : inactiveForeground,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                child: Text(
                  elapsedTime,
                  maxLines: 1,
                  textAlign: TextAlign.left,
                ),
              ),
            ),

            const Spacer(),

            Align(
              alignment: Alignment.bottomRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isRunning)
                    _TimerControlButton(
                      backgroundColor: isActive
                          ? Colors.transparent
                          : inactiveButtonBackground,
                      borderColor: isPaused ? activeForeground : null,
                      iconColor: isActive
                          ? activeForeground
                          : inactiveButtonIcon,
                      icon: Icons.play_arrow_rounded,
                      onPressed: onToggle,
                    )
                  else
                    _TimerControlButton(
                      backgroundColor: Colors.transparent,
                      borderColor: activeForeground,
                      iconColor: activeForeground,
                      icon: Icons.pause_rounded,
                      onPressed: onPause,
                    ),

                  if (isActive) ...[
                    const SizedBox(width: 12),
                    _TimerControlButton(
                      backgroundColor: activeForeground,
                      iconColor: _dark,
                      icon: Icons.stop_rounded,
                      onPressed: onStop,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerControlButton extends StatelessWidget {
  const _TimerControlButton({
    required this.backgroundColor,
    required this.iconColor,
    required this.icon,
    required this.onPressed,
    this.borderColor,
  });

  final Color backgroundColor;
  final Color iconColor;
  final Color? borderColor;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: Material(
        color: backgroundColor,
        shape: CircleBorder(
          side: BorderSide(color: borderColor ?? Colors.transparent, width: 1),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Center(child: Icon(icon, size: 22, color: iconColor)),
        ),
      ),
    );
  }
}
