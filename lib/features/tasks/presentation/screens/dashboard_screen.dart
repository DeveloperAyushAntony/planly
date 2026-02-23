import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:planly/features/auth/presentation/providers/auth_provider.dart';
import 'package:planly/features/profile/presentation/providers/profile_provider.dart';
import 'package:planly/features/profile/presentation/screens/profile_screen.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import 'add_task_screen.dart';
import 'edit_task_screen.dart';
import 'package:planly/features/tasks/domain/repositories/task_repository.dart';
import 'package:planly/core/di/injection_container.dart' as di;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Connectivity listener for auto-sync
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      debugPrint('Dashboard: Connectivity changed to $results');
      if (!mounted) return;
      if (!results.contains(ConnectivityResult.none)) {
        final uid = context.read<AuthProvider>().user?.id;
        if (uid != null) {
          debugPrint('Dashboard: Triggering sync for user $uid');
          di.sl<TaskRepository>().syncTasks(uid).then((_) {
            if (mounted) {
              context.read<TaskProvider>().fetchTasks(uid, isRefresh: true);
            }
          });
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      debugPrint('Dashboard: authProvider.user is ${authProvider.user?.id}');
      if (authProvider.user != null) {
        context.read<TaskProvider>().fetchTasks(
          authProvider.user!.id,
          isRefresh: true,
        );
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final authProvider = context.read<AuthProvider>();
      final taskProvider = context.read<TaskProvider>();
      if (authProvider.user != null &&
          taskProvider.status != TaskStatus.loading &&
          !taskProvider.hasReachedMax) {
        taskProvider.fetchTasks(authProvider.user!.id, isRefresh: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-fetch tasks if provider status is initial (e.g. after hot reload)
    final taskProvider = context.read<TaskProvider>();
    if (taskProvider.status == TaskStatus.initial) {
      final uid = context.read<AuthProvider>().user?.id;
      if (uid != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && taskProvider.status == TaskStatus.initial) {
            taskProvider.fetchTasks(uid, isRefresh: true);
          }
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planly'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh tasks',
            onPressed: () {
              final uid = context.read<AuthProvider>().user?.id;
              if (uid != null) {
                context.read<TaskProvider>().fetchTasks(uid, isRefresh: true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<ProfileProvider>().clearProfile();
              context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                if (taskProvider.status == TaskStatus.loading &&
                    taskProvider.tasks.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (taskProvider.status == TaskStatus.error &&
                    taskProvider.tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(taskProvider.errorMessage ?? 'An error occurred'),
                        ElevatedButton(
                          onPressed: () {
                            final uid = context.read<AuthProvider>().user?.id;
                            if (uid != null) {
                              taskProvider.fetchTasks(uid, isRefresh: true);
                            }
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final tasks = taskProvider.filteredTasks;
                return RefreshIndicator(
                  onRefresh: () async {
                    final uid = context.read<AuthProvider>().user?.id;
                    if (uid != null) {
                      await taskProvider.fetchTasks(uid, isRefresh: true);
                    }
                  },
                  child:
                      tasks.isEmpty
                          ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.6,
                                child: const Center(
                                  child: Text(
                                    'No tasks found. Tap + to add one!',
                                  ),
                                ),
                              ),
                            ],
                          )
                          : ListView.builder(
                            controller: _scrollController,
                            itemCount:
                                taskProvider.hasReachedMax
                                    ? tasks.length
                                    : tasks.length + 1,
                            itemBuilder: (context, index) {
                              if (index < tasks.length) {
                                final task = tasks[index];
                                return TaskCard(
                                  task: task,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => EditTaskScreen(task: task),
                                      ),
                                    );
                                  },
                                  onStatusChanged: (val) {
                                    final uid =
                                        context.read<AuthProvider>().user?.id;
                                    if (uid != null) {
                                      taskProvider.updateTask(
                                        task.copyWith(
                                          isCompleted: val ?? false,
                                        ),
                                        uid,
                                      );
                                    }
                                  },
                                  onDelete: () {
                                    final uid =
                                        context.read<AuthProvider>().user?.id;
                                    if (uid != null) {
                                      taskProvider.deleteTask(task.id, uid);
                                    }
                                  },
                                );
                              }
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                          ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search tasks...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (val) => context.read<TaskProvider>().setSearchQuery(val),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All'),
                selected: taskProvider.filter == 'All',
                onSelected: (val) => taskProvider.setFilter('All'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Completed'),
                selected: taskProvider.filter == 'Completed',
                onSelected: (val) => taskProvider.setFilter('Completed'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Pending'),
                selected: taskProvider.filter == 'Pending',
                onSelected: (val) => taskProvider.setFilter('Pending'),
              ),
              const VerticalDivider(),
              DropdownButton<String>(
                value: taskProvider.sortBy,
                items:
                    ['Due Date', 'Priority', 'Created Date'].map((
                      String value,
                    ) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    taskProvider.setSortBy(val);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
