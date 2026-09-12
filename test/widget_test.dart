import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:time_tracker/app/app.dart';
import 'package:time_tracker/core/config/app_environment.dart';
import 'package:time_tracker/features/authentication/domain/auth_state.dart';
import 'package:time_tracker/features/authentication/presentation/auth_controller.dart';

class FakeAuthController extends AuthController {
  @override
  AuthState build() {
    return const AuthState(status: AuthStatus.unauthenticated);
  }
}

void main() {
  testWidgets('Time Tracker app loads', (tester) async {
    const config = AppConfig(
      environment: AppEnvironment.development,
      appName: 'Time Tracker Dev',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(FakeAuthController.new),
        ],
        child: TimeTrackerApp(config: config),
      ),
    );

    await tester.pump();

    expect(find.byType(TimeTrackerApp), findsOneWidget);
  });
}
