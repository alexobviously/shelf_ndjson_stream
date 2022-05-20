## shelf_ndjson_stream

A wrapper for easily streaming ndjson responses from a shelf server.

* Create an `NdjsonStream` object.
* Return `stream.response` in a Shelf handler.
* Add messages to it with `stream.add()`.
* Don't forget to call `stream.close()`, or the connection will stay open forever (or likely produce some strange behaviour).