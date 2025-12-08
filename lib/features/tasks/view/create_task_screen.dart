import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_text_field.dart';
import 'package:sline_app/core/widgets/glass_container.dart';
import 'package:sline_app/features/categories/data/categories_repository.dart';
import 'package:sline_app/features/categories/models/category_model.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:sline_app/features/tasks/viewmodels/task_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateTaskScreen extends StatefulWidget {
  final Task? task; // optional task for edit mode
  const CreateTaskScreen({super.key, this.task});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  int _currentStep = 1;
  
  // Form State
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController(); // Comma separated
  final _budgetController = TextEditingController();
  
  // Booking Packages State (Visual placeholders for now)
  int _selectedPackageTier = 0; // 0: Basic, 1: Standard, 2: Premium
  final _packagePriceController = TextEditingController();
  final _packageDeliveryController = TextEditingController();
  final _packageRevisionsController = TextEditingController();
  final _packageDescriptionController = TextEditingController();

  // Selection State
  TaskType _selectedTaskType = TaskType.tender;
  String? _selectedCategoryId;
  DateTime? _selectedDeadline;
  
  // Data
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
      _selectedTaskType = widget.task!.taskType;
      // Tags not in model yet, ignoring
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _categoriesLoading = true);
    try {
      final repo = CategoriesRepository(Supabase.instance.client);
      final cats = await repo.getAll();
      setState(() {
        _categories = cats;
      });
    } catch (e) {
      // Fallback
      setState(() {
        _categories = [];
      });
    } finally {
      setState(() => _categoriesLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _budgetController.dispose();
    _packagePriceController.dispose();
    _packageDeliveryController.dispose();
    _packageRevisionsController.dispose();
    _packageDescriptionController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submit() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in title and description')),
      );
      return;
    }

    final vm = context.read<TaskViewModel>();
    final userId = vm.currentUserId;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      // Use package price if booking, else budget
      double budget = double.tryParse(_budgetController.text) ?? 0;
      
      Map<String, dynamic>? packages;
      if (_selectedTaskType == TaskType.booking) {
        // Construct Packages Map (Simplified for single selected tier for now, or map all if UI supported it)
        // Assuming we are editing the currently selected tier in the UI
        final currentTierName = ['Basic', 'Standard', 'Premium'][_selectedPackageTier];
        
        // In a real wizard, you'd probably have state for all 3 tiers. 
        // For this prototype, we'll just save the one being edited as the "Basic" one or similar logic, 
        // OR we assume the user fills out one package.
        // Let's construct a simple map with the current data.
        packages = {
          currentTierName: {
            'price': _packagePriceController.text,
            'delivery': _packageDeliveryController.text,
            'revisions': _packageRevisionsController.text,
            'description': _packageDescriptionController.text,
          }
        };
        
        // Also update main budget display to match the package price
        budget = double.tryParse(_packagePriceController.text) ?? 0;
      }

      final task = Task(
        id: widget.task?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        budget: budget,
        userId: userId,
        status: TaskStatus.open,
        taskType: _selectedTaskType,
        createdAt: DateTime.now(),
        deadline: _selectedDeadline,
        categoryId: _selectedCategoryId,
        category: null,
        skills: _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        packages: packages,
      );

      if (widget.task == null) {
        await vm.createTask(task);
      } else {
        final updateData = task.toJson();
        // Ensure packages are included in update if present
        if (packages != null) {
          updateData['packages'] = packages;
        }
        await vm.updateTask(task.id, updateData);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.phoneBackground,
      body: SafeArea(
        child: Column(
          children: [
            // --- Header ---
            _buildHeader(colorScheme),

            // --- Content ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimens.p24),
                child: _buildStepContent(colorScheme),
              ),
            ),

            // --- Bottom Bar ---
            _buildBottomBar(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.p24, vertical: AppDimens.p16),
      decoration: BoxDecoration(
        color: colorScheme.headerBackground,
        border: Border(bottom: BorderSide(color: colorScheme.headerBorder)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close, color: AppColors.teal),
              ),
              Text(
                'Create Task',
                style: AppTypography.h4.copyWith(color: colorScheme.text),
              ),
              const SizedBox(width: 24), // Balance spacing
            ],
          ),
          const SizedBox(height: AppDimens.p16),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.r4),
            child: LinearProgressIndicator(
              value: _currentStep / 3,
              backgroundColor: AppColors.teal.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(AppColors.teal),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: AppDimens.p8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepLabel('Concept', 1, colorScheme),
              _buildStepLabel('Details', 2, colorScheme),
              _buildStepLabel('Logistics', 3, colorScheme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepLabel(String label, int step, AppColorScheme colorScheme) {
    final isActive = _currentStep >= step;
    return Text(
      label,
      style: AppTypography.captionBold.copyWith(
        color: isActive ? AppColors.teal : colorScheme.textSecondary,
      ),
    );
  }

  Widget _buildStepContent(AppColorScheme colorScheme) {
    switch (_currentStep) {
      case 1:
        return _buildStep1(colorScheme);
      case 2:
        return _buildStep2(colorScheme);
      case 3:
        return _buildStep3(colorScheme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLabeledInput(String label, Widget input, AppColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.captionBold.copyWith(color: colorScheme.text)),
        const SizedBox(height: AppDimens.p8),
        input,
      ],
    );
  }

  // --- Step 1: Concept ---
  Widget _buildStep1(AppColorScheme colorScheme) {
    // Popular categories with emojis for fallback
    final popularCategories = [
      {'icon': '🎨', 'name': 'Design', 'color': AppColors.lightRed},
      {'icon': '💻', 'name': 'Development', 'color': AppColors.lightTeal},
      {'icon': '✍️', 'name': 'Writing', 'color': const Color(0xFFF7D69C)},
      {'icon': '📱', 'name': 'Mobile', 'color': AppColors.gold},
      {'icon': '🎯', 'name': 'Marketing', 'color': AppColors.mediumGreyBlue},
      {'icon': '🎬', 'name': 'Video', 'color': AppColors.teal},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Task Type', style: AppTypography.h5.copyWith(color: colorScheme.text)),
        const SizedBox(height: AppDimens.p12),
        Row(
          children: [
            Expanded(
              child: _buildTypeCard(
                emoji: '📋',
                label: 'Tender',
                subLabel: 'Open proposals',
                type: TaskType.tender,
                colorScheme: colorScheme,
                color: AppColors.lightRed,
              ),
            ),
            const SizedBox(width: AppDimens.p12),
            Expanded(
              child: _buildTypeCard(
                emoji: '📅',
                label: 'Booking',
                subLabel: 'Direct hire',
                type: TaskType.booking,
                colorScheme: colorScheme,
                color: AppColors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.p24),
        Text('Choose Category', style: AppTypography.h5.copyWith(color: colorScheme.text)),
        const SizedBox(height: AppDimens.p12),
        _categoriesLoading
            ? const Center(child: CircularProgressIndicator())
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: AppDimens.p10,
                  mainAxisSpacing: AppDimens.p10,
                  childAspectRatio: 1.0,
                ),
                itemCount: _categories.isNotEmpty ? _categories.length : popularCategories.length,
                itemBuilder: (context, index) {
                  // Use actual categories if available, otherwise fallback
                  if (_categories.isNotEmpty) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategoryId == cat.id;
                    final emoji = _getCategoryEmoji(cat.name);
                    final catColor = _getCategoryColor(cat.name);
                    
                    return _buildCategoryCard(
                      emoji: emoji,
                      name: cat.name,
                      isSelected: isSelected,
                      color: catColor,
                      colorScheme: colorScheme,
                      onTap: () => setState(() => _selectedCategoryId = cat.id),
                    );
                  } else {
                    final cat = popularCategories[index];
                    final isSelected = _selectedCategoryId == cat['name'] as String?;
                    
                    return _buildCategoryCard(
                      emoji: cat['icon'] as String,
                      name: cat['name'] as String,
                      isSelected: isSelected,
                      color: cat['color'] as Color,
                      colorScheme: colorScheme,
                      onTap: () => setState(() => _selectedCategoryId = cat['name'] as String),
                    );
                  }
                },
              ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required String emoji,
    required String name,
    required bool isSelected,
    required Color color,
    required AppColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : colorScheme.cardBackground,
          borderRadius: BorderRadius.circular(AppDimens.r16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              name,
              style: AppTypography.captionBold.copyWith(color: colorScheme.text),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryEmoji(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('design')) return '🎨';
    if (lowerName.contains('dev') || lowerName.contains('code')) return '💻';
    if (lowerName.contains('writ') || lowerName.contains('content')) return '✍️';
    if (lowerName.contains('mobile') || lowerName.contains('app')) return '📱';
    if (lowerName.contains('market') || lowerName.contains('seo')) return '🎯';
    if (lowerName.contains('video') || lowerName.contains('media')) return '🎬';
    return '📁';
  }

  Color _getCategoryColor(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('design')) return AppColors.lightRed;
    if (lowerName.contains('dev') || lowerName.contains('code')) return AppColors.lightTeal;
    if (lowerName.contains('writ') || lowerName.contains('content')) return const Color(0xFFF7D69C);
    if (lowerName.contains('mobile') || lowerName.contains('app')) return AppColors.gold;
    if (lowerName.contains('market') || lowerName.contains('seo')) return AppColors.mediumGreyBlue;
    if (lowerName.contains('video') || lowerName.contains('media')) return AppColors.teal;
    return AppColors.teal;
  }

  Widget _buildTypeCard({
    required String emoji,
    required String label,
    required String subLabel,
    required TaskType type,
    required AppColorScheme colorScheme,
    required Color color,
  }) {
    final isSelected = _selectedTaskType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedTaskType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 100,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : colorScheme.cardBackground,
          borderRadius: BorderRadius.circular(AppDimens.r18),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : colorScheme.text,
              ),
            ),
            Text(
              subLabel,
              style: AppTypography.micro.copyWith(color: colorScheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 2: Details ---
  Widget _buildStep2(AppColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabeledInput(
          'Title',
          AppTextField(
            hintText: 'e.g., Modern Logo Design',
            controller: _titleController,
          ),
          colorScheme,
        ),
        const SizedBox(height: AppDimens.p16),
        _buildLabeledInput(
          'Description',
          AppTextField(
            hintText: 'Describe your project...',
            controller: _descriptionController,
            maxLines: 5,
          ),
          colorScheme,
        ),
        const SizedBox(height: AppDimens.p16),
        _buildLabeledInput(
          'Tags',
          AppTextField(
            hintText: 'e.g., Design, Logo (comma separated)',
            controller: _tagsController,
          ),
          colorScheme,
        ),
      ],
    );
  }

  // --- Step 3: Logistics ---
  Widget _buildStep3(AppColorScheme colorScheme) {
    if (_selectedTaskType == TaskType.booking) {
      return _buildBookingLogistics(colorScheme);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabeledInput(
          'Budget (IQD)',
          AppTextField(
            hintText: 'Enter amount',
            controller: _budgetController,
            keyboardType: TextInputType.number,
          ),
          colorScheme,
        ),
        const SizedBox(height: AppDimens.p16),
        Text('Deadline', style: AppTypography.captionBold.copyWith(color: colorScheme.text)),
        const SizedBox(height: AppDimens.p8),
        // Simple Deadline Chips
        Row(
          children: [3, 7, 14, 30].map((days) {
            final date = DateTime.now().add(Duration(days: days));
            final isSelected = _selectedDeadline != null && 
                               _selectedDeadline!.difference(DateTime.now()).inDays + 1 == days; // approx check
            
            return Padding(
              padding: const EdgeInsets.only(right: AppDimens.p8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedDeadline = date),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimens.p12, vertical: AppDimens.p10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.teal.withValues(alpha: 0.1) : colorScheme.cardBackground,
                    borderRadius: BorderRadius.circular(AppDimens.r12),
                    border: Border.all(
                      color: isSelected ? AppColors.teal : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    days == 7 ? '1 Week' : days == 14 ? '2 Weeks' : days == 30 ? '1 Month' : '$days Days',
                    style: AppTypography.captionBold.copyWith(
                      color: isSelected ? AppColors.teal : colorScheme.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBookingLogistics(AppColorScheme colorScheme) {
    // Tab selector for packages
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colorScheme.inputBackground,
            borderRadius: BorderRadius.circular(AppDimens.r14),
            border: Border.all(color: colorScheme.inputBorder),
          ),
          child: Row(
            children: ['Basic', 'Standard', 'Premium'].asMap().entries.map((entry) {
              final index = entry.key;
              final label = entry.value;
              final isSelected = _selectedPackageTier == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPackageTier = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: AppDimens.p10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.teal : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppDimens.r10),
                      boxShadow: isSelected
                          ? [BoxShadow(color: AppColors.teal.withValues(alpha: 0.3), blurRadius: 8)]
                          : [],
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: AppTypography.captionBold.copyWith(
                        color: isSelected ? Colors.white : colorScheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppDimens.p16),
        // Package Fields
        Row(
          children: [
            Expanded(
              child: _buildLabeledInput(
                'Price (\$)',
                AppTextField(
                  hintText: '0',
                  controller: _packagePriceController, // Note: Shared controller for now (simplified)
                  keyboardType: TextInputType.number,
                ),
                colorScheme,
              ),
            ),
            const SizedBox(width: AppDimens.p12),
            Expanded(
              child: _buildLabeledInput(
                'Delivery (Days)',
                AppTextField(
                  hintText: '1',
                  controller: _packageDeliveryController,
                  keyboardType: TextInputType.number,
                ),
                colorScheme,
              ),
            ),
            const SizedBox(width: AppDimens.p12),
            Expanded(
              child: _buildLabeledInput(
                'Revisions',
                AppTextField(
                  hintText: '1',
                  controller: _packageRevisionsController,
                ),
                colorScheme,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.p16),
        _buildLabeledInput(
          'Package Description',
          AppTextField(
            hintText: 'What is included?',
            controller: _packageDescriptionController,
            maxLines: 3,
          ),
          colorScheme,
        ),
      ],
    );
  }

  Widget _buildBottomBar(AppColorScheme colorScheme) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppDimens.p24),
      borderRadius: BorderRadius.zero, // Stick to bottom
      child: Row(
        children: [
          if (_currentStep > 1)
            Padding(
              padding: const EdgeInsets.only(right: AppDimens.p12),
              child: GestureDetector(
                onTap: _prevStep,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colorScheme.cardBackground,
                    borderRadius: BorderRadius.circular(AppDimens.r14),
                    border: Border.all(color: colorScheme.cardBorder),
                  ),
                  child: Icon(Icons.chevron_left, color: colorScheme.text),
                ),
              ),
            ),
          Expanded(
            child: AppButton(
              text: _currentStep == 3 ? 'Create Task' : 'Next Step',
              onPressed: _isLoading ? null : _nextStep,
              isLoading: _isLoading,
              icon: _currentStep < 3 ? Icons.chevron_right : null,
            ),
          ),
        ],
      ),
    );
  }
}