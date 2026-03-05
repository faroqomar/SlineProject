import 'package:sline_app/features/services/models/service_status.dart';

const Object _nullSentinel = Object();

/// Immutable model mirroring `public.services`.
class ServiceModel {
  final String id;
  final String freelancerId;
  final String title;
  final String? description;
  final double? price;
  final int? deliveryDays;
  final ServiceStatus status;
  final List<String> imageUrls;
  final DateTime createdAt;

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
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as String,
      freelancerId: json['freelancer_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      deliveryDays: json['delivery_days'] as int?,
      status: ServiceStatus.fromString(json['status'] as String?),
      imageUrls:
          (json['image_urls'] as List?)?.map((e) => e as String).toList() ?? [],
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    );
  }

  /// Serialises for DB writes. Does NOT include `id`, `created_at`,
  /// or `freelancer_id` — RLS sets the owner server-side.
  Map<String, dynamic> toInsertJson() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'delivery_days': deliveryDays,
      'status': status.name,
      'image_urls': imageUrls,
    };
  }

  /// Full JSON representation (used for toJson round-trip / cache).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'freelancer_id': freelancerId,
      'title': title,
      'description': description,
      'price': price,
      'delivery_days': deliveryDays,
      'status': status.name,
      'image_urls': imageUrls,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ServiceModel copyWith({
    String? title,
    Object? description = _nullSentinel,
    double? price,
    int? deliveryDays,
    ServiceStatus? status,
    List<String>? imageUrls,
  }) {
    return ServiceModel(
      id: id,
      freelancerId: freelancerId,
      title: title ?? this.title,
      description: description == _nullSentinel
          ? this.description
          : description as String?,
      price: price ?? this.price,
      deliveryDays: deliveryDays ?? this.deliveryDays,
      status: status ?? this.status,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt,
    );
  }
}
