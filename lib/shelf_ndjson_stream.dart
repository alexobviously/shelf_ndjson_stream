import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';

class NdjsonStream {
  final int statusCode;

  NdjsonStream(
    this.statusCode, {
    Map<String, Object>? headers,
    Map<String, Object>? context,
    Map<String, dynamic>? initialMessage,
  }) {
    _controller = StreamController();
    headers ??= {};
    headers['content-type'] = 'application/x-ndjson';
    context ??= {};
    context['shelf.io.buffer_output'] = false;
    response = Response(
      statusCode,
      body: _controller.stream,
      headers: headers,
      context: context,
    );
    if (initialMessage != null) add(initialMessage);
  }

  late StreamController<List<int>> _controller;
  late Response response;

  void add(Map<String, dynamic> json) {
    String str = jsonEncode(json);
    List<int> charCodes = [...str.codeUnits, 10];
    _controller.add(charCodes);
  }

  void close() => _controller.close();
}
