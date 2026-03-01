class ProfileModel {
  final String id;
  final String? fullName;
  final String? email;
  final String? avatarUrl;
  final String? bio;
  final String activeRole;
  final List<String> skills;
  final String? sellerLevel;
  final DateTime createdAt;

  ProfileModel({
    required this.id,
    this.fullName,
    this.email,
    this.avatarUrl,
    this.bio,
    this.activeRole = 'client',
    this.skills = const [],
    this.sellerLevel,
    required this.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      activeRole: json['active_role'] as String? ?? 'client',
      skills:
          (json['skills'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      sellerLevel: json['seller_level'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'avatar_url': avatarUrl,
      'bio': bio,
      'active_role': activeRole,
      'skills': skills,
      'seller_level': sellerLevel,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? fullName,
    String? bio,
    String? avatarUrl,
    List<String>? skills,
    String? sellerLevel,
  }) {
    return ProfileModel(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      activeRole: activeRole,
      skills: skills ?? this.skills,
      sellerLevel: sellerLevel ?? this.sellerLevel,
      createdAt: createdAt,
    );
  }
}
