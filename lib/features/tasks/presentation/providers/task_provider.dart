import 'package:flutter/foundation.dart';
import 'package:planly/features/tasks/domain/entities/task_entity.dart';
import 'package:planly/features/tasks/domain/usecases/task_usecases.dart';

enum TaskStatus { initial, loading, loaded, error }

class TaskProvider extends ChangeNotifier {
  final FetchTasksUseCase fetchTasksUseCase;
  final AddTaskUseCase addTaskUseCase;
  final UpdateTaskUseCase updateTaskUseCase;
  final DeleteTaskUseCase deleteTaskUseCase;
  final SyncTasksUseCase syncTasksUseCase;

  TaskStatus _status = TaskStatus.initial;
  List<TaskEntity> _tasks = [];
  List<TaskEntity> _filteredTasks = [];
  bool _hasReachedMax = false;
  String? _errorMessage;
  String _filter = 'All';
  String _searchQuery = '';
  String _sortBy = 'Due Date';

  TaskProvider({
    required this.fetchTasksUseCase,
    required this.addTaskUseCase,
    required this.updateTaskUseCase,
    required this.deleteTaskUseCase,
    required this.syncTasksUseCase,
  });

  TaskStatus get status => _status;
  List<TaskEntity> get tasks => _tasks;
  List<TaskEntity> get filteredTasks => _filteredTasks;
  bool get hasReachedMax => _hasReachedMax;
  String? get errorMessage => _errorMessage;
  String get filter => _filter;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;

  Future<void> fetchTasks(String uid, {bool isRefresh = true}) async {
    debugPrint(
      'TaskProvider: fetchTasks called for $uid (isRefresh: $isRefresh)',
    );
    if (isRefresh) {
      _status = TaskStatus.loading;
      _hasReachedMax = false;
      Future.microtask(() => notifyListeners());
      try {
        await syncTasksUseCase(uid);
      } catch (e) {
        debugPrint('TaskProvider: Sync failed during refresh: $e');
      }
    }

    if (_hasReachedMax && !isRefresh) return;

    try {
      final newTasks = await fetchTasksUseCase(
        FetchTasksParams(
          uid: uid,
          skip: isRefresh ? 0 : _tasks.length,
          limit: isRefresh ? 100 : 10,
        ),
      );

      debugPrint('TaskProvider: Fetched ${newTasks.length} tasks');

      if (isRefresh) {
        // Optimistic Merge: Keep tasks that are still local-only (large timestamp IDs)
        final localOnlyTasks =
            _tasks.where((t) => t.id > 1000000000000).toList();
        _tasks = List<TaskEntity>.from(newTasks);

        for (var task in localOnlyTasks.reversed) {
          // Only add back if not already returned by server (checked by title/desc/dueDate as a heuristic)
          final exists = _tasks.any(
            (t) =>
                t.title == task.title &&
                t.description == task.description &&
                t.dueDate == task.dueDate,
          );
          if (!exists) {
            _tasks.insert(0, task);
          }
        }
      } else {
        _tasks.addAll(newTasks);
      }

      _hasReachedMax = newTasks.length < 10;
      _status = TaskStatus.loaded;
      _applyFiltersAndSort();
    } catch (e) {
      debugPrint('TaskProvider: Error in fetchTasks: $e');
      _status = TaskStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> addTask(TaskEntity task, String uid) async {
    debugPrint('TaskProvider: Adding task ${task.title} for user $uid');
    final originalTasks = List<TaskEntity>.from(_tasks);
    _status = TaskStatus.loading;
    _tasks.insert(0, task);
    _applyFiltersAndSort();

    try {
      final addedTask = await addTaskUseCase(
        AddTaskParams(task: task, uid: uid),
      );
      debugPrint('TaskProvider: Task added successfully');
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = addedTask;
      }
      _status = TaskStatus.loaded;
      _applyFiltersAndSort();
    } catch (e) {
      debugPrint('TaskProvider: Error adding task: $e');
      _tasks = originalTasks;
      _status = TaskStatus.error;
      _errorMessage = e.toString();
      _applyFiltersAndSort();
    }
  }

  Future<void> updateTask(TaskEntity task, String uid) async {
    final originalTasks = List<TaskEntity>.from(_tasks);
    _tasks = _tasks.map((t) => t.id == task.id ? task : t).toList();
    _applyFiltersAndSort();

    try {
      final updatedTask = await updateTaskUseCase(
        UpdateTaskParams(task: task, uid: uid),
      );
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
      }
      notifyListeners();
    } catch (e) {
      _tasks = originalTasks;
      _status = TaskStatus.error;
      _errorMessage = e.toString();
      _applyFiltersAndSort();
    }
  }

  Future<void> deleteTask(int taskId, String uid) async {
    final originalTasks = List<TaskEntity>.from(_tasks);
    _tasks.removeWhere((t) => t.id == taskId);
    _applyFiltersAndSort();

    try {
      await deleteTaskUseCase(DeleteTaskParams(taskId: taskId, uid: uid));
    } catch (e) {
      _tasks = originalTasks;
      _status = TaskStatus.error;
      _errorMessage = e.toString();
      _applyFiltersAndSort();
    }
  }

  void setFilter(String filter) {
    _filter = filter;
    _applyFiltersAndSort();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    List<TaskEntity> filtered = List<TaskEntity>.from(_tasks);

    // Filter
    if (_filter == 'Completed') {
      filtered = filtered.where((t) => t.isCompleted).toList();
    } else if (_filter == 'Pending') {
      filtered = filtered.where((t) => !t.isCompleted).toList();
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered
              .where(
                (t) =>
                    t.title.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    t.description.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();
    }

    // Sort
    if (_sortBy == 'Due Date') {
      filtered.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    } else if (_sortBy == 'Priority') {
      final priorityMap = {'High': 1, 'Medium': 2, 'Low': 3};
      filtered.sort((a, b) {
        final cmp = (priorityMap[a.priority] ?? 4).compareTo(
          priorityMap[b.priority] ?? 4,
        );
        if (cmp != 0) return cmp;
        return b.createdAt.compareTo(
          a.createdAt,
        ); // Secondary sort by newest first
      });
    } else if (_sortBy == 'Created Date') {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    _filteredTasks = filtered;
    notifyListeners();
  }

  void resetStatus() {
    _status = TaskStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }
}
