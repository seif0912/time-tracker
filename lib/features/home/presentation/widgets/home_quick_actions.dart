import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/surfaces/app_glass_surface.dart';

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({
    super.key,
    required this.onAddTask,
    required this.onAddTime,
    required this.onSwitchTask,
    required this.onMore,
  });

  final VoidCallback onAddTask;
  final VoidCallback onAddTime;
  final VoidCallback onSwitchTask;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final labelColor = isDark ? AppColors.darkText : AppColors.lightText;
    final iconColor = isDark ? AppColors.darkText : AppColors.lightText;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _QuickActionItem(
          label: 'Add Task',
          icon: Icons.add_task_rounded,
          iconColor: iconColor,
          labelColor: labelColor,
          onTap: onAddTask,
        ),
        _QuickActionItem(
          label: 'Add Time',
          icon: Icons.add_rounded,
          iconColor: iconColor,
          labelColor: labelColor,
          onTap: onAddTime,
        ),
        _QuickActionItem(
          label: 'Switch Task',
          icon: Icons.swap_horiz_rounded,
          iconColor: iconColor,
          labelColor: labelColor,
          onTap: onSwitchTask,
        ),
        _QuickActionItem(
          label: 'More',
          icon: Icons.more_horiz_rounded,
          iconColor: iconColor,
          labelColor: labelColor,
          onTap: onMore,
        ),
      ],
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  const _QuickActionItem({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.labelColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final Color labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(18),
                child: AppGlassSurface(
                  variant: AppSurfaceVariant.action,
                  padding: EdgeInsets.zero,
                  child: Center(child: Icon(icon, size: 30, color: iconColor)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.visible,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}
