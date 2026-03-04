class ProfileModel {
  final String id;
  final String? fullName;
  final String? email;
  final String? avatarUrl;
  final String? bio;
  final String activeRole;
  final List<String> skills;
  final String? sellerLevel;
  final String accountStatus;
  final String? moderationReason;
  final String? restrictionScope;
  final DateTime? forceLogoutAfterUtc;
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
    this.accountStatus = 'active',
    this.moderationReason,
    this.restrictionScope,
    this.forceLogoutAfterUtc,
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
      accountStatus: (json['account_status'] as String?) ?? 'active',
      moderationReason: json['moderation_reason'] as String?,
      restrictionScope: json['restriction_scope'] as String?,
      forceLogoutAfterUtc: json['force_logout_after'] != null
          ? DateTime.tryParse(json['force_logout_after'].toString())?.toUtc()
          : null,
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
      'account_status': accountStatus,
      'moderation_reason': moderationReason,
      'restriction_scope': restrictionScope,
      'force_logout_after': forceLogoutAfterUtc?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? fullName,
    String? bio,
    String? avatarUrl,
    List<String>? skills,
    String? sellerLevel,
    String? accountStatus,
    String? moderationReason,
    String? restrictionScope,
    DateTime? forceLogoutAfterUtc,
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
      accountStatus: accountStatus ?? this.accountStatus,
      moderationReason: moderationReason ?? this.moderationReason,
      restrictionScope: restrictionScope ?? this.restrictionScope,
      forceLogoutAfterUtc: forceLogoutAfterUtc ?? this.forceLogoutAfterUtc,
      createdAt: createdAt,
    );
  }
}
