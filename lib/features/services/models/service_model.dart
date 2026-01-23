class ServiceModel {
  final String id;
  final String freelancerId;
  final String title;
  final String? description;
  final double? price;
  final int? deliveryDays;
  final String status; // 'active', 'draft', 'paused'
  final List<String> imageUrls;
  final DateTime createdAt;

  // Joined/Computed
  final int activeOrdersCount; // From bookings
  final double rating;

  const ServiceModel({
    required this.id,
    required this.freelancerId,
    required this.title,
    this.description,
    this.price,
    this.deliveryDays,
    required this.status,
    this.imageUrls = const [],
    required this.createdAt,
    this.activeOrdersCount = 0,
    this.rating = 0.0,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as String,
      freelancerId: json['freelancer_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      deliveryDays: json['delivery_days'] as int?,
      status: json['status'] as String,
      imageUrls:
          (json['image_urls'] as List?)?.map((e) => e as String).toList() ?? [],
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      // Mock stats for now until booking relations are strict
      activeOrdersCount: 0,
      rating: 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'freelancer_id': freelancerId,
      'title': title,
      'description': description,
      'price': price,
      'delivery_days': deliveryDays,
      'status': status,
      'image_urls': imageUrls,
    };
  }
}
