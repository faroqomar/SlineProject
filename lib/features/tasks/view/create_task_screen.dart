import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_text_field.dart';
import 'package:sline_app/core/widgets/glass_container.dart';
import 'package:sline_app/features/categories/data/categories_repository.dart';
import 'package:sline_app/features/categories/models/category_model.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:sline_app/features/tasks/viewmodels/task_view_model.dart';

class CreateTaskScreen extends StatefulWidget {
  final Task? task; // optional task for edit mode
  const CreateTaskScreen({super.key, this.task});

  static const Key primaryActionButtonKey = ValueKey<String>(
    'create_task_primary_action',
  );
  static const Key tenderTypeCardKey = ValueKey<String>(
    'create_task_type_tender',
  );
  static const Key bookingTypeCardKey = ValueKey<String>(
    'create_task_type_booking',
  );
  static const Key packageTierBasicKey = ValueKey<String>(
    'create_task_package_tier_basic',
  );
  static const Key packageTierStandardKey = ValueKey<String>(
    'create_task_package_tier_standard',
  );
  static const Key packageTierPremiumKey = ValueKey<String>(
    'create_task_package_tier_premium',
  );
  static const Key packagePriceFieldKey = ValueKey<String>(
    'create_task_package_price',
  );
  static const Key packageDescriptionFieldKey = ValueKey<String>(
    'create_task_package_description',
  );

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

  // Booking Packages State
  int _selectedPackageTier = 0; // 0: Basic, 1: Standard, 2: Premium
  final _packagePriceController = TextEditingController();
  final _packageDeliveryController = TextEditingController();
  final _packageRevisionsController = TextEditingController();
  final _packageDescriptionController = TextEditingController();

  // Store data for each tier: 0->Basic, 1->Standard, 2->Premium
  final Map<int, Map<String, String>> _packagesData = {
    0: {'price': '', 'delivery': '', 'revisions': '', 'description': ''},
    1: {'price': '', 'delivery': '', 'revisions': '', 'description': ''},
    2: {'price': '', 'delivery': '', 'revisions': '', 'description': ''},
  };

  void _loadPackageDataFromModel(Map<String, dynamic> packages) {
    void loadTier(int tier, String key) {
      if (packages.containsKey(key)) {
        final data = packages[key] as Map<String, dynamic>;
        _packagesData[tier] = {
          'price': data['price']?.toString() ?? '',
          'delivery': data['delivery']?.toString() ?? '',
          'revisions': data['revisions']?.toString() ?? '',
          'description': data['description']?.toString() ?? '',
        };
      }
    }

    loadTier(0, 'Basic');
    loadTier(1, 'Standard');
    loadTier(2, 'Premium');

    // Load initial values for currently selected tier (0)
    _updateControllersFromState(0);
  }

  void _updatePackageState(String key, String value) {
    _packagesData[_selectedPackageTier]?[key] = value;
  }

  void _updateControllersFromState(int tier) {
    final data = _packagesData[tier]!;
    _packagePriceController.text = data['price'] ?? '';
    _packageDeliveryController.text = data['delivery'] ?? '';
    _packageRevisionsController.text = data['revisions'] ?? '';
    _packageDescriptionController.text = data['description'] ?? '';
  }

  // Selection State
  TaskType _selectedTaskType = TaskType.tender;
  String? _selectedCategoryId;
  String? _selectedCategoryName; // Add this to track name separately
  DateTime? _selectedDeadline;

  // Data
  List<CategoryModel> _categories = [];
  bool _categoriesLoading = false;
  bool _isLoading = false;
  bool _categoriesLoadScheduled = false;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _budgetController.text = widget.task!.budget.toString();
      _selectedDeadline = widget.task!.deadline;
      _selectedCategoryId = widget.task!.categoryId;
      _selectedCategoryName =
          widget.task!.categoryName ?? widget.task!.category;
      _selectedTaskType = widget.task!.taskType;

      // Load packages if exist
      if (widget.task!.packages != null) {
        _loadPackageDataFromModel(widget.task!.packages!);
      }
    }
    // Categories loaded in didChangeDependencies so context has repository

    // Listeners to sync controllers to state
    _packagePriceController.addListener(
      () => _updatePackageState('price', _packagePriceController.text),
    );
    _packageDeliveryController.addListener(
      () => _updatePackageState('delivery', _packageDeliveryController.text),
    );
    _packageRevisionsController.addListener(
      () => _updatePackageState('revisions', _packageRevisionsController.text),
    );
    _packageDescriptionController.addListener(
      () => _updatePackageState(
        'description',
        _packageDescriptionController.text,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_categoriesLoadScheduled) {
      _categoriesLoadScheduled = true;
      _loadCategories();
    }
  }

  Future<void> _loadCategories() async {
    setState(() => _categoriesLoading = true);
    try {
      final repo = context.read<CategoriesRepository>();
      final cats = await repo.getAll();
      if (!mounted) return;
      setState(() {
        _categories = cats;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _categories = [];
      });
    } finally {
      if (mounted) setState(() => _categoriesLoading = false);
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
    if (userId == null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Use package price if booking, else budget
      double budget = double.tryParse(_budgetController.text) ?? 0;

      Map<String, dynamic>? packages;
      if (_selectedTaskType == TaskType.booking) {
        // Construct Packages Map from all tiers
        packages = {
          'Basic': _packagesData[0],
          'Standard': _packagesData[1],
          'Premium': _packagesData[2],
        };

        // Use lowest package price as "starting at" budget
        double? minPrice;
        for (var tierInfo in _packagesData.values) {
          final p = double.tryParse(tierInfo['price'] ?? '');
          if (p != null) {
            if (minPrice == null || p < minPrice) minPrice = p;
          }
        }
        budget = minPrice ?? 0;
      }

      final task = Task(
        id: widget.task?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        budget: budget,
        userId: userId,
        status:
            widget.task?.status ?? TaskStatus.open, // Preserve status on edit
        taskType: _selectedTaskType,
        createdAt:
            widget.task?.createdAt ?? DateTime.now(), // Preserve createdAt
        deadline: _selectedDeadline,
        categoryId: _selectedCategoryId,
        category: _selectedCategoryName, // Use the selected name
        skills: _tagsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        packages: packages,
        offers: widget.task?.offers ?? 0, // Preserve offers count
      );

      if (widget.task == null) {
        await vm.createTask(task);
      } else {
        final updateData = task.toJson();
        // Remove fields that shouldn't be updated or cause issues
        updateData.remove('id');
        updateData.remove('created_at');
        updateData.remove(
          'user_id',
        ); // RLS might block if it looks like a change (even if same)

        await vm.updateTask(task.id, updateData);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p24,
        vertical: AppDimens.p16,
      ),
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
                widget.task != null ? 'Edit Task' : 'Create Task',
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

  Widget _buildLabeledInput(
    String label,
    Widget input,
    AppColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.captionBold.copyWith(color: colorScheme.text),
        ),
        const SizedBox(height: AppDimens.p8),
        input,
      ],
    );
  }

  // --- Step 1: Concept ---
  Widget _buildStep1(AppColorScheme colorScheme) {
    final popularCategories = [
      {
        'icon': Icons.palette_outlined,
        'name': 'Design',
        'color': AppColors.lightRed,
      },
      {
        'icon': Icons.code,
        'name': 'Development',
        'color': AppColors.lightTeal,
      },
      {
        'icon': Icons.edit_note,
        'name': 'Writing',
        'color': AppColors.sand,
      },
      {'icon': Icons.phone_iphone, 'name': 'Mobile', 'color': AppColors.gold},
      {
        'icon': Icons.campaign_outlined,
        'name': 'Marketing',
        'color': AppColors.mediumGreyBlue,
      },
      {'icon': Icons.movie_outlined, 'name': 'Video', 'color': AppColors.teal},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Task Type',
          style: AppTypography.h5.copyWith(color: colorScheme.text),
        ),
        const SizedBox(height: AppDimens.p12),
        Row(
          children: [
            Expanded(
              child: _buildTypeCard(
                cardKey: CreateTaskScreen.tenderTypeCardKey,
                icon: Icons.assignment_outlined,
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
                cardKey: CreateTaskScreen.bookingTypeCardKey,
                icon: Icons.calendar_today_outlined,
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
        Text(
          'Choose Category',
          style: AppTypography.h5.copyWith(color: colorScheme.text),
        ),
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
                itemCount: _categories.isNotEmpty
                    ? _categories.length
                    : popularCategories.length,
                itemBuilder: (context, index) {
                  // Use actual categories if available, otherwise fallback
                  if (_categories.isNotEmpty) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategoryId == cat.id;
                    final icon = _getCategoryIcon(cat.name);
                    final catColor = _getCategoryColor(cat.name);

                    return _buildCategoryCard(
                      icon: icon,
                      name: cat.name,
                      isSelected: isSelected,
                      color: catColor,
                      colorScheme: colorScheme,
                      onTap: () => setState(() {
                        _selectedCategoryId = cat.id;
                        _selectedCategoryName = cat.name;
                      }),
                    );
                  } else {
                    final cat = popularCategories[index];
                    final catName = cat['name'] as String;
                    final isSelected =
                        _selectedCategoryName ==
                        catName; // Check name for fallback

                    return _buildCategoryCard(
                      icon: cat['icon'] as IconData,
                      name: catName,
                      isSelected: isSelected,
                      color: cat['color'] as Color,
                      colorScheme: colorScheme,
                      onTap: () => setState(() {
                        _selectedCategoryId =
                            null; // Clear UUID as we don't have one
                        _selectedCategoryName = catName;
                      }),
                    );
                  }
                },
              ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required IconData icon,
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
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : colorScheme.cardBackground,
          borderRadius: BorderRadius.circular(AppDimens.r16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: isSelected ? color : colorScheme.text),
            const SizedBox(height: 6),
            Text(
              name,
              style: AppTypography.captionBold.copyWith(
                color: colorScheme.text,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('design')) return Icons.palette_outlined;
    if (lowerName.contains('dev') || lowerName.contains('code')) {
      return Icons.code;
    }
    if (lowerName.contains('writ') || lowerName.contains('content')) {
      return Icons.edit_note;
    }
    if (lowerName.contains('mobile') || lowerName.contains('app')) {
      return Icons.phone_iphone;
    }
    if (lowerName.contains('market') || lowerName.contains('seo')) {
      return Icons.campaign_outlined;
    }
    if (lowerName.contains('video') || lowerName.contains('media')) {
      return Icons.movie_outlined;
    }
    return Icons.folder_outlined;
  }

  Color _getCategoryColor(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('design')) return AppColors.lightRed;
    if (lowerName.contains('dev') || lowerName.contains('code')) {
      return AppColors.lightTeal;
    }
    if (lowerName.contains('writ') || lowerName.contains('content')) {
      return AppColors.sand;
    }
    if (lowerName.contains('mobile') || lowerName.contains('app')) {
      return AppColors.gold;
    }
    if (lowerName.contains('market') || lowerName.contains('seo')) {
      return AppColors.mediumGreyBlue;
    }
    if (lowerName.contains('video') || lowerName.contains('media')) {
      return AppColors.teal;
    }
    return AppColors.teal;
  }

  Widget _buildTypeCard({
    Key? cardKey,
    required IconData icon,
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
        key: cardKey,
        duration: const Duration(milliseconds: 200),
        height: 100,
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : colorScheme.cardBackground,
          borderRadius: BorderRadius.circular(AppDimens.r18),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: isSelected ? color : colorScheme.text),
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
              style: AppTypography.micro.copyWith(
                color: colorScheme.textSecondary,
              ),
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
        Text(
          'Deadline',
          style: AppTypography.captionBold.copyWith(color: colorScheme.text),
        ),
        const SizedBox(height: AppDimens.p8),
        // Simple Deadline Chips
        Row(
          children: [3, 7, 14, 30].map((days) {
            final date = DateTime.now().add(Duration(days: days));
            final isSelected =
                _selectedDeadline != null &&
                _selectedDeadline!.difference(DateTime.now()).inDays + 1 ==
                    days; // approx check

            return Padding(
              padding: const EdgeInsets.only(right: AppDimens.p8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedDeadline = date),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.p12,
                    vertical: AppDimens.p10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.teal.withValues(alpha: 0.1)
                        : colorScheme.cardBackground,
                    borderRadius: BorderRadius.circular(AppDimens.r12),
                    border: Border.all(
                      color: isSelected ? AppColors.teal : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    days == 7
                        ? '1 Week'
                        : days == 14
                        ? '2 Weeks'
                        : days == 30
                        ? '1 Month'
                        : '$days Days',
                    style: AppTypography.captionBold.copyWith(
                      color: isSelected
                          ? AppColors.teal
                          : colorScheme.textSecondary,
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
            children: ['Basic', 'Standard', 'Premium'].asMap().entries.map((
              entry,
            ) {
              final index = entry.key;
              final label = entry.value;
              final isSelected = _selectedPackageTier == index;
              final Key tierKey = switch (index) {
                0 => CreateTaskScreen.packageTierBasicKey,
                1 => CreateTaskScreen.packageTierStandardKey,
                _ => CreateTaskScreen.packageTierPremiumKey,
              };
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedPackageTier = index);
                    _updateControllersFromState(index);
                  },
                  child: AnimatedContainer(
                    key: tierKey,
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimens.p10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.teal : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppDimens.r10),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.teal.withValues(alpha: 0.3),
                                blurRadius: 8,
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: AppTypography.captionBold.copyWith(
                        color: isSelected
                            ? Colors.white
                            : colorScheme.textSecondary,
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
                  fieldKey: CreateTaskScreen.packagePriceFieldKey,
                  controller:
                      _packagePriceController, // Note: Shared controller for now (simplified)
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
            fieldKey: CreateTaskScreen.packageDescriptionFieldKey,
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
              tapTargetKey: CreateTaskScreen.primaryActionButtonKey,
              text: _currentStep == 3
                  ? (widget.task != null ? 'Save Changes' : 'Create Task')
                  : 'Next Step',
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
