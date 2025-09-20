/// Enum for task status
enum TaskStatus {
  open,
  assigned,
  closed,
  inProgress,
}

/// Enum for task type (bidding vs. scheduling)
enum TaskType {
  /// Default tender-style tasks that use offers/requests
  tender,

  /// Booking-style tasks that use availability & scheduling
  booking,
}

/// Category notes:
/// - `categoryId` is a nullable FK to `public.categories(id)` (DB-first rollout).
/// - `category` is the legacy text name kept for backward compatibility and fallback.
/// - Prefer using `categoryId` going forward; `category` may be deprecated later.
/// Model representing a task/job posting
class Task {
  /// Unique identifier for the task
  final String id;

  /// Title of the task
  final String title;

  /// Detailed description of the task
  final String description;

  /// Budget allocated for the task
  final double budget;

  /// User ID of the person who posted the task
  final String userId;

  /// Current status of the task
  final TaskStatus status;

  /// Type of the task (tender or booking)
  final TaskType taskType;

  /// Timestamp when the task was created
  final DateTime createdAt;

  /// Optional deadline for task completion
  final DateTime? deadline;

  /// List of skills required for the task (planned for Supabase integration)
  final List<String> skills;

  /// Nullable FK to categories table (DB).
  final String? categoryId;

  /// Legacy text category (kept as fallback until full migration).
  final String? category;

  /// Resolved category name from embedded `categories(name)` or legacy `category`.
  final String? categoryName;

  /// Optional name of the user who posted the task
  final String? userName;

  /// Optional avatar URL of the user who posted the task
  final String? userAvatar;

  /// Storage paths (NOT URLs) for task images in the private `task-images` bucket.
  final List<String> imagePaths;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.budget,
    required this.userId,
    required this.status,
    this.taskType = TaskType.tender,
    required this.createdAt,
    this.deadline,
    this.skills = const [],
    this.categoryId,
    this.category,
    this.userName,
    this.userAvatar,
    this.categoryName,
    this.imagePaths = const [],
  });

  /// Create Task from JSON
  factory Task.fromJson(Map<String, dynamic> json) {
    // Map database string to TaskType enum; default to tender for backward compatibility
    final String? typeStr = json['task_type'] as String?;
    final TaskType parsedTaskType =
        (typeStr == 'booking') ? TaskType.booking : TaskType.tender;

    final rawPaths = (json['image_paths'] as List?) ?? const [];
    final parsedImagePaths = rawPaths
        .map((e) => e?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();

    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      budget: (json['budget'] as num).toDouble(),
      userId: json['user_id'] as String,
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TaskStatus.open,
      ),
      taskType: parsedTaskType,
      createdAt: DateTime.parse(json['created_at'] as String),
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      skills: (json['skills'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      // New DB-first FK (nullable)
      categoryId: json['category_id'] as String?,
      // Legacy text (nullable for rollback/fallback)
      category: json['category'] as String?,
      // Resolved name from embedded relation (if present), fallback to legacy text
      categoryName: ((json['categories'] as Map?)?['name'] as String?) ?? (json['category'] as String?),
      userName: null,
      userAvatar: null,
      imagePaths: parsedImagePaths,
    );
  }

  /// Convert Task to JSON
  Map<String, dynamic> toJson({bool includeSystemFields = false}) {
    final map = {
      'title': title,
      'description': description,
      'budget': budget,
      'user_id': userId,
      'status': status.name,
      'task_type': taskType.name,
      'deadline': deadline?.toIso8601String(),
      'skills': skills,
      // Prefer DB-first FK; legacy category text is optional
      'category_id': categoryId,
      if (category != null) 'category': category,
      'image_paths': imagePaths,
    };
    if (includeSystemFields) {
      map['id'] = id;
      map['created_at'] = createdAt.toIso8601String();
    }
    return map;
  }

  /// True if this is a tender (bidding) task
  bool get isTender => taskType == TaskType.tender;

  /// True if this is a booking (scheduling) task
  bool get isBooking => taskType == TaskType.booking;

  /// Create a copy with updated fields
  Task copyWith({
    String? id,
    String? title,
    String? description,
    double? budget,
    String? userId,
    TaskStatus? status,
    TaskType? taskType,
    DateTime? createdAt,
    DateTime? deadline,
    List<String>? skills,
    String? categoryId,
    String? category,
    String? userName,
    String? userAvatar,
    String? categoryName,
    List<String>? imagePaths,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      budget: budget ?? this.budget,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      taskType: taskType ?? this.taskType,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
      skills: skills ?? this.skills,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      categoryName: categoryName ?? this.categoryName,
      imagePaths: imagePaths ?? this.imagePaths,
    );
  }
}
