import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/task_entity.dart';

part 'task_model.g.dart';

// ignore_for_file: overridden_fields
@HiveType(typeId: 0)
class TaskModel extends TaskEntity {
  @HiveField(0)
  @override
  final int id;

  @HiveField(1)
  @override
  final String title;

  @HiveField(2)
  @override
  final String priority;

  @HiveField(3)
  @override
  final String category;

  @HiveField(4)
  @override
  final DateTime dueDate;

  @HiveField(5)
  @override
  final bool isCompleted;

  @HiveField(6)
  @override
  final DateTime createdAt;

  @HiveField(7)
  @override
  final String userId;

  @HiveField(8)
  @override
  final String description;

  @HiveField(9)
  @override
  final DateTime updatedAt;

  const TaskModel({
    required this.id,
    required this.title,
    required this.priority,
    required this.category,
    required this.dueDate,
    required this.isCompleted,
    required this.createdAt,
    required this.userId,
    this.description = '',
    required this.updatedAt,
  }) : super(
         id: id,
         title: title,
         description: description,
         priority: priority,
         category: category,
         dueDate: dueDate,
         isCompleted: isCompleted,
         createdAt: createdAt,
         updatedAt: updatedAt,
         userId: userId,
       );

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 'Medium',
      category: json['category'] ?? 'Others',
      dueDate: _parseDate(json['due_date']),
      isCompleted: _parseBool(json['is_completed']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      userId: json['user_id'] ?? '',
    );
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      debugPrint('TaskModel: Error parsing date $value: $e');
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'category': category,
      'due_date': dueDate.toIso8601String(),
      'is_completed': isCompleted,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'title': title,
      'description': description,
      'priority': priority,
      'category': category,
      'due_date': dueDate.toIso8601String(),
      'is_completed': isCompleted,
    };
  }

  factory TaskModel.fromEntity(TaskEntity entity) {
    return TaskModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      priority: entity.priority,
      category: entity.category,
      dueDate: entity.dueDate,
      isCompleted: entity.isCompleted,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      userId: entity.userId,
    );
  }
}
