import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/surfaces/app_glass_surface.dart';

class HomeTodayOverview extends StatelessWidget {
  const HomeTodayOverview({
    super.key,
    required this.totalTime,
    required this.goalTime,
    required this.progress,
    required this.hourlyActivity,
  });

  final String totalTime;
  final String goalTime;

  /// Progress between 0.0 and 1.0.
  final double progress;

  /// 24 values, one for each hour of the day.
  final List<double> hourlyActivity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryColor = isDark
        ? AppColors.darkSecondaryText
        : AppColors.lightSecondaryText;
    final mutedColor = isDark
        ? AppColors.darkMutedText
        : AppColors.lightMutedText;

    final safeProgress = progress.clamp(0.0, 1.0);

    return AppGlassSurface(
      variant: AppSurfaceVariant.standard,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today',
            style: theme.textTheme.titleSmall?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Goal progress ring.
              SizedBox(
                width: 88,
                height: 88,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(78, 78),
                      painter: _ProgressRingPainter(
                        progress: safeProgress,
                        trackColor: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                        progressColor: AppColors.primary,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_rounded,
                          size: 13,
                          color: secondaryColor,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${(safeProgress * 100).round()}%',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Total time and hourly activity.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Time',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: secondaryColor,
                      ),
                    ),
                    Text(
                      totalTime,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: 25,
                        height: 1.1,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      'Of $goalTime Goal',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: secondaryColor,
                      ),
                    ),
                    const SizedBox(height: 7),
                    SizedBox(
                      height: 37,
                      width: double.infinity,
                      child: _HourlyActivityChart(
                        values: hourlyActivity,
                        barColor: AppColors.primary,
                        inactiveBarColor: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                        labelColor: mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 8.0;
    final rect = Offset.zero & size;
    final ringRect = rect.deflate(strokeWidth / 2);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(ringRect, -math.pi / 2, math.pi * 2, false, trackPaint);

    canvas.drawArc(
      ringRect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}

class _HourlyActivityChart extends StatelessWidget {
  const _HourlyActivityChart({
    required this.values,
    required this.barColor,
    required this.inactiveBarColor,
    required this.labelColor,
  });

  final List<double> values;
  final Color barColor;
  final Color inactiveBarColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HourlyActivityPainter(
        values: values,
        barColor: barColor,
        inactiveBarColor: inactiveBarColor,
        labelColor: labelColor,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _HourlyActivityPainter extends CustomPainter {
  const _HourlyActivityPainter({
    required this.values,
    required this.barColor,
    required this.inactiveBarColor,
    required this.labelColor,
  });

  final List<double> values;
  final Color barColor;
  final Color inactiveBarColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const labelHeight = 10.0;
    const barAreaBottomGap = 3.0;
    const barWidth = 2.5;
    const barGap = 2.0;

    final chartHeight = size.height - labelHeight;
    final maxBarHeight = chartHeight - barAreaBottomGap;

    final barPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;

    final availableWidth = size.width;

    final actualGap = values.length > 1
        ? (availableWidth - values.length * barWidth) / (values.length - 1)
        : 0.0;

    final spacing = math.max(barGap, actualGap);
    final totalWidth = values.length * barWidth + (values.length - 1) * spacing;
    final startX = (availableWidth - totalWidth) / 2;

    for (var i = 0; i < values.length; i++) {
      final value = values[i].clamp(0.0, 1.0);
      final barHeight = math.max(2.0, maxBarHeight * value);

      barPaint.color = value > 0 ? barColor : inactiveBarColor;

      final x = startX + i * (barWidth + spacing);

      canvas.drawLine(
        Offset(x + barWidth / 2, maxBarHeight - barHeight),
        Offset(x + barWidth / 2, maxBarHeight),
        barPaint,
      );
    }

    final labels = const [
      (0, '00'),
      (6, '06'),
      (12, '12'),
      (18, '18'),
      (23, '23'),
    ];

    final textStyle = TextStyle(
      color: labelColor,
      fontSize: 7,
      fontWeight: FontWeight.w400,
    );

    for (final (hour, label) in labels) {
      final x = startX + hour * (barWidth + spacing);
      final textPainter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(
          (x - textPainter.width / 2).clamp(
            0.0,
            size.width - textPainter.width,
          ),
          chartHeight,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HourlyActivityPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.barColor != barColor ||
        oldDelegate.inactiveBarColor != inactiveBarColor ||
        oldDelegate.labelColor != labelColor;
  }
}
