import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:time_tracker/app/app.dart';
import 'package:time_tracker/core/config/app_environment.dart';

void main() {
  testWidgets('Time Tracker app loads', (tester) async {
    const config = AppConfig(
      environment: AppEnvironment.development,
      appName: 'Time Tracker Dev',
    );

    await tester.pumpWidget(
      ProviderScope(child: TimeTrackerApp(config: config)),
    );

    await tester.pump();

    expect(find.byType(TimeTrackerApp), findsOneWidget);
  });
}
