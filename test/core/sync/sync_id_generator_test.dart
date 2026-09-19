import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/core/sync/sync_id_generator.dart';

void main() {
  test('generates unique UUIDs', () {
    const generator = SyncIdGenerator();

    final first = generator.generate();
    final second = generator.generate();

    expect(first, isNot(equals(second)));
    expect(
      first,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });
}
