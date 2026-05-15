import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/theme/app_colors.dart' show AppColorScheme;
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_card_container.dart';
import 'package:sline_app/core/widgets/app_text_field.dart';
import 'package:sline_app/features/categories/models/category_model.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:sline_app/features/tasks/view/widgets/booking_logistics_section.dart';
import 'package:sline_app/features/tasks/view/widgets/task_concept_section.dart';
import 'package:sline_app/features/tasks/viewmodels/task_view_model.dart';

/// Result returned when the create/edit sheet finishes a persisted post.
///
/// The parent shell uses this value to refresh the Home feed after the sheet
/// closes instead of guessing whether a create flow completed.
@immutable
class CreateTaskResult {
  /// Creates a completion result for a task create or update operation.
  const CreateTaskResult({
    required this.operation,
    required this.taskType,
    this.taskId,
  });

  /// The persistence operation that completed successfully.
  final CreateTaskOperation operation;

  /// The post type that was created or updated.
  final TaskType taskType;

  /// The persisted task id when the repository returned or already had one.
  final String? taskId;

  /// User-facing success copy for the durable parent-shell confirmation.
  String get successMessage {
    final postType = taskType == TaskType.booking
        ? 'Booking post'
        : 'Tender post';
    return operation == CreateTaskOperation.created
        ? '$postType published. Home feed refreshed.'
        : '$postType updated. Home feed refreshed.';
  }
}

/// Distinguishes create and update completions from the create/edit sheet.
enum CreateTaskOperation {
  /// A new post was created.
  created,

  /// An existing post was updated.
  updated,
}

/// Bottom-sheet create/edit flow for Tender and Booking posts.
///
/// The screen keeps the existing [TaskViewModel] create/update contracts while
/// presenting the Phase 2 Amber Dusk Type, Details, and Review progression.
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
  static const Key titleFieldKey = ValueKey<String>('create_task_title');
  static const Key descriptionFieldKey = ValueKey<String>(
    'create_task_description',
  );
  static const Key budgetFieldKey = ValueKey<String>('create_task_budget');

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  static const double _kTypeStepHeightFraction = 0.74;
  static const double _kDetailStepHeightFraction = 0.84;

  int _currentStep = 1;

  // Form State
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController(); // Comma separated
  final _budgetController = TextEditingController();
  final _locationController = TextEditingController();
  final _workTypeController = TextEditingController();

  // Booking Packages State
  int _selectedPackageTier = 0; // 0: Basic, 1: Standard, 2: Premium
  final _bookingRoleController = TextEditingController();
  final _bookingSeniorityController = TextEditingController();
  final _bookingPeriodController = TextEditingController();
  final _bookingLocationController = TextEditingController();
  final _bookingExperienceController = TextEditingController();
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
    final details = Task.packageDetailsFrom(packages);
    if (details != null) {
      _locationController.text = details['location']?.toString() ?? '';
      _workTypeController.text = details['workType']?.toString() ?? '';
      _bookingRoleController.text = details['role']?.toString() ?? '';
      _bookingSeniorityController.text = details['seniority']?.toString() ?? '';
      _bookingPeriodController.text = details['period']?.toString() ?? '';
      _bookingLocationController.text = details['location']?.toString() ?? '';
      _bookingExperienceController.text =
          details['experience']?.toString() ?? '';
    }

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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_loadCategories());
      });
    }
  }

  Future<void> _loadCategories() async {
    setState(() => _categoriesLoading = true);
    try {
      final vm = context.read<TaskViewModel>();
      final cats = await vm.loadCategories();
      if (!mounted) return;
      setState(() {
        _categories = cats;
      });
    } on Exception catch (_) {
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
    _locationController.dispose();
    _workTypeController.dispose();
    _bookingRoleController.dispose();
    _bookingSeniorityController.dispose();
    _bookingPeriodController.dispose();
    _bookingLocationController.dispose();
    _bookingExperienceController.dispose();
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
      unawaited(_submit());
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  Map<String, String> _compactDetails(Map<String, String> rawDetails) {
    return Map<String, String>.fromEntries(
      rawDetails.entries
          .where((entry) => entry.value.trim().isNotEmpty)
          .map((entry) => MapEntry(entry.key, entry.value.trim())),
    );
  }

  Map<String, String> _tenderDetailsPayload() {
    return _compactDetails({
      'location': _locationController.text,
      'workType': _workTypeController.text,
    });
  }

  Map<String, String> _bookingDetailsPayload() {
    return _compactDetails({
      'role': _bookingRoleController.text,
      'seniority': _bookingSeniorityController.text,
      'period': _bookingPeriodController.text,
      'location': _bookingLocationController.text,
      'experience': _bookingExperienceController.text,
    });
  }

  List<String> _skillsPayload() {
    final values = _tagsController.text
        .split(',')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
    final workType = _workTypeController.text.trim();
    if (_selectedTaskType == TaskType.tender && workType.isNotEmpty) {
      values.add(workType);
    }
    return values.toSet().toList();
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
      var budget = double.tryParse(_budgetController.text) ?? 0;

      Map<String, dynamic>? packages;
      if (_selectedTaskType == TaskType.booking) {
        final bookingDetails = _bookingDetailsPayload();
        // Construct Packages Map from all tiers
        packages = Task.packagesWithDetails(
          packages: {
            'Basic': _packagesData[0],
            'Standard': _packagesData[1],
            'Premium': _packagesData[2],
          },
          details: bookingDetails,
        );

        // Use lowest package price as "starting at" budget
        double? minPrice;
        for (final tierInfo in _packagesData.values) {
          final p = double.tryParse(tierInfo['price'] ?? '');
          if (p != null) {
            if (minPrice == null || p < minPrice) minPrice = p;
          }
        }
        budget = minPrice ?? 0;
      } else {
        final tenderDetails = _tenderDetailsPayload();
        if (tenderDetails.isNotEmpty) {
          // The current task schema has no first-class location/work-type
          // columns, so Amber Dusk create metadata is stored in the existing
          // JSON details field until the backend contract grows explicit fields.
          packages = Task.packagesWithDetails(
            packages: const <String, dynamic>{},
            details: tenderDetails,
          );
        }
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
        skills: _skillsPayload(),
        packages: packages,
        offers: widget.task?.offers ?? 0, // Preserve offers count
      );

      final CreateTaskResult result;
      if (widget.task == null) {
        final created = await vm.createTask(task);
        result = CreateTaskResult(
          operation: CreateTaskOperation.created,
          taskType: created.taskType,
          taskId: created.id,
        );
      } else {
        // Remove fields that shouldn't be updated or cause issues
        final updateData = task.toJson()
          ..remove('id')
          ..remove('created_at')
          ..remove(
            'user_id',
          ); // RLS might block if it looks like a change (even if same)

        await vm.updateTask(task.id, updateData);
        result = CreateTaskResult(
          operation: CreateTaskOperation.updated,
          taskType: task.taskType,
          taskId: task.id,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, result);
    } on Exception catch (e) {
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
    final colorScheme = context.colorScheme;
    final sheetRecipe = AmberDuskTokens.surfaces.sheet;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: AmberDuskColors.transparent,
      resizeToAvoidBottomInset: true,
      body: AnimatedPadding(
        duration: AppMotion.fast,
        curve: AppMotion.curveDecel,
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final sheetHeight =
                    constraints.maxHeight *
                    (_currentStep == 1
                        ? _kTypeStepHeightFraction
                        : _kDetailStepHeightFraction);
                return SizedBox(
                  width: double.infinity,
                  height: sheetHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: sheetRecipe.fill,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(sheetRecipe.radius),
                      ),
                      boxShadow: AppDecorations.elevation(
                        sheetRecipe.elevationLevel,
                        isDark: colorScheme.isDark,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildHeader(colorScheme),

                        Expanded(
                          child: SingleChildScrollView(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.fromLTRB(
                              AmberDuskSpacing.contentHorizontalPadding,
                              AppDimens.p8,
                              AmberDuskSpacing.contentHorizontalPadding,
                              AppDimens.p24,
                            ),
                            child: _buildStepContent(colorScheme),
                          ),
                        ),

                        _buildBottomBar(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorScheme colorScheme) {
    const colors = AmberDuskTokens.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AmberDuskSpacing.contentHorizontalPadding,
        vertical: AppDimens.p12,
      ),
      child: Column(
        children: [
          Container(
            width: AppDimens.p40,
            height: AppDimens.p4,
            margin: const EdgeInsets.only(bottom: AppDimens.p12),
            decoration: BoxDecoration(
              color: colors.surfaceHighest,
              borderRadius: BorderRadius.circular(AppDimens.r4),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: 'Close create post',
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: colors.primary),
              ),
              Text(
                widget.task != null ? 'Edit post' : 'Create a post',
                style: AmberDuskTokens.typography.sectionTitle.copyWith(
                  color: colors.text,
                ),
              ),
              const SizedBox(width: AppDimens.p24), // Balance spacing
            ],
          ),
          const SizedBox(height: AppDimens.p12),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.r4),
            child: LinearProgressIndicator(
              value: _currentStep / 3,
              backgroundColor: colors.surfaceHighest,
              valueColor: AlwaysStoppedAnimation(colors.primary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: AppDimens.p6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepLabel('Type', 1),
              _buildStepLabel('Details', 2),
              _buildStepLabel('Review', 3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepLabel(String label, int step) {
    const colors = AmberDuskTokens.colors;
    final isActive = _currentStep >= step;
    return Text(
      label,
      style: AppTypography.captionBold.copyWith(
        color: isActive ? colors.primary : colors.muted,
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
          style: AmberDuskTokens.widgetTheme.fields.labelStyle.copyWith(
            color: AmberDuskTokens.colors.muted,
          ),
        ),
        const SizedBox(height: AppDimens.p8),
        input,
      ],
    );
  }

  // --- Step 1: Type ---
  Widget _buildStep1(AppColorScheme colorScheme) {
    return TaskConceptSection(
      selectedTaskType: _selectedTaskType,
      onTaskTypeChanged: (type) => setState(() => _selectedTaskType = type),
    );
  }

  // --- Step 2: Details ---
  Widget _buildStep2(AppColorScheme colorScheme) {
    final isBooking = _selectedTaskType == TaskType.booking;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabeledInput(
          isBooking ? 'Booking title' : 'Tender title',
          AppTextField(
            key: CreateTaskScreen.titleFieldKey,
            hintText: isBooking
                ? 'e.g., Mobile app UX audit'
                : 'e.g., Landing page for clothing brand',
            controller: _titleController,
          ),
          colorScheme,
        ),
        const SizedBox(height: AppDimens.p16),
        _buildLabeledInput(
          isBooking ? 'Service description' : 'Tender description',
          AppTextField(
            key: CreateTaskScreen.descriptionFieldKey,
            hintText: isBooking
                ? 'Describe what clients receive...'
                : 'Describe the project freelancers should quote...',
            controller: _descriptionController,
            maxLines: 5,
          ),
          colorScheme,
        ),
        const SizedBox(height: AppDimens.p16),
        if (isBooking)
          _buildBookingLogistics(colorScheme)
        else
          _buildTenderDetails(colorScheme),
        const SizedBox(height: AppDimens.p16),
        _buildCategorySelector(colorScheme),
        const SizedBox(height: AppDimens.p16),
        _buildLabeledInput(
          'Tags',
          AppTextField(
            hintText: isBooking
                ? 'e.g., UX, Audit, Prototype'
                : 'e.g., Design, Landing Page',
            controller: _tagsController,
          ),
          colorScheme,
        ),
      ],
    );
  }

  // --- Step 3: Review ---
  Widget _buildStep3(AppColorScheme colorScheme) {
    return _buildReviewPreview(colorScheme);
  }

  Widget _buildTenderDetails(AppColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabeledInput(
          'Budget (IQD)',
          AppTextField(
            key: CreateTaskScreen.budgetFieldKey,
            hintText: 'Enter amount',
            controller: _budgetController,
            keyboardType: TextInputType.number,
          ),
          colorScheme,
        ),
        const SizedBox(height: AppDimens.p16),
        _buildLabeledInput(
          'Location',
          AppTextField(
            hintText: 'Remote or city',
            controller: _locationController,
          ),
          colorScheme,
        ),
        const SizedBox(height: AppDimens.p16),
        _buildLabeledInput(
          'Work type',
          AppTextField(
            hintText: 'e.g., Design system audit',
            controller: _workTypeController,
          ),
          colorScheme,
        ),
        const SizedBox(height: AppDimens.p16),
        _buildDeadlineSelector(),
      ],
    );
  }

  Widget _buildDeadlineSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deadline',
          style: AppTypography.captionBold.copyWith(
            color: AmberDuskTokens.colors.text,
          ),
        ),
        const SizedBox(height: AppDimens.p8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [3, 7, 14, 30].map((days) {
              final date = DateTime.now().add(Duration(days: days));
              final isSelected =
                  _selectedDeadline != null &&
                  _selectedDeadline!.year == date.year &&
                  _selectedDeadline!.month == date.month &&
                  _selectedDeadline!.day == date.day;

              return Padding(
                padding: const EdgeInsets.only(right: AppDimens.p8),
                child: Semantics(
                  key: ValueKey<String>('create_task_deadline_$days'),
                  button: true,
                  selected: isSelected,
                  label: _deadlineLabel(days),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _selectedDeadline = date),
                    child: AnimatedContainer(
                      duration: AppMotion.fast,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.p12,
                        vertical: AppDimens.p10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AmberDuskTokens.colors.activeGlow
                            : AmberDuskTokens.colors.surface,
                        borderRadius: BorderRadius.circular(AppDimens.r12),
                        border: Border.all(
                          color: isSelected
                              ? AmberDuskTokens.colors.primary
                              : AmberDuskColors.transparent,
                        ),
                      ),
                      child: Text(
                        _deadlineLabel(days),
                        style: AppTypography.captionBold.copyWith(
                          color: isSelected
                              ? AmberDuskTokens.colors.primary
                              : AmberDuskTokens.colors.muted,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _deadlineLabel(int days) {
    return days == 7
        ? '1 Week'
        : days == 14
        ? '2 Weeks'
        : days == 30
        ? '1 Month'
        : '$days Days';
  }

  Widget _buildCategorySelector(AppColorScheme colorScheme) {
    const colors = AmberDuskTokens.colors;
    final popularCategories = <({IconData icon, String name, Color color})>[
      (icon: Icons.palette_outlined, name: 'Design', color: colors.rust),
      (icon: Icons.code, name: 'Development', color: colors.forest),
      (icon: Icons.edit_note, name: 'Writing', color: colors.star),
      (icon: Icons.phone_iphone, name: 'Mobile', color: colors.warning),
      (
        icon: Icons.campaign_outlined,
        name: 'Marketing',
        color: colors.primaryDeep,
      ),
      (icon: Icons.movie_outlined, name: 'Video', color: colors.primary),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: AmberDuskTokens.typography.sectionTitle.copyWith(
            color: colors.text,
          ),
        ),
        const SizedBox(height: AppDimens.p12),
        if (_categoriesLoading)
          const Center(child: CircularProgressIndicator())
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppDimens.p10,
              mainAxisSpacing: AppDimens.p10,
              childAspectRatio: 1.22,
            ),
            itemCount: _categories.isNotEmpty
                ? _categories.length
                : popularCategories.length,
            itemBuilder: (context, index) {
              if (_categories.isNotEmpty) {
                final category = _categories[index];
                return _buildCategoryCard(
                  icon: _getCategoryIcon(category.name),
                  name: category.name,
                  isSelected: _selectedCategoryId == category.id,
                  color: _getCategoryColor(category.name),
                  colorScheme: colorScheme,
                  onTap: () => setState(() {
                    _selectedCategoryId = category.id;
                    _selectedCategoryName = category.name;
                  }),
                );
              }

              final category = popularCategories[index];
              return _buildCategoryCard(
                icon: category.icon,
                name: category.name,
                isSelected: _selectedCategoryName == category.name,
                color: category.color,
                colorScheme: colorScheme,
                onTap: () => setState(() {
                  _selectedCategoryId = null;
                  _selectedCategoryName = category.name;
                }),
              );
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
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$name category',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.18)
                : AmberDuskTokens.colors.surface,
            borderRadius: BorderRadius.circular(AppDimens.r16),
            border: Border.all(
              color: isSelected ? color : AmberDuskTokens.colors.surfaceHighest,
            ),
            boxShadow: AppDecorations.elevation(1, isDark: colorScheme.isDark),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: AppDimens.iconSizeMedium,
                color: isSelected ? color : AmberDuskTokens.colors.text,
              ),
              const SizedBox(height: AppDimens.p6),
              Text(
                name,
                style: AppTypography.captionBold.copyWith(
                  color: AmberDuskTokens.colors.text,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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
    const colors = AmberDuskTokens.colors;
    if (lowerName.contains('design')) return colors.rust;
    if (lowerName.contains('dev') || lowerName.contains('code')) {
      return colors.forest;
    }
    if (lowerName.contains('writ') || lowerName.contains('content')) {
      return colors.star;
    }
    if (lowerName.contains('mobile') || lowerName.contains('app')) {
      return colors.warning;
    }
    if (lowerName.contains('market') || lowerName.contains('seo')) {
      return colors.primaryDeep;
    }
    if (lowerName.contains('video') || lowerName.contains('media')) {
      return colors.primary;
    }
    return colors.primary;
  }

  Widget _buildBookingLogistics(AppColorScheme colorScheme) {
    return BookingLogisticsSection(
      selectedPackageTier: _selectedPackageTier,
      bookingRoleController: _bookingRoleController,
      bookingSeniorityController: _bookingSeniorityController,
      bookingPeriodController: _bookingPeriodController,
      bookingLocationController: _bookingLocationController,
      bookingExperienceController: _bookingExperienceController,
      packagePriceController: _packagePriceController,
      packageDeliveryController: _packageDeliveryController,
      packageRevisionsController: _packageRevisionsController,
      packageDescriptionController: _packageDescriptionController,
      onTierChanged: (index) {
        setState(() => _selectedPackageTier = index);
        _updateControllersFromState(index);
      },
      buildLabeledInput: _buildLabeledInput,
    );
  }

  Widget _buildReviewPreview(AppColorScheme colorScheme) {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final isBooking = _selectedTaskType == TaskType.booking;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review preview',
          style: AmberDuskTokens.typography.sectionTitle.copyWith(
            color: AmberDuskTokens.colors.text,
          ),
        ),
        const SizedBox(height: AppDimens.p8),
        Text(
          'Check how this post will read before publishing.',
          style: AmberDuskTokens.typography.bodySmall.copyWith(
            color: AmberDuskTokens.colors.muted,
          ),
        ),
        const SizedBox(height: AppDimens.p12),
        if (isBooking)
          _buildBookingPreviewCard(colorScheme, title, description)
        else
          _buildTenderPreviewCard(colorScheme, title, description),
      ],
    );
  }

  Widget _buildTenderPreviewCard(
    AppColorScheme colorScheme,
    String title,
    String description,
  ) {
    final cards = AmberDuskTokens.widgetTheme.cards;
    final status = AmberDuskTokens.widgetTheme.statusPills.primary;
    final budget = _budgetController.text.trim();
    final category = _selectedCategoryName?.trim();
    final location = _locationController.text.trim();
    final workType = _workTypeController.text.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.p16),
      decoration: BoxDecoration(
        color: cards.task.background,
        borderRadius: BorderRadius.circular(cards.task.radius),
        border: Border.all(color: cards.border, width: cards.borderWidth),
        boxShadow: AppDecorations.elevation(
          cards.task.elevationLevel,
          isDark: colorScheme.isDark,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.isEmpty ? 'Tender title' : title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AmberDuskTokens.typography.sectionTitle.copyWith(
                    color: AmberDuskTokens.colors.text,
                  ),
                ),
              ),
              Container(
                padding: AmberDuskTokens.widgetTheme.statusPills.smallPadding,
                decoration: BoxDecoration(
                  color: status.background,
                  borderRadius: BorderRadius.circular(
                    AmberDuskTokens.widgetTheme.statusPills.radius,
                  ),
                ),
                child: Text(
                  'TENDER',
                  style: AmberDuskTokens.widgetTheme.statusPills.smallTextStyle
                      .copyWith(color: status.foreground),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.p10),
          Text(
            description.isEmpty ? 'Tender description preview.' : description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AmberDuskTokens.typography.bodySmall.copyWith(
              color: AmberDuskTokens.colors.muted,
            ),
          ),
          const SizedBox(height: AppDimens.p14),
          Wrap(
            spacing: AppDimens.p8,
            runSpacing: AppDimens.p8,
            children: [
              _buildPreviewChip(
                category == null || category.isEmpty ? 'Category' : category,
              ),
              _buildPreviewChip(
                _selectedDeadline == null ? 'Deadline open' : 'Deadline set',
              ),
              _buildPreviewChip(
                budget.isEmpty ? 'Budget in IQD' : '$budget IQD',
              ),
              _buildPreviewChip(location.isEmpty ? 'Location open' : location),
              if (workType.isNotEmpty) _buildPreviewChip(workType),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingPreviewCard(
    AppColorScheme colorScheme,
    String title,
    String description,
  ) {
    final hero = AmberDuskTokens.surfaces.hero;
    final tierData =
        _packagesData[_selectedPackageTier] ?? const <String, String>{};
    final price = tierData['price']?.trim() ?? '';
    final role = _bookingRoleController.text.trim();
    final location = _bookingLocationController.text.trim();
    final period = _bookingPeriodController.text.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.p18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hero.gradientStops,
        ),
        borderRadius: BorderRadius.circular(hero.radius),
        boxShadow: AppDecorations.elevation(
          hero.elevationLevel,
          isDark: colorScheme.isDark,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.isEmpty ? 'Booking package' : title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AmberDuskTokens.typography.bookingName.copyWith(
              color: AmberDuskTokens.colors.heroText,
            ),
          ),
          const SizedBox(height: AppDimens.p8),
          Text(
            description.isEmpty
                ? 'Packaged service clients can book.'
                : description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AmberDuskTokens.typography.bodySmall.copyWith(
              color: AmberDuskTokens.colors.heroMuted,
            ),
          ),
          const SizedBox(height: AppDimens.p16),
          Text(
            price.isEmpty ? 'Price in IQD' : '$price IQD',
            style: AmberDuskTokens.typography.sectionTitle.copyWith(
              color: AmberDuskTokens.colors.heroText,
            ),
          ),
          const SizedBox(height: AppDimens.p12),
          Wrap(
            spacing: AppDimens.p8,
            runSpacing: AppDimens.p8,
            children: [
              _buildHeroPreviewChip(role.isEmpty ? 'Role' : role),
              _buildHeroPreviewChip(location.isEmpty ? 'Location' : location),
              _buildHeroPreviewChip(period.isEmpty ? 'Period' : period),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroPreviewChip(String label) {
    return Container(
      padding: AmberDuskTokens.widgetTheme.statusPills.smallPadding,
      decoration: BoxDecoration(
        color: AmberDuskTokens.colors.heroChip,
        borderRadius: BorderRadius.circular(
          AmberDuskTokens.widgetTheme.statusPills.radius,
        ),
      ),
      child: Text(
        label,
        style: AmberDuskTokens.widgetTheme.statusPills.smallTextStyle.copyWith(
          color: AmberDuskTokens.colors.heroText,
        ),
      ),
    );
  }

  Widget _buildPreviewChip(String label) {
    return Container(
      padding: AmberDuskTokens.widgetTheme.statusPills.smallPadding,
      decoration: BoxDecoration(
        color: AmberDuskTokens.colors.surfaceHighest,
        borderRadius: BorderRadius.circular(
          AmberDuskTokens.widgetTheme.statusPills.radius,
        ),
      ),
      child: Text(
        label,
        style: AmberDuskTokens.widgetTheme.statusPills.smallTextStyle.copyWith(
          color: AmberDuskTokens.colors.textSubtle,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return AppCardContainer(
      padding: const EdgeInsets.fromLTRB(
        AmberDuskSpacing.contentHorizontalPadding,
        AppDimens.p12,
        AmberDuskSpacing.contentHorizontalPadding,
        AppDimens.p16,
      ),
      borderRadius: BorderRadius.zero,
      child: Row(
        children: [
          if (_currentStep > 1)
            Padding(
              padding: const EdgeInsets.only(right: AppDimens.p12),
              child: SizedBox(
                width: AppDimens.p100,
                child: AppButton(
                  text: 'Back',
                  isPrimary: false,
                  onPressed: _prevStep,
                ),
              ),
            ),
          if (_currentStep == 1)
            Padding(
              padding: const EdgeInsets.only(right: AppDimens.p12),
              child: SizedBox(
                width: AppDimens.p100,
                child: AppButton(
                  text: 'Cancel',
                  isPrimary: false,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          Expanded(
            child: AppButton(
              tapTargetKey: CreateTaskScreen.primaryActionButtonKey,
              text: _currentStep == 3
                  ? (widget.task != null ? 'Save changes' : 'Post now')
                  : 'Continue',
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
