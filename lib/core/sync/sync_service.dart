abstract interface class SyncService {
  Future<void> sync();

  Future<void> syncTasks();
}
