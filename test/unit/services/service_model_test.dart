import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/features/services/models/service_model.dart';
import 'package:sline_app/features/services/models/service_status.dart';

void main() {
  group('ServiceStatus', () {
    test('fromString parses known values', () {
      expect(ServiceStatus.fromString('active'), ServiceStatus.active);
      expect(ServiceStatus.fromString('draft'), ServiceStatus.draft);
      expect(ServiceStatus.fromString('paused'), ServiceStatus.paused);
    });

    test('fromString defaults to draft for unknowns', () {
      expect(ServiceStatus.fromString('unknown'), ServiceStatus.draft);
      expect(ServiceStatus.fromString(null), ServiceStatus.draft);
      expect(ServiceStatus.fromString(''), ServiceStatus.draft);
    });

    test('label returns human-readable text', () {
      expect(ServiceStatus.active.label, 'Active');
      expect(ServiceStatus.draft.label, 'Draft');
      expect(ServiceStatus.paused.label, 'Paused');
    });
  });

  group('ServiceModel.fromJson', () {
    final fullJson = <String, dynamic>{
      'id': 'svc-001',
      'freelancer_id': 'user-123',
      'title': 'Logo Design',
      'description': 'Professional logo design service',
      'price': 49.99,
      'delivery_days': 3,
      'status': 'active',
      'image_urls': ['img1.jpg', 'img2.jpg'],
      'created_at': '2026-01-15T10:00:00Z',
    };

    test('parses all fields correctly', () {
      final model = ServiceModel.fromJson(fullJson);

      expect(model.id, 'svc-001');
      expect(model.freelancerId, 'user-123');
      expect(model.title, 'Logo Design');
      expect(model.description, 'Professional logo design service');
      expect(model.price, 49.99);
      expect(model.deliveryDays, 3);
      expect(model.status, ServiceStatus.active);
      expect(model.imageUrls, ['img1.jpg', 'img2.jpg']);
      expect(model.createdAt.isUtc, true);
    });

    test('handles null optional fields', () {
      final minimalJson = <String, dynamic>{
        'id': 'svc-002',
        'freelancer_id': 'user-456',
        'title': 'Web Dev',
        'description': null,
        'price': null,
        'delivery_days': null,
        'status': 'draft',
        'image_urls': null,
        'created_at': '2026-02-01T12:00:00Z',
      };

      final model = ServiceModel.fromJson(minimalJson);

      expect(model.description, isNull);
      expect(model.price, isNull);
      expect(model.deliveryDays, isNull);
      expect(model.imageUrls, isEmpty);
      expect(model.status, ServiceStatus.draft);
    });

    test('handles unknown status gracefully', () {
      final json = Map<String, dynamic>.from(fullJson)..['status'] = 'archived';

      final model = ServiceModel.fromJson(json);
      expect(model.status, ServiceStatus.draft);
    });
  });

  group('ServiceModel.toJson round-trip', () {
    test('toJson produces complete JSON', () {
      final model = ServiceModel(
        id: 'svc-003',
        freelancerId: 'user-789',
        title: 'SEO Audit',
        description: 'Full SEO audit',
        price: 199.0,
        deliveryDays: 7,
        status: ServiceStatus.active,
        imageUrls: ['audit.png'],
        createdAt: DateTime.utc(2026, 3),
      );

      final json = model.toJson();
      expect(json['id'], 'svc-003');
      expect(json['freelancer_id'], 'user-789');
      expect(json['status'], 'active');
      expect(json['price'], 199.0);
    });

    test('toInsertJson excludes id, freelancer_id, created_at', () {
      final model = ServiceModel(
        id: 'svc-004',
        freelancerId: 'user-000',
        title: 'Copywriting',
        status: ServiceStatus.draft,
        createdAt: DateTime.utc(2026, 3, 5),
      );

      final json = model.toInsertJson();
      expect(json.containsKey('id'), false);
      expect(json.containsKey('freelancer_id'), false);
      expect(json.containsKey('created_at'), false);
      expect(json['title'], 'Copywriting');
      expect(json['status'], 'draft');
    });
  });

  group('ServiceModel.copyWith', () {
    final original = ServiceModel(
      id: 'svc-005',
      freelancerId: 'user-111',
      title: 'Original',
      status: ServiceStatus.draft,
      createdAt: DateTime.utc(2026),
    );

    test('updates only specified fields', () {
      final updated = original.copyWith(
        title: 'Updated',
        status: ServiceStatus.active,
      );

      expect(updated.title, 'Updated');
      expect(updated.status, ServiceStatus.active);
      expect(updated.id, original.id);
      expect(updated.freelancerId, original.freelancerId);
      expect(updated.createdAt, original.createdAt);
    });

    test('returns identical when no args', () {
      final copy = original.copyWith();
      expect(copy.title, original.title);
      expect(copy.status, original.status);
    });
  });
}
