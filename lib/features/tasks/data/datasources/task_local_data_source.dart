import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_model.dart';

abstract class TaskLocalDataSource {
  Future<List<TaskModel>> getLastTasks();
  Future<void> cacheTasks(List<TaskModel> tasksToCache);
  Future<void> cacheTask(TaskModel task);
  Future<void> deleteTask(int taskId);
  Future<void> clearCache();

  // Pending Actions for Offline Sync
  Future<void> addPendingAction(int taskId, String action, {TaskModel? task});
  Future<List<Map<String, dynamic>>> getPendingActions();
  Future<void> deletePendingAction(int taskId);
  Future<void> clearPendingActions();
}

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  final Box<TaskModel> taskBox;
  final Box<Map> pendingActionsBox;

  TaskLocalDataSourceImpl({
    required this.taskBox,
    required this.pendingActionsBox,
  });

  @override
  Future<List<TaskModel>> getLastTasks() async {
    return taskBox.values.toList();
  }

  @override
  Future<void> cacheTasks(List<TaskModel> tasksToCache) async {
    final Map<String, TaskModel> taskMap = {
      for (var task in tasksToCache) task.id.toString(): task,
    };
    await taskBox.putAll(taskMap);
  }

  @override
  Future<void> cacheTask(TaskModel task) async {
    await taskBox.put(task.id.toString(), task);
  }

  @override
  Future<void> deleteTask(int taskId) async {
    await taskBox.delete(taskId.toString());
  }

  @override
  Future<void> clearCache() async {
    await taskBox.clear();
  }

  @override
  Future<void> addPendingAction(
    int taskId,
    String action, {
    TaskModel? task,
  }) async {
    await pendingActionsBox.put(taskId.toString(), {
      'id': taskId,
      'action': action,
      'task': task?.toJson(),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingActions() async {
    final actions =
        pendingActionsBox.values
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
    // Sort by timestamp to ensure correct order
    actions.sort(
      (a, b) => (a['timestamp'] as String).compareTo(b['timestamp']),
    );
    return actions;
  }

  @override
  Future<void> deletePendingAction(int taskId) async {
    await pendingActionsBox.delete(taskId.toString());
  }

  @override
  Future<void> clearPendingActions() async {
    await pendingActionsBox.clear();
  }
}
