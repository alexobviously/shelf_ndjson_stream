import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';

/// A controller that generates a streaming HTTP [response].
/// Use the [add] method to add ndjson data (`Map<String, dynamic>`) to it,
/// which will be pushed to the client. The connection will be kept open
/// until [close] is called.
class NdjsonStream {
  /// A HTTP status code. Defaults to 200. Probably 200.
  final int statusCode;

  NdjsonStream({
    this.statusCode = 200,
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

  /// Adds a message to the stream, which will be sent to the client through [response].
  void add(Map<String, dynamic> json) {
    String str = jsonEncode(json);
    List<int> charCodes = [...str.codeUnits, 10];
    _controller.add(charCodes);
  }

  /// Closes the stream, and consequently the connection to the client.
  void close() => _controller.close();
}
