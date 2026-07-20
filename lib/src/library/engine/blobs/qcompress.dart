import 'dart:io';
import 'dart:typed_data';

/// Compresses [data] using Qt's `qCompress` framing, as used by Engine DJ's
/// compressed performance-data blobs: a 4-byte big-endian uncompressed length
/// followed by a zlib stream.
Uint8List qCompress(Uint8List data) {
  final header = ByteData(4)..setUint32(0, data.length);
  final builder = BytesBuilder()
    ..add(header.buffer.asUint8List())
    ..add(zlib.encode(data));
  return builder.takeBytes();
}

/// Decompresses a `qCompress`-framed blob. Returns an empty list for an empty
/// blob or a zero apparent size, matching libdjinterop's behavior.
Uint8List qUncompress(Uint8List blob) {
  if (blob.isEmpty) return Uint8List(0);
  if (blob.length < 4) {
    throw const FormatException(
      'Compressed data is less than the minimum size of 4 bytes',
    );
  }

  final apparentSize = ByteData.sublistView(blob, 0, 4).getUint32(0);
  if (apparentSize == 0) return Uint8List(0);

  return Uint8List.fromList(zlib.decode(blob.sublist(4)));
}
