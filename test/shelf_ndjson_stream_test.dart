import 'dart:convert';

import 'package:shelf_ndjson_stream/shelf_ndjson_stream.dart';
import 'package:test/test.dart';

void main() {
  group('NdjsonStream regression tests', () {
    test(
        'regression: multi-byte UTF-8 characters are properly encoded and decoded',
        () async {
      final stream = NdjsonStream();
      final unicodePayload = {
        'greeting': 'こんにちは',
        'emoji': '🚀🔥',
        'accent': 'Café',
        'frank': '欢迎来到稻田，你个混蛋',
      };

      stream.add(unicodePayload);
      stream.close();

      // Read chunks from shelf response body
      final bytes =
          await stream.response.read().expand((chunk) => chunk).toList();

      // Verify bytes are valid UTF-8 (must not throw FormatException)
      // and match the original object after deserialization
      final decodedString = utf8.decode(bytes);
      final lines = decodedString.trim().split('\n');
      expect(lines.length, equals(1));

      final parsed = jsonDecode(lines.first) as Map<String, dynamic>;
      expect(parsed, equals(unicodePayload));
    });
  });
}
