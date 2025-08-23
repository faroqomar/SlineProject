/// PortfolioItem
///
/// Immutable model representing one row in `public.portfolio_items`.
/// All comments MUST be in English only.
class PortfolioItem {
  final String id;
  final String ownerId;
  final String title;
  final String? description;
  final String? imageUrl; // Public URL (for public bucket) or signed URL (if private)
  final DateTime createdAt;

  const PortfolioItem({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.createdAt,
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    );
  }

  Map<String, dynamic> toJson({bool includeSystem = false}) {
    final map = <String, dynamic>{
      'owner_id': ownerId,
      'title': title,
      'description': description,
      'image_url': imageUrl,
    };
    if (includeSystem) {
      map['id'] = id;
      map['created_at'] = createdAt.toIso8601String();
    }
    return map;
  }

  PortfolioItem copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? description,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return PortfolioItem(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'PortfolioItem($id, $title)';
}