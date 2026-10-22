# shelf_ndjson_stream

A wrapper for easily streaming newline-delimited JSON (`application/x-ndjson`) responses from a Shelf server.

* Create an `NdjsonStream` object.
* Return `stream.response` in a Shelf handler.
* Add messages to it with `stream.add()`.
* Don't forget to call `stream.close()`, or the connection will stay open forever (or likely produce some strange behaviour).


## Usage
Run a server that looks like this:

```dart
import 'dart:async';
import 'package:shelf/shelf.dart';
import 'package:shelf_ndjson_stream/shelf_ndjson_stream.dart';

Response streamedHandler(Request request) {
  final stream = NdjsonStream(initialMessage: {'status': 'connected'});
  // Push messages asynchronously
  _sendEvents(stream);
  // Return the Response immediately
  return stream.response;
}

void _sendEvents(NdjsonStream stream) async {
  for (int i = 1; i <= 5; i++) {
    await Future.pause(const Duration(seconds: 1));
    stream.add({'hello': 'world', 'count': i});
  }
  // Close the stream when done to terminate the client connection
  stream.close();
}
```

Then `curl http://0.0.0.0:8080` and you'll see incremental counts and the stream eventually terminating.

## Details
- Sets `content-type: application/x-ndjson`.
- Disables output buffering (`shelf.io.buffer_output: false`) so chunks flush to clients immediately.
- UTF-8 encoding support for emojis and multi-byte characters.
- Custom headers, context, and status codes supported.