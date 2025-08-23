import 'package:flutter/material.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:sline_app/features/tasks/services/task_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/features/categories/models/category_model.dart';
import 'package:sline_app/features/categories/services/categories_service.dart';

class CreateTaskScreen extends StatefulWidget {
  final Task? task; // optional task for edit mode
  const CreateTaskScreen({super.key, this.task});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();

  // Selected task type: Request (tender) by default; Service = booking
  TaskType _selectedTaskType = TaskType.tender;

  DateTime? _selectedDeadline;
  String? _selectedCategoryId;
  List<CategoryModel> _categories = [];
  bool _categoriesLoading = false;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _budgetController.text = widget.task!.budget.toString();
      _selectedDeadline = widget.task!.deadline;
      _selectedCategoryId = widget.task!.categoryId;
      _selectedTaskType = widget.task!.taskType; // keep current type in edit mode
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _categoriesLoading = true);
    try {
      final svc = CategoriesService(Supabase.instance.client);
      final cats = await svc.getAll();
      setState(() {
        _categories = cats;
      });
    } catch (e) {
      // fallback: use constants if service fails
      setState(() {
        _categories = [
          CategoryModel(
            id: 'static-design',
            name: 'Design',
            iconUrl: null,
            createdAt: DateTime.now().toUtc(),
          ),
          CategoryModel(
            id: 'static-dev',
            name: 'Development',
            iconUrl: null,
            createdAt: DateTime.now().toUtc(),
          ),
          CategoryModel(
            id: 'static-writing',
            name: 'Writing',
            iconUrl: null,
            createdAt: DateTime.now().toUtc(),
          ),
          CategoryModel(
            id: 'static-marketing',
            name: 'Marketing',
            iconUrl: null,
            createdAt: DateTime.now().toUtc(),
          ),
        ];
      });
    } finally {
      setState(() => _categoriesLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.task == null) {
        // Create mode
        final task = Task(
          id: '',
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          budget: double.tryParse(_budgetController.text.trim()) ?? 0,
          userId: userId,
          status: TaskStatus.open,
          taskType: _selectedTaskType, // tender|booking
          createdAt: DateTime.now(),
          deadline: _selectedDeadline,
          categoryId: _selectedCategoryId,
          category: null, // legacy left null
          skills: const [],
        );

        await TaskService().createTask(task);
      } else {
        // Edit mode
        await TaskService().updateTask(widget.task!.id, {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'budget': double.tryParse(_budgetController.text.trim()) ?? 0,
          'deadline': _selectedDeadline?.toIso8601String(),
          'category_id': _selectedCategoryId,
          'task_type': _selectedTaskType.name, // persist type change
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.task == null
              ? 'Task published successfully!'
              : 'Task updated successfully!'),
          backgroundColor: widget.task == null ? Colors.green : Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Create Task' : 'Edit Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Task type selector: Request (tender) vs Service (booking)
              Text(
                'What are you creating?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    RadioListTile<TaskType>(
                      title: const Text('Request (Receive offers)'),
                      subtitle: const Text('Use tender: bidders will submit offers'),
                      value: TaskType.tender,
                      groupValue: _selectedTaskType,
                      onChanged: (val) =>
                          setState(() => _selectedTaskType = val!),
                    ),
                    const Divider(height: 0),
                    RadioListTile<TaskType>(
                      title: const Text('Service (Allow bookings)'),
                      subtitle:
                          const Text('Use booking: clients can schedule time'),
                      value: TaskType.booking,
                      groupValue: _selectedTaskType,
                      onChanged: (val) =>
                          setState(() => _selectedTaskType = val!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _budgetController,
                decoration: InputDecoration(
                  labelText: _selectedTaskType == TaskType.tender
                      ? 'Budget (IQD)'
                      : 'Price (IQD) — hourly/session',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  // tender: required number; booking: optional number
                  if (_selectedTaskType == TaskType.tender) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (double.tryParse(value) == null) {
                      return 'Enter a valid number';
                    }
                  } else {
                    if (value != null &&
                        value.isNotEmpty &&
                        double.tryParse(value) == null) {
                      return 'Enter a valid number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              _categoriesLoading
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      items: _categories
                          .map((cat) => DropdownMenuItem(
                                value: cat.id,
                                child: Text(cat.name),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedCategoryId = val),
                      decoration: const InputDecoration(labelText: 'Category'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(_selectedDeadline == null
                    ? 'Select Deadline'
                    : 'Deadline: ${_selectedDeadline!.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                    initialDate: _selectedDeadline ?? DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _selectedDeadline = picked);
                  }
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(widget.task == null ? 'Publish Task' : 'Update Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}