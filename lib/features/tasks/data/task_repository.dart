import 'package:drift/drift.dart';

import '../../../core/services/database/app_database.dart';

class TaskRepository {
  final AppDatabase database;

  TaskRepository(this.database);

  Future<List<Task>> getTasks() {
    return (database.select(database.tasks)
          ..where((task) => task.archived.equals(false))
          ..orderBy([
            (task) => OrderingTerm(
              expression: task.createdAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .get();
  }

  Future<int> createTask({required String name, String? description}) {
    return database
        .into(database.tasks)
        .insert(
          TasksCompanion.insert(
            name: name,
            description: Value(description),
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<void> archiveTask(int id) {
    return (database.update(database.tasks)
          ..where((task) => task.id.equals(id)))
        .write(const TasksCompanion(archived: Value(true)));
  }
}
