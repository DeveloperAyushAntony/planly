import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:planly/core/error/exceptions.dart';
import 'package:planly/features/auth/domain/repositories/auth_repository.dart';
import '../datasources/task_local_data_source.dart';
import '../datasources/task_remote_data_source.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource remoteDataSource;
  final TaskLocalDataSource localDataSource;
  final Connectivity connectivity;
  final AuthRepository authRepository;

  TaskRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.connectivity,
    required this.authRepository,
  });

  @override
  Future<List<TaskEntity>> fetchTasks({
    required String uid,
    int skip = 0,
    int limit = 10,
  }) async {
    final connectivityResult = await connectivity.checkConnectivity();
    if (!connectivityResult.contains(ConnectivityResult.none)) {
      try {
        debugPrint('TaskRepository: Fetching remote tasks for $uid');
        final remoteTasks = await remoteDataSource.fetchTasks(
          uid,
          skip: skip,
          limit: limit,
        );
        debugPrint(
          'TaskRepository: Successfully fetched ${remoteTasks.length} remote tasks',
        );
        if (skip == 0) {
          await localDataSource.clearCache();
        }
        await localDataSource.cacheTasks(remoteTasks);
        return remoteTasks;
      } on ServerException catch (e) {
        debugPrint(
          'TaskRepository: Remote fetch failed ($e), falling back to local',
        );
        return await localDataSource.getLastTasks();
      }
    } else {
      return await localDataSource.getLastTasks();
    }
  }

  @override
  Future<TaskEntity> addTask(TaskEntity task, String uid) async {
    final taskModel = TaskModel.fromEntity(task);
    final connectivityResult = await connectivity.checkConnectivity();

    if (!connectivityResult.contains(ConnectivityResult.none)) {
      try {
        final remoteTask = await remoteDataSource.addTask(taskModel, uid);
        await localDataSource.cacheTask(remoteTask);
        return remoteTask;
      } on ServerException {
        await localDataSource.cacheTask(taskModel);
        await localDataSource.addPendingAction(
          taskModel.id,
          'ADD',
          task: taskModel,
        );
        return taskModel;
      }
    } else {
      await localDataSource.cacheTask(taskModel);
      await localDataSource.addPendingAction(
        taskModel.id,
        'ADD',
        task: taskModel,
      );
      return taskModel;
    }
  }

  @override
  Future<TaskEntity> updateTask(TaskEntity task, String uid) async {
    final taskModel = TaskModel.fromEntity(task);
    final connectivityResult = await connectivity.checkConnectivity();

    if (!connectivityResult.contains(ConnectivityResult.none)) {
      try {
        final remoteTask = await remoteDataSource.updateTask(taskModel, uid);
        await localDataSource.cacheTask(remoteTask);
        return remoteTask;
      } on ServerException {
        await localDataSource.cacheTask(taskModel);
        await localDataSource.addPendingAction(
          taskModel.id,
          'UPDATE',
          task: taskModel,
        );
        return taskModel;
      }
    } else {
      await localDataSource.cacheTask(taskModel);
      await localDataSource.addPendingAction(
        taskModel.id,
        'UPDATE',
        task: taskModel,
      );
      return taskModel;
    }
  }

  @override
  Future<void> deleteTask(int taskId, String uid) async {
    final connectivityResult = await connectivity.checkConnectivity();

    if (!connectivityResult.contains(ConnectivityResult.none)) {
      try {
        await remoteDataSource.deleteTask(taskId, uid);
        await localDataSource.deleteTask(taskId);
      } on ServerException {
        await localDataSource.deleteTask(taskId);
        await localDataSource.addPendingAction(taskId, 'DELETE');
      }
    } else {
      await localDataSource.deleteTask(taskId);
      await localDataSource.addPendingAction(taskId, 'DELETE');
    }
  }

  @override
  Future<void> syncTasks(String uid) async {
    debugPrint('TaskRepository: Starting sync for user $uid');
    final connectivityResult = await connectivity.checkConnectivity();
    if (!connectivityResult.contains(ConnectivityResult.none)) {
      try {
        // 1. Process pending actions
        final pendingActions = await localDataSource.getPendingActions();
        debugPrint(
          'TaskRepository: Found ${pendingActions.length} pending actions to sync',
        );

        int successCount = 0;
        for (final action in pendingActions) {
          try {
            final int taskId = action['id'];
            final String actionType = action['action'];
            final Map<String, dynamic>? taskJson = action['task'];

            debugPrint('TaskRepository: Syncing $actionType for task $taskId');

            if (actionType == 'ADD') {
              final remoteTask = await remoteDataSource.addTask(
                TaskModel.fromJson(taskJson!),
                uid,
              );
              if (remoteTask.id != taskId) {
                await localDataSource.deleteTask(taskId);
                await localDataSource.cacheTask(remoteTask);
              }
            } else if (actionType == 'UPDATE') {
              await remoteDataSource.updateTask(
                TaskModel.fromJson(taskJson!),
                uid,
              );
            } else if (actionType == 'DELETE') {
              await remoteDataSource.deleteTask(taskId, uid);
            }

            await localDataSource.deletePendingAction(taskId);
            successCount++;
          } catch (e) {
            debugPrint('TaskRepository: Failed to sync individual action: $e');
          }
        }
        debugPrint(
          'TaskRepository: Successfully synced $successCount/${pendingActions.length} actions',
        );

        // 2. Fetch latest tasks
        debugPrint(
          'TaskRepository: Fetching latest tasks for cache after sync',
        );
        final remoteTasks = await remoteDataSource.fetchTasks(
          uid,
          skip: 0,
          limit: 100,
        );
        await localDataSource.clearCache();
        await localDataSource.cacheTasks(remoteTasks);
        debugPrint(
          'TaskRepository: Local cache updated with ${remoteTasks.length} tasks',
        );
      } catch (e) {
        debugPrint('TaskRepository: Critical error during syncTasks: $e');
      }
    } else {
      debugPrint('TaskRepository: Sync skipped - no connectivity');
    }
  }
}
