/// Enum for task status
enum TaskStatus {
  open,
  inProgress,
  completed,
  cancelled,
}

/// Model representing a task/job posting
class Task {
  final String id;
  final String title;
  final String description;
  final double budget;
  final String postedBy;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime? deadline;
  final List<String> skills;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.budget,
    required this.postedBy,
    required this.status,
    required this.createdAt,
    this.deadline,
    this.skills = const [],
  });

  /// Create Task from JSON
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      budget: (json['budget'] as num).toDouble(),
      postedBy: json['posted_by'] as String,
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TaskStatus.open,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      deadline: json['deadline'] != null 
          ? DateTime.parse(json['deadline'] as String) 
          : null,
      skills: (json['skills'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
    );
  }

  /// Convert Task to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'budget': budget,
      'posted_by': postedBy,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'skills': skills,
    };
  }

  /// Create a copy with updated fields
  Task copyWith({
    String? id,
    String? title,
    String? description,
    double? budget,
    String? postedBy,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? deadline,
    List<String>? skills,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      budget: budget ?? this.budget,
      postedBy: postedBy ?? this.postedBy,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
      skills: skills ?? this.skills,
    );
  }
}
