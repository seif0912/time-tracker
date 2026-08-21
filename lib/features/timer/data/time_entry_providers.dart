import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/database/database_provider.dart';
import 'time_entry_repository.dart';

final timeEntryRepositoryProvider = Provider<TimeEntryRepository>((ref) {
  final database = ref.watch(databaseProvider);

  return TimeEntryRepository(database);
});
