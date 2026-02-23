import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/task_model.dart';
import 'package:planly/core/error/exceptions.dart';

abstract class TaskRemoteDataSource {
  Future<List<TaskModel>> fetchTasks(
    String uid, {
    int skip = 0,
    int limit = 10,
  });
  Future<TaskModel> addTask(TaskModel task, String uid);
  Future<TaskModel> updateTask(TaskModel task, String uid);
  Future<void> deleteTask(int taskId, String uid);
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final Dio dio;
  final String baseUrl;

  TaskRemoteDataSourceImpl({required this.dio, required this.baseUrl}) {
    dio.options.baseUrl = baseUrl;
  }

  @override
  Future<List<TaskModel>> fetchTasks(
    String uid, {
    int skip = 0,
    int limit = 10,
  }) async {
    final queryParams = {'user_id': uid, 'skip': skip, 'limit': limit};
    debugPrint('TaskRemoteDataSource: GET /tasks/ with $queryParams');
    try {
      final response = await dio.get('/tasks/', queryParameters: queryParams);

      debugPrint('TaskRemoteDataSource: URL ${response.realUri}');
      debugPrint('TaskRemoteDataSource: Status ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic rawData = response.data;
        debugPrint('TaskRemoteDataSource: Raw response: $rawData');

        if (rawData is Map && rawData['status'] == 'success') {
          final data = rawData['data'];
          if (data is List) {
            debugPrint(
              'TaskRemoteDataSource: Found ${data.length} tasks in data array',
            );
            return data.map((task) => TaskModel.fromJson(task)).toList();
          } else if (data == null) {
            debugPrint(
              'TaskRemoteDataSource: data field is null, returning empty list',
            );
            return [];
          } else {
            throw ServerException('Data field is not a list', 'format_error');
          }
        } else {
          final message =
              (rawData is Map)
                  ? rawData['message']
                  : 'API returned success status but unexpected format';
          debugPrint('TaskRemoteDataSource: API Error Message: $message');
          throw ServerException(
            message?.toString() ?? 'Failed to fetch tasks',
            'api_error',
          );
        }
      } else {
        debugPrint(
          'TaskRemoteDataSource: Non-200 status code: ${response.statusCode}',
        );
        debugPrint(
          'TaskRemoteDataSource: API Error Response: ${response.data}',
        );
        throw ServerException(
          'Failed to fetch tasks',
          response.statusCode.toString(),
        );
      }
    } catch (e) {
      debugPrint('TaskRemoteDataSource: Critical Error in fetchTasks: $e');
      if (e is ServerException) rethrow;
      throw ServerException(e.toString(), 'network_error');
    }
  }

  @override
  Future<TaskModel> addTask(TaskModel task, String uid) async {
    final queryParams = {'user_id': uid};
    final payload = task.toCreateJson();
    debugPrint('TaskRemoteDataSource: POST /tasks/ with $queryParams');
    debugPrint('TaskRemoteDataSource: Payload: $payload');
    try {
      final response = await dio.post(
        '/tasks/',
        queryParameters: queryParams,
        data: payload,
      );

      debugPrint('TaskRemoteDataSource: Status ${response.statusCode}');
      debugPrint('TaskRemoteDataSource: Response ${response.data}');
      debugPrint('TaskRemoteDataSource: Raw add response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic rawData = response.data;
        if (rawData is Map && rawData['status'] == 'success') {
          return TaskModel.fromJson(rawData['data']);
        } else {
          final message =
              (rawData is Map)
                  ? rawData['message']
                  : 'Unexpected response format';
          throw ServerException(
            message?.toString() ?? 'Failed to add task',
            'api_error',
          );
        }
      } else {
        debugPrint(
          'TaskRemoteDataSource: Non-200/201 status code: ${response.statusCode}',
        );
        debugPrint(
          'TaskRemoteDataSource: API Error Response: ${response.data}',
        );
        throw ServerException(
          'Failed to add task',
          response.statusCode.toString(),
        );
      }
    } catch (e) {
      debugPrint('TaskRemoteDataSource: Error in addTask: $e');
      if (e is ServerException) rethrow;
      throw ServerException(e.toString(), 'network_error');
    }
  }

  @override
  Future<TaskModel> updateTask(TaskModel task, String uid) async {
    final queryParams = {'user_id': uid};
    final payload = task.toCreateJson();
    debugPrint('TaskRemoteDataSource: PUT /tasks/${task.id} with $queryParams');
    debugPrint('TaskRemoteDataSource: Payload: $payload');
    try {
      final response = await dio.put(
        '/tasks/${task.id}',
        queryParameters: queryParams,
        data: payload,
      );

      debugPrint('TaskRemoteDataSource: Status ${response.statusCode}');
      debugPrint('TaskRemoteDataSource: Response ${response.data}');

      if (response.statusCode == 200) {
        final dynamic rawData = response.data;
        debugPrint('TaskRemoteDataSource: Raw update response: $rawData');
        if (rawData is Map && rawData['status'] == 'success') {
          return TaskModel.fromJson(rawData['data']);
        } else {
          final message =
              (rawData is Map)
                  ? rawData['message']
                  : 'Unexpected response format';
          throw ServerException(
            message?.toString() ?? 'Failed to update task',
            'api_error',
          );
        }
      } else {
        debugPrint(
          'TaskRemoteDataSource: Non-200 status code: ${response.statusCode}',
        );
        debugPrint(
          'TaskRemoteDataSource: API Error Response: ${response.data}',
        );
        throw ServerException(
          'Failed to update task',
          response.statusCode.toString(),
        );
      }
    } catch (e) {
      debugPrint('TaskRemoteDataSource: Error in updateTask: $e');
      if (e is ServerException) rethrow;
      throw ServerException(e.toString(), 'network_error');
    }
  }

  @override
  Future<void> deleteTask(int taskId, String uid) async {
    final queryParams = {'user_id': uid};
    debugPrint('TaskRemoteDataSource: DELETE /tasks/$taskId with $queryParams');
    try {
      final response = await dio.delete(
        '/tasks/$taskId',
        queryParameters: queryParams,
      );

      debugPrint('TaskRemoteDataSource: Status ${response.statusCode}');
      debugPrint('TaskRemoteDataSource: Response ${response.data}');

      if (response.statusCode == 200) {
        final dynamic rawData = response.data;
        if (rawData is Map && rawData['status'] != 'success') {
          final message = rawData['message'];
          throw ServerException(
            message?.toString() ?? 'Failed to delete task',
            'api_error',
          );
        }
      } else {
        throw ServerException(
          'Failed to delete task',
          response.statusCode.toString(),
        );
      }
    } catch (e) {
      debugPrint('TaskRemoteDataSource: Error in deleteTask: $e');
      if (e is ServerException) rethrow;
      throw ServerException(e.toString(), 'network_error');
    }
  }
}
