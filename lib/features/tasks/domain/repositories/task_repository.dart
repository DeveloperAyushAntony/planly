import '../entities/task_entity.dart';

abstract class TaskRepository {
  Future<List<TaskEntity>> fetchTasks({
    required String uid,
    int skip = 0,
    int limit = 10,
  });
  Future<TaskEntity> addTask(TaskEntity task, String uid);
  Future<TaskEntity> updateTask(TaskEntity task, String uid);
  Future<void> deleteTask(int taskId, String uid);
  Future<void> syncTasks(String uid);
}
