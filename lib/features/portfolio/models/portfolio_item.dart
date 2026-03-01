/// PortfolioItem
///
/// Immutable model representing one row in `public.portfolio_items`.
/// All comments MUST be in English only.
///
/// Contract: Canonical field is `imagePath` (storage path).
/// `imageUrl` is legacy fallback for backwards compatibility during migration.
class PortfolioItem {
  final String id;
  final String ownerId;
  final String title;
  final String? description;
  /// **Canonical:** Storage path (e.g., "ownerId/filename.jpg")
  /// Prefer this over imageUrl for new code.
  final String? imagePath;
  /// **Legacy:** Public URL (backwards compatibility only)
  /// Use only when imagePath is null.
  final String? imageUrl;
  final DateTime createdAt;

  const PortfolioItem({
    required this.id,
    required this.ownerId,
    required this.title,
    this.description,
    this.imagePath,
    this.imageUrl,
    required this.createdAt,
  });

  /// Creates from database JSON.
  /// Reads `image_path` (canonical) with fallback to `image_url` (legacy).
  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    final imagePath = json['image_path'] as String?;
    final imageUrl = json['image_url'] as String?;

    return PortfolioItem(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      imagePath: imagePath,
      // Fallback to imageUrl only if imagePath is null
      imageUrl: imagePath == null ? imageUrl : null,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    );
  }

  /// Converts to database JSON.
  /// Writes only to `image_path` (canonical). Does NOT write to `image_url`.
  Map<String, dynamic> toJson({bool includeSystem = false}) {
    final map = <String, dynamic>{
      'owner_id': ownerId,
      'title': title,
      'description': description,
      // Only write canonical field
      'image_path': imagePath,
    };
    if (includeSystem) {
      map['id'] = id;
      map['created_at'] = createdAt.toIso8601String();
    }
    return map;
  }

  /// Returns the effective image reference for rendering.
  /// Prefers imagePath (canonical), falls back to imageUrl (legacy).
  String? get effectiveImageRef => imagePath ?? imageUrl;

  /// Returns true if this item has an image (either canonical or legacy).
  bool get hasImage => imagePath != null || imageUrl != null;

  PortfolioItem copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? description,
    String? imagePath,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return PortfolioItem(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'PortfolioItem($id, $title, imagePath: $imagePath)';
}
