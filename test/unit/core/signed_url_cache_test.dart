import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/utils/signed_url_cache.dart';

void main() {
  group('SignedUrlCache T40-T41', () {
    setUp(() {
      SignedUrlCache.clear();
    });

    tearDown(() {
      SignedUrlCache.clear();
    });

    test('T40 SignedUrlCache set/get hit path', () {
      const path = 'task-images/user-1/task-1/image.jpg';
      const url = 'https://example.com/signed-url';

      SignedUrlCache.set(path, url);

      expect(SignedUrlCache.get(path), url);
      expect(SignedUrlCache.size, 1);
    });

    test('T41 SignedUrlCache expired entry returns null and evicts', () {
      const path = 'task-images/user-2/task-2/expired.jpg';
      const url = 'https://example.com/expired-signed-url';

      SignedUrlCache.set(path, url, duration: const Duration(milliseconds: -1));

      expect(SignedUrlCache.get(path), isNull);
      expect(SignedUrlCache.size, 0);
    });
  });
}
