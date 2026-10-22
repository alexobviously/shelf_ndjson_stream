import 'dart:convert';

import 'package:shelf_ndjson_stream/shelf_ndjson_stream.dart';
import 'package:test/test.dart';

void main() {
  group('NdjsonStream configuration', () {
    test('uses default status code, content-type header, and buffer context', () async {
      final stream = NdjsonStream();
      stream.close();
      await stream.response.read().drain();

      expect(stream.statusCode, equals(200));
      expect(stream.response.statusCode, equals(200));
      expect(
        stream.response.headers['content-type'],
        equals('application/x-ndjson'),
      );
      expect(
        stream.response.context['shelf.io.buffer_output'],
        equals(false),
      );
    });

    test('preserves custom status code, custom headers, and custom context', () async {
      final stream = NdjsonStream(
        statusCode: 201,
        headers: {'x-custom-header': 'test-value'},
        context: {'custom.key': 42},
      );
      stream.close();
      await stream.response.read().drain();

      expect(stream.statusCode, equals(201));
      expect(stream.response.statusCode, equals(201));
      expect(
        stream.response.headers['x-custom-header'],
        equals('test-value'),
      );
      expect(
        stream.response.headers['content-type'],
        equals('application/x-ndjson'),
      );
      expect(stream.response.context['custom.key'], equals(42));
      expect(
        stream.response.context['shelf.io.buffer_output'],
        equals(false),
      );
    });
  });

  group('NdjsonStream streaming behavior', () {
    test('emits initialMessage as the first item if provided', () async {
      final stream = NdjsonStream(initialMessage: {'status': 'ready'});
      stream.close();

      final lines = await _readLines(stream);
      expect(lines, hasLength(1));
      expect(jsonDecode(lines.first), equals({'status': 'ready'}));
    });

    test('emits multiple messages in FIFO sequence delimited by newlines', () async {
      final stream = NdjsonStream();

      stream.add({'step': 1, 'message': 'first'});
      stream.add({'step': 2, 'message': 'second'});
      stream.add({'step': 3, 'message': 'third'});
      stream.close();

      final lines = await _readLines(stream);
      expect(lines, hasLength(3));
      expect(
        lines.map((l) => jsonDecode(l) as Map<String, dynamic>).toList(),
        equals([
          {'step': 1, 'message': 'first'},
          {'step': 2, 'message': 'second'},
          {'step': 3, 'message': 'third'},
        ]),
      );
    });

    test('emits empty body when closed without messages', () async {
      final stream = NdjsonStream();
      stream.close();

      final bytes =
          await stream.response.read().expand((chunk) => chunk).toList();
      expect(bytes, isEmpty);
    });

    test('regression: multi-byte UTF-8 characters are properly encoded and decoded', () async {
      final stream = NdjsonStream();
      final unicodePayload = {
        'greeting': 'こんにちは',
        'emoji': '🚀🔥',
        'accent': 'Café',
        'frank': '欢迎来到稻田，你个混蛋',
      };

      stream.add(unicodePayload);
      stream.close();

      final lines = await _readLines(stream);
      expect(lines, hasLength(1));
      expect(jsonDecode(lines.first), equals(unicodePayload));
    });
  });
}

Future<List<String>> _readLines(NdjsonStream stream) async {
  final bytes = await stream.response.read().expand((chunk) => chunk).toList();
  final decoded = utf8.decode(bytes);
  return decoded.trim().isEmpty ? [] : decoded.trim().split('\n');
}
