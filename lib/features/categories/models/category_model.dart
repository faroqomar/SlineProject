import 'package:flutter/foundation.dart';

/// CategoryModel
///
/// Immutable model representing a category row from `public.categories`.
/// - `id`         : UUID string
/// - `name`       : Human readable name (unique)
/// - `iconUrl`    : Optional icon path/URL (nullable)
/// - `createdAt`  : Server timestamp (UTC)
///
/// Notes:
/// - Keep this model small and serializable. It is shared by services and UI.
/// - All comments MUST be in English only.
@immutable
class CategoryModel {
  final String id;
  final String name;
  final String? iconUrl;
  final DateTime createdAt;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.createdAt,
  });

  /// Creates a CategoryModel from a Supabase JSON row.
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      iconUrl: json['icon_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    );
  }

  /// Serializes this model to a JSON payload (matching DB column names).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon_url': iconUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? iconUrl,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconUrl: iconUrl ?? this.iconUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'CategoryModel(id: $id, name: $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryModel &&
        other.id == id &&
        other.name == name &&
        other.iconUrl == iconUrl &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ iconUrl.hashCode ^ createdAt.hashCode;
}
