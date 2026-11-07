import 'package:flutter/material.dart';

import '../core/widgets/app_background.dart';

class BackgroundTestingScreen extends StatefulWidget {
  const BackgroundTestingScreen({super.key});

  @override
  State<BackgroundTestingScreen> createState() =>
      _BackgroundTestingScreenState();
}

class _BackgroundTestingScreenState extends State<BackgroundTestingScreen> {
  LightBackgroundVariant _lightVariant = LightBackgroundVariant.light;

  bool _readabilityOverlay = false;

  double _backgroundScale = 1.8;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                'Preview your app backgrounds with sample content.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 24),

              // Light background selector
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

              // Readability overlay
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

              // Background scale
              Text(
                'Background scale: ${_backgroundScale.toStringAsFixed(1)}x',
                style: Theme.of(context).textTheme.bodyMedium,
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
              Text('Today', style: Theme.of(context).textTheme.titleLarge),

              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total tracked',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '04:32:18',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(value: 0.72),
                      const SizedBox(height: 8),
                      const Text('72% of your daily goal'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Recent tasks',
                style: Theme.of(context).textTheme.titleLarge,
              ),

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
