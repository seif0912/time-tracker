import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_user_profile_repository.dart';
import '../../../core/services/database/database_provider.dart';

final localUserProfileRepositoryProvider = Provider<LocalUserProfileRepository>(
  (ref) {
    return LocalUserProfileRepository(ref.watch(databaseProvider));
  },
);
