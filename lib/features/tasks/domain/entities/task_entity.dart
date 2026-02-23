import 'package:equatable/equatable.dart';

class TaskEntity extends Equatable {
  final int id;
  final String title;
  final String description;
  final String priority; // Low, Medium, High
  final String category;
  final DateTime dueDate;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;

  const TaskEntity({
    required this.id,
    required this.title,
    this.description = '',
    required this.priority,
    required this.category,
    required this.dueDate,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    priority,
    category,
    dueDate,
    isCompleted,
    createdAt,
    updatedAt,
    userId,
  ];

  TaskEntity copyWith({
    String? title,
    String? description,
    String? priority,
    String? category,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? updatedAt,
  }) {
    return TaskEntity(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId,
    );
  }
}
