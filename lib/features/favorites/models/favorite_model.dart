

// Import the logger package for error logging
import 'package:logger/logger.dart';

// Create a top-level logger instance to log errors throughout the file
final logger = Logger();

/// Model representing a Favorite item
class FavoriteModel {
  // Unique identifier for the favorite
  final String id;
  // Identifier of the favorited freelancer
  final String freelancerId;
  // The date and time when the favorite was created
  final DateTime createdAt;

  /// Constructor with required fields
  FavoriteModel({
    required this.id,
    required this.freelancerId,
    required this.createdAt,
  });

  /// Factory constructor to create a FavoriteModel from a Map
  /// Wraps parsing in try/catch to handle and log potential errors
  factory FavoriteModel.fromMap(Map<String, dynamic> map) {
    try {
      return FavoriteModel(
        id: map['id'] as String,
        freelancerId: map['freelancer_id'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
    } catch (e, st) {
      // Log error with stack trace for debugging
      logger.e("Failed to parse FavoriteModel.fromMap", error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Converts the FavoriteModel instance back to a Map
  /// Used for serialization (e.g., sending to APIs or local storage)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'freelancer_id': freelancerId,
      // Store date as ISO8601 string for consistency
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Model representing a Favorite joined with freelancer profile info.
class FavoriteWithProfile {
  final String freelancerId;
  final String? freelancerName;
  final String? freelancerAvatar;
  final DateTime createdAt;

  FavoriteWithProfile({
    required this.freelancerId,
    required this.createdAt,
    this.freelancerName,
    this.freelancerAvatar,
  });

  factory FavoriteWithProfile.fromMap(Map<String, dynamic> map) {
    final freelancer = map['freelancer'] as Map?;
    return FavoriteWithProfile(
      freelancerId: freelancer?['id'] as String,
      freelancerName: freelancer?['full_name'] as String?,
      freelancerAvatar: freelancer?['avatar_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}