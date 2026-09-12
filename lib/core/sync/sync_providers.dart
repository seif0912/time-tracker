import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sync_id_generator.dart';

final syncIdGeneratorProvider = Provider<SyncIdGenerator>((ref) {
  return const SyncIdGenerator();
});
