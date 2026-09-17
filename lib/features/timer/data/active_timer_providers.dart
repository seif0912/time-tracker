import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/database/database_provider.dart';
import 'active_timer_repository.dart';

final activeTimerRepositoryProvider = Provider<ActiveTimerRepository>((ref) {
  final database = ref.watch(databaseProvider);

  return ActiveTimerRepository(database);
});
