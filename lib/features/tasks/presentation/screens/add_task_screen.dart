import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:planly/features/auth/presentation/providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../../domain/entities/task_entity.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController(text: 'Others');
  String _priority = 'Medium';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  bool _wasLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().resetStatus();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user == null) return;

      final now = DateTime.now();
      final task = TaskEntity(
        id: now.millisecondsSinceEpoch,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _priority,
        category: _categoryController.text.trim(),
        dueDate: _dueDate,
        createdAt: now,
        updatedAt: now,
        userId: authProvider.user!.id,
      );

      context.read<TaskProvider>().addTask(task, authProvider.user!.id);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Task')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter a title'
                            : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value:
                    [
                          'Work',
                          'Personal',
                          'Health',
                          'Finance',
                          'Education',
                          'Shopping',
                          'Travel',
                          'Others',
                        ].contains(_categoryController.text)
                        ? _categoryController.text
                        : 'Others',
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items:
                    [
                      'Work',
                      'Personal',
                      'Health',
                      'Finance',
                      'Education',
                      'Shopping',
                      'Travel',
                      'Others',
                    ].map((String category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                onChanged:
                    (val) => setState(() => _categoryController.text = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.priority_high),
                ),
                items:
                    ['Low', 'Medium', 'High'].map((String priority) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Text(priority),
                      );
                    }).toList(),
                onChanged: (val) => setState(() => _priority = val!),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  'Due Date: ${DateFormat('MMM d, y').format(_dueDate)}',
                ),
                leading: const Icon(Icons.calendar_today),
                trailing: const Icon(Icons.edit),
                onTap: () => _selectDate(context),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 32),
              Consumer<TaskProvider>(
                builder: (context, taskProvider, child) {
                  final isCurrentlyLoading =
                      taskProvider.status == TaskStatus.loading;

                  if (_wasLoading && taskProvider.status == TaskStatus.loaded) {
                    _wasLoading = false;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    });
                  } else if (taskProvider.status == TaskStatus.error &&
                      taskProvider.errorMessage != null) {
                    _wasLoading = false;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(taskProvider.errorMessage!),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        taskProvider.resetStatus();
                      }
                    });
                  }

                  if (isCurrentlyLoading) {
                    _wasLoading = true;
                  }

                  return ElevatedButton(
                    onPressed: isCurrentlyLoading ? null : _submit,
                    child:
                        isCurrentlyLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text('Add Task'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
