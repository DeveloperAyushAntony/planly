import 'package:flutter/foundation.dart';
import 'package:planly/core/usecases/usecase.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class FetchTasksUseCase implements UseCase<List<TaskEntity>, FetchTasksParams> {
  final TaskRepository repository;

  FetchTasksUseCase(this.repository);

  @override
  Future<List<TaskEntity>> call(FetchTasksParams params) {
    debugPrint(
      'FetchTasksUseCase: calling with uid=${params.uid}, skip=${params.skip}',
    );
    return repository.fetchTasks(
      uid: params.uid,
      skip: params.skip,
      limit: params.limit,
    );
  }
}

class FetchTasksParams {
  final String uid;
  final int skip;
  final int limit;

  FetchTasksParams({required this.uid, this.skip = 0, this.limit = 10});
}

class AddTaskUseCase implements UseCase<TaskEntity, AddTaskParams> {
  final TaskRepository repository;

  AddTaskUseCase(this.repository);

  @override
  Future<TaskEntity> call(AddTaskParams params) {
    return repository.addTask(params.task, params.uid);
  }
}

class AddTaskParams {
  final TaskEntity task;
  final String uid;

  AddTaskParams({required this.task, required this.uid});
}

class UpdateTaskUseCase implements UseCase<TaskEntity, UpdateTaskParams> {
  final TaskRepository repository;

  UpdateTaskUseCase(this.repository);

  @override
  Future<TaskEntity> call(UpdateTaskParams params) {
    return repository.updateTask(params.task, params.uid);
  }
}

class UpdateTaskParams {
  final TaskEntity task;
  final String uid;

  UpdateTaskParams({required this.task, required this.uid});
}

class DeleteTaskUseCase implements UseCase<void, DeleteTaskParams> {
  final TaskRepository repository;

  DeleteTaskUseCase(this.repository);

  @override
  Future<void> call(DeleteTaskParams params) {
    return repository.deleteTask(params.taskId, params.uid);
  }
}

class DeleteTaskParams {
  final int taskId;
  final String uid;

  DeleteTaskParams({required this.taskId, required this.uid});
}

class SyncTasksUseCase implements UseCase<void, String> {
  final TaskRepository repository;

  SyncTasksUseCase(this.repository);

  @override
  Future<void> call(String uid) {
    return repository.syncTasks(uid);
  }
}
