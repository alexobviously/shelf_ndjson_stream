import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_ndjson_stream/shelf_ndjson_stream.dart';

Future<void> main() async {
  final handler = const Pipeline().addMiddleware(logRequests()).addHandler(_streamedResponse);

  final server = await shelf_io.serve(
    handler,
    InternetAddress.anyIPv4,
    8080,
  );

  print('Serving at http://${server.address.host}:${server.port}');
}

Response _streamedResponse(Request request) {
  NdjsonStream stream = NdjsonStream(initialMessage: {'counter': 0});
  _doStuffWithStream(stream);
  return stream.response;
}

void _doStuffWithStream(NdjsonStream stream) async {
  for (int i = 1; i <= 20; i++) {
    stream.add({'counter': i});
    await Future.delayed(Duration(milliseconds: 200));
  }
  stream.close();
}
