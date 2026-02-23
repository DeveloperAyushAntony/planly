import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:planly/features/auth/presentation/providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../../domain/entities/task_entity.dart';

class EditTaskScreen extends StatefulWidget {
  final TaskEntity task;

  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  late String _priority;
  late DateTime _dueDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(
      text: widget.task.description,
    );
    final allowedCategories = [
      'Work',
      'Personal',
      'Health',
      'Finance',
      'Education',
      'Shopping',
      'Travel',
      'Others',
    ];
    String initialCategory = widget.task.category;
    if (!allowedCategories.contains(initialCategory)) {
      initialCategory = 'Others';
    }
    _categoryController = TextEditingController(text: initialCategory);
    _priority = widget.task.priority;
    _dueDate = widget.task.dueDate;
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

      final updatedTask = widget.task.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _priority,
        category: _categoryController.text.trim(),
        dueDate: _dueDate,
        isCompleted: widget.task.isCompleted,
        updatedAt: DateTime.now(),
      );

      context.read<TaskProvider>().updateTask(
        updatedTask,
        authProvider.user!.id,
      );
      Navigator.pop(context);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
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
      appBar: AppBar(title: const Text('Edit Task')),
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
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
