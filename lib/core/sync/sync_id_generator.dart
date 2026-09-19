import 'package:uuid/uuid.dart';

class SyncIdGenerator {
  const SyncIdGenerator();

  String generate() {
    return const Uuid().v4();
  }
}
