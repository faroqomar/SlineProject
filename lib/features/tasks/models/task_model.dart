import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';

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

  /// Seller level of the task author, hydrated from profile summaries.
  final String? authorSellerLevel;

  /// When a request is accepted, `assigned_freelancer_id` is set in DB.
  /// UI uses this to show "Assigned" state and gate actions.
  /// Assigned freelancer (set when a request is accepted). Nullable.
  final String? assignedFreelancerId;

  /// Storage paths (NOT URLs) for task images in the private `task-images` bucket.
  final List<String> imagePaths;

  /// Packages for booking tasks (Basic/Standard/Premium details).
  /// Structure: { 'Basic': {...}, 'Standard': {...}, 'Premium': {...} }
  final Map<String, dynamic>? packages;

  /// Number of offers/requests on this task (maintained by DB trigger).
  /// Only relevant for tender tasks.
  final int offers;

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
    this.authorSellerLevel,
    this.categoryName,
    this.assignedFreelancerId,
    this.imagePaths = const [],
    this.packages,
    this.offers = 0,
  });

  /// Create Task from JSON (supports both flat and JOIN-embedded profile data)
  ///
  /// Why this parsing logic: Supabase returns nested objects for JOINed relations.
  /// The `profiles` key contains user data when fetched with:
  /// `.select('*, profiles!tasks_client_id_fkey(full_name, avatar_url)')`
  ///
  /// This avoids N+1 queries by getting all data in a single request.
  factory Task.fromJson(Map<String, dynamic> json) {
    try {
      // Map database string to TaskType enum; default to tender for backward compatibility
      final typeStr = json['task_type'] as String?;
      final parsedTaskType = (typeStr == 'booking')
          ? TaskType.booking
          : TaskType.tender;

      final rawPaths = (json['image_paths'] as List?) ?? const [];
      final parsedImagePaths = rawPaths
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();

      // Extract profile data from JOIN (nested under 'profiles' key)
      // or from flat fields (for backward compatibility with existing code)
      final profileData = json['profiles'] as Map<String, dynamic>?;
      final parsedUserName =
          profileData?['full_name'] as String? ?? json['user_name'] as String?;
      final parsedUserAvatar =
          profileData?['avatar_url'] as String? ??
          json['user_avatar'] as String?;
      final parsedAuthorSellerLevel =
          profileData?['seller_level'] as String? ??
          json['author_seller_level'] as String?;

      final parsedOwnerId =
          (json['owner_id'] as String?) ??
          (json['client_id'] as String?) ??
          (json['user_id'] as String?) ??
          '';

      return Task(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        budget: (json['budget'] as num).toDouble(),
        userId: parsedOwnerId,
        status: _parseTaskStatus(json['status'] as String?),
        taskType: parsedTaskType,
        createdAt: DateTime.parse(json['created_at'] as String),
        deadline: json['deadline'] != null
            ? DateTime.parse(json['deadline'] as String)
            : null,
        skills:
            (json['skills'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        // New DB-first FK (nullable)
        categoryId: json['category_id'] as String?,
        // Legacy text (nullable for rollback/fallback)
        category: json['category'] as String?,
        // Resolved name from embedded relation (if present), fallback to legacy text
        categoryName:
            ((json['categories'] as Map?)?['name'] as String?) ??
            (json['category'] as String?),
        userName: parsedUserName,
        userAvatar: parsedUserAvatar,
        authorSellerLevel: parsedAuthorSellerLevel,
        assignedFreelancerId:
            (json['assigned_freelancer_id'] as String?) ??
            (json['freelancer_id'] as String?),
        imagePaths: parsedImagePaths,
        packages: json['packages'] as Map<String, dynamic>?,
        offers: (json['offers'] as int?) ?? 0,
      );
    } catch (e, st) {
      AppLogger.e(
        'Failed to parse Task',
        tag: 'Tasks',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  static TaskStatus _parseTaskStatus(String? rawStatus) {
    switch (rawStatus) {
      case 'open':
        return TaskStatus.open;
      case 'assigned':
        return TaskStatus.assigned;
      case 'in_progress':
      case 'inProgress':
        return TaskStatus.inProgress;
      case 'delivered':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      case 'closed':
        return TaskStatus.closed;
      case 'canceled':
      case 'cancelled':
        return TaskStatus.canceled;
      case 'draft':
        return TaskStatus.draft;
      default:
        AppLogger.w(
          'Unknown task status "$rawStatus" encountered, falling back to draft',
          tag: 'Tasks',
        );
        return TaskStatus.draft;
    }
  }

  static String _mapTaskStatusToDb(TaskStatus status) {
    switch (status) {
      case TaskStatus.inProgress:
        return 'in_progress';
      default:
        return status.name;
    }
  }

  /// Convert Task to JSON
  Map<String, dynamic> toJson({bool includeSystemFields = false}) {
    final map = {
      'title': title,
      'description': description,
      'budget': budget,
      'user_id': userId,
      'status': _mapTaskStatusToDb(status),
      'task_type': taskType.name,
      'deadline': deadline?.toIso8601String(),
      'skills': skills,
      // Prefer DB-first FK; legacy category text is optional
      'category_id': categoryId,
      if (category != null) 'category': category,
      'image_paths': imagePaths,
      if (assignedFreelancerId != null)
        'assigned_freelancer_id': assignedFreelancerId,
      'packages': packages,
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
    String? authorSellerLevel,
    String? categoryName,
    String? assignedFreelancerId,
    List<String>? imagePaths,
    Map<String, dynamic>? packages,
    int? offers,
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
      authorSellerLevel: authorSellerLevel ?? this.authorSellerLevel,
      categoryName: categoryName ?? this.categoryName,
      assignedFreelancerId: assignedFreelancerId ?? this.assignedFreelancerId,
      imagePaths: imagePaths ?? this.imagePaths,
      packages: packages ?? this.packages,
      offers: offers ?? this.offers,
    );
  }
}
