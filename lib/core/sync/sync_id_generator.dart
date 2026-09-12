class SyncIdGenerator {
  const SyncIdGenerator();

  String generate() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}
