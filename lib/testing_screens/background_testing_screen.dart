import 'package:flutter/material.dart';

import '../core/theme/app_dimensions.dart';
import '../core/widgets/app_background.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/surfaces/app_glass_card.dart';
import '../core/widgets/surfaces/app_glass_surface.dart';
import '../core/widgets/surfaces/app_outlined_card.dart';
import '../features/home/presentation/widgets/home_quick_actions.dart';
import '../features/home/presentation/widgets/home_recent_entries.dart';
import '../features/home/presentation/widgets/home_timer_widget.dart';
import '../features/home/presentation/widgets/home_today_overview.dart';

class BackgroundTestingScreen extends StatefulWidget {
  const BackgroundTestingScreen({super.key});

  @override
  State<BackgroundTestingScreen> createState() =>
      _BackgroundTestingScreenState();
}

class _BackgroundTestingScreenState extends State<BackgroundTestingScreen> {
  LightBackgroundVariant _lightVariant = LightBackgroundVariant.light;
  bool _readabilityOverlay = false;
  bool _isTimerRunning = false;
  double _backgroundScale = 1.8;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        lightVariant: _lightVariant,
        backgroundScale: _backgroundScale,
        readabilityOverlay: _readabilityOverlay,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Background Studio',
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Preview your app backgrounds with sample content.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Background controls
              SegmentedButton<LightBackgroundVariant>(
                segments: const [
                  ButtonSegment(
                    value: LightBackgroundVariant.light,
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: LightBackgroundVariant.lightWhite,
                    label: Text('White'),
                  ),
                ],
                selected: {_lightVariant},
                onSelectionChanged: (selection) {
                  setState(() {
                    _lightVariant = selection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Readability overlay'),
                value: _readabilityOverlay,
                onChanged: (value) {
                  setState(() {
                    _readabilityOverlay = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Background scale: ${_backgroundScale.toStringAsFixed(1)}x',
                style: theme.textTheme.bodyMedium,
              ),
              Slider(
                value: _backgroundScale,
                min: 1.0,
                max: 2.5,
                divisions: 15,
                onChanged: (value) {
                  setState(() {
                    _backgroundScale = value;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Dummy dashboard content
              Text('Today', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total tracked', style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      Text('04:32:18', style: theme.textTheme.displaySmall),
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(value: 0.72),
                      const SizedBox(height: 8),
                      const Text('72% of your daily goal'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Surface component showcase
              Text('Surface Components', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),

              AppGlassSurface(
                variant: AppSurfaceVariant.standard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent Entries', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Your latest tracked activities.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Icon-only action buttons with labels underneath
              Text('Action Buttons', style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  _ActionButtonPreview(
                    icon: Icons.add_task_outlined,
                    label: 'Add Task',
                  ),
                  _ActionButtonPreview(
                    icon: Icons.edit_calendar_outlined,
                    label: 'Add Time',
                  ),
                  _ActionButtonPreview(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Switch',
                  ),
                  _ActionButtonPreview(
                    icon: Icons.more_horiz_rounded,
                    label: 'More',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Interactive timer
              HomeTimerWidget(
                taskName: 'Design System',
                taskIcon: Icons.palette_outlined,
                elapsedTime: '01:24:38',
                isRunning: _isTimerRunning,
                onToggle: () {
                  setState(() => _isTimerRunning = true);
                },
                onPause: () {
                  setState(() => _isTimerRunning = false);
                },
                onStop: () {
                  setState(() => _isTimerRunning = false);
                },
              ),

              const SizedBox(height: 24),

              HomeQuickActions(
                onAddTask: () {},
                onAddTime: () {},
                onSwitchTask: () {},
                onMore: () {},
              ),

              const SizedBox(height: 24),

              HomeRecentEntries(
                onViewAll: () {},
                entries: const [
                  RecentTimeEntryItem(
                    taskId: 1,
                    taskName: 'Portfolio Redesign',
                    categoryName: 'Design',
                    icon: Icons.palette_outlined,
                    totalDuration: '12h 30m',
                  ),
                  RecentTimeEntryItem(
                    taskId: 1,
                    taskName: 'Portfolio Redesign',
                    categoryName: 'Design',
                    icon: Icons.palette_outlined,
                    totalDuration: '12h 30m',
                  ),
                  RecentTimeEntryItem(
                    taskId: 1,
                    taskName: 'Portfolio Redesign',
                    categoryName: 'Design',
                    icon: Icons.palette_outlined,
                    totalDuration: '12h 30m',
                  ),
                ],
              ),

              const SizedBox(height: 24),
              HomeTodayOverview(
                totalTime: '05:51',
                goalTime: '12h',
                progress: 0.48,
                hourlyActivity: const [
                  0.05,
                  0.03,
                  0.02,
                  0.02,
                  0.02,
                  0.04,
                  0.05,
                  0.03,
                  0.02,
                  0.02,
                  0.04,
                  0.12,
                  0.55,
                  0.85,
                  0.95,
                  0.70,
                  0.35,
                  0.65,
                  0.90,
                  0.55,
                  0.25,
                  0.60,
                  0.35,
                  0.20,
                ],
              ),
              const SizedBox(height: 24),

              // AI button
              AppGlassSurface(
                variant: AppSurfaceVariant.ai,
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'AI Time Insights',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Other card styles
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Standard Card', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      'A clean elevated surface for general content.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppOutlinedCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Outlined Card', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      'A subtle border with a translucent background.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Glass Card', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      'A blurred translucent surface.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Recent tasks
              Text('Recent tasks', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              const _DummyTaskCard(
                title: 'Design system',
                subtitle: 'UI / UX',
                duration: '01:42:10',
                icon: Icons.palette_outlined,
              ),
              const _DummyTaskCard(
                title: 'Flutter development',
                subtitle: 'Time Tracker',
                duration: '02:15:08',
                icon: Icons.code,
              ),
              const _DummyTaskCard(
                title: 'Client meeting',
                subtitle: 'Freelance',
                duration: '00:35:00',
                icon: Icons.people_outline,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start timer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButtonPreview extends StatelessWidget {
  const _ActionButtonPreview({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: AppGlassSurface(
            variant: AppSurfaceVariant.action,
            radius: AppRadius.lg,
            padding: EdgeInsets.zero,
            child: Center(
              child: Icon(
                icon,
                size: 24,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _DummyTaskCard extends StatelessWidget {
  const _DummyTaskCard({
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String duration;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(duration, style: Theme.of(context).textTheme.labelLarge),
      ),
    );
  }
}
