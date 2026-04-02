// Schema ref: messages.payload JSONB column — see Sline_everything/SUPABASE_SETUP.md
// Tests ChatOfferPayload.fromJson, toMap, daysFromPayload, and type coercion.

import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/features/chat/models/chat_offer_payload.dart';

Map<String, dynamic> _offerJson({Map<String, dynamic>? overrides}) {
  final base = <String, dynamic>{
    'price': 50000,
    'days': 7,
    'title': 'Logo Design',
    'description': 'A professional logo',
    'status': 'pending',
  };
  if (overrides != null) {
    base.addAll(overrides);
  }
  return base;
}

void main() {
  // ---------------------------------------------------------------------------
  // fromJson — basic parsing
  // ---------------------------------------------------------------------------
  group('ChatOfferPayload.fromJson basic', () {
    test('parses all fields from valid JSON', () {
      final p = ChatOfferPayload.fromJson(_offerJson());

      expect(p.price, 50000);
      expect(p.days, 7);
      expect(p.title, 'Logo Design');
      expect(p.description, 'A professional logo');
      expect(p.status, 'pending');
    });

    test('status defaults to pending when missing', () {
      final p = ChatOfferPayload.fromJson(
        _offerJson(overrides: {'status': null}),
      );
      expect(p.status, 'pending');
    });

    test('title and description are nullable', () {
      final json = <String, dynamic>{'price': 1000, 'days': 3};
      final p = ChatOfferPayload.fromJson(json);

      expect(p.title, isNull);
      expect(p.description, isNull);
      expect(p.status, 'pending');
    });
  });

  // ---------------------------------------------------------------------------
  // fromJson — price type coercion
  // ---------------------------------------------------------------------------
  group('ChatOfferPayload.fromJson price coercion', () {
    test('price as int', () {
      final p = ChatOfferPayload.fromJson(_offerJson(overrides: {'price': 42}));
      expect(p.price, 42);
    });

    test('price as num (double) is parsed via toString', () {
      // json['price'] is double => not int branch => int.tryParse('25000.0')
      // int.tryParse('25000.0') returns null => defaults to 0
      // This is the actual model behavior for a double price.
      final p = ChatOfferPayload.fromJson(
        _offerJson(overrides: {'price': 25000.0}),
      );
      expect(p.price, 0); // double.toString() = '25000.0', tryParse fails
    });

    test('price as String (numeric)', () {
      final p = ChatOfferPayload.fromJson(
        _offerJson(overrides: {'price': '9999'}),
      );
      expect(p.price, 9999);
    });

    test('price as non-numeric String defaults to 0', () {
      final p = ChatOfferPayload.fromJson(
        _offerJson(overrides: {'price': 'abc'}),
      );
      expect(p.price, 0);
    });

    test('price as null defaults to 0', () {
      final p = ChatOfferPayload.fromJson(
        _offerJson(overrides: {'price': null}),
      );
      expect(p.price, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // fromJson — days logic (prefers 'days' over legacy 'delivery')
  // ---------------------------------------------------------------------------
  group('ChatOfferPayload.fromJson days/delivery fallback', () {
    test('uses days when present', () {
      final p = ChatOfferPayload.fromJson(_offerJson(overrides: {'days': 14}));
      expect(p.days, 14);
    });

    test('falls back to delivery when days is absent', () {
      final json = <String, dynamic>{'price': 1000, 'delivery': 5};
      final p = ChatOfferPayload.fromJson(json);
      expect(p.days, 5);
    });

    test('days takes priority over delivery when both present', () {
      final json = <String, dynamic>{'price': 1000, 'days': 10, 'delivery': 20};
      final p = ChatOfferPayload.fromJson(json);
      expect(p.days, 10);
    });

    test('both missing yields days=0', () {
      final json = <String, dynamic>{'price': 1000};
      final p = ChatOfferPayload.fromJson(json);
      expect(p.days, 0);
    });

    test('days as String parses correctly', () {
      final p = ChatOfferPayload.fromJson(
        _offerJson(overrides: {'days': '21'}),
      );
      expect(p.days, 21);
    });

    test('delivery as String parses correctly', () {
      final json = <String, dynamic>{'price': 1000, 'delivery': '15'};
      final p = ChatOfferPayload.fromJson(json);
      expect(p.days, 15);
    });

    test('non-numeric days String defaults to 0', () {
      final p = ChatOfferPayload.fromJson(
        _offerJson(overrides: {'days': 'xyz'}),
      );
      expect(p.days, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // daysFromPayload static helper
  // ---------------------------------------------------------------------------
  group('ChatOfferPayload.daysFromPayload', () {
    test('returns 0 for null payload', () {
      expect(ChatOfferPayload.daysFromPayload(null), 0);
    });

    test('returns 0 for empty map', () {
      expect(ChatOfferPayload.daysFromPayload({}), 0);
    });

    test('prefers days over delivery', () {
      expect(ChatOfferPayload.daysFromPayload({'days': 3, 'delivery': 99}), 3);
    });

    test('falls back to delivery', () {
      expect(ChatOfferPayload.daysFromPayload({'delivery': 8}), 8);
    });

    test('handles String values in days', () {
      expect(ChatOfferPayload.daysFromPayload({'days': '12'}), 12);
    });

    test('handles String values in delivery', () {
      expect(ChatOfferPayload.daysFromPayload({'delivery': '6'}), 6);
    });
  });

  // ---------------------------------------------------------------------------
  // toMap — canonical wire format
  // ---------------------------------------------------------------------------
  group('ChatOfferPayload.toMap', () {
    test('writes days NOT delivery', () {
      final p = ChatOfferPayload.fromJson(_offerJson());
      final map = p.toMap();

      expect(map.containsKey('days'), isTrue);
      expect(map.containsKey('delivery'), isFalse);
      expect(map['days'], 7);
    });

    test('includes price and status', () {
      final p = ChatOfferPayload.fromJson(_offerJson());
      final map = p.toMap();

      expect(map['price'], 50000);
      expect(map['status'], 'pending');
    });

    test('includes title and description only when non-null', () {
      final p = ChatOfferPayload.fromJson(_offerJson());
      final map = p.toMap();

      expect(map['title'], 'Logo Design');
      expect(map['description'], 'A professional logo');
    });

    test('omits title and description when null', () {
      final p = ChatOfferPayload.fromJson(<String, dynamic>{
        'price': 100,
        'days': 1,
      });
      final map = p.toMap();

      expect(map.containsKey('title'), isFalse);
      expect(map.containsKey('description'), isFalse);
    });

    test('round-trip: fromJson -> toMap -> fromJson preserves data', () {
      final original = ChatOfferPayload.fromJson(_offerJson());
      final map = original.toMap();
      final restored = ChatOfferPayload.fromJson(map);

      expect(restored.price, original.price);
      expect(restored.days, original.days);
      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.status, original.status);
    });
  });
}
