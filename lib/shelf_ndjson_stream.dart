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
  final StreamController<List<int>> _controller;
  final Response response;

  NdjsonStream._(this.statusCode, this._controller, this.response);

  factory NdjsonStream({
    int statusCode = 200,
    Map<String, Object>? headers,
    Map<String, Object>? context,
    Map<String, dynamic>? initialMessage,
  }) {
    final controller = StreamController<List<int>>();
    final response = Response(
      statusCode,
      body: controller.stream,
      headers: {
        ...?headers,
        'content-type': 'application/x-ndjson',
      },
      context: {
        ...?context,
        'shelf.io.buffer_output': false,
      },
    );

    final stream = NdjsonStream._(statusCode, controller, response);
    if (initialMessage != null) stream.add(initialMessage);

    return stream;
  }

  /// Adds a message to the stream, which will be sent to the client through [response].
  void add(Map<String, dynamic> json) {
    String str = jsonEncode(json);
    _controller.add(utf8.encode('$str\n'));
  }

  /// Closes the stream, and consequently the connection to the client.
  Future<void> close() async => await _controller.close();
}
