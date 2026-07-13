import 'dart:convert';
import 'dart:typed_data';

/// Sequential binary writer with explicit endianness per field.
///
/// Engine DJ performance-data blobs mix big-endian headers with little-endian
/// payload fields, so every write method spells out its endianness.
class ByteWriter {
  final BytesBuilder _builder = BytesBuilder();
  final ByteData _scratch = ByteData(8);

  void u8(int value) => _builder.addByte(value);

  void i32be(int value) {
    _scratch.setInt32(0, value);
    _builder.add(_scratch.buffer.asUint8List(0, 4).toList());
  }

  void i32le(int value) {
    _scratch.setInt32(0, value, Endian.little);
    _builder.add(_scratch.buffer.asUint8List(0, 4).toList());
  }

  void i64be(int value) {
    _scratch.setInt64(0, value);
    _builder.add(_scratch.buffer.asUint8List(0, 8).toList());
  }

  void i64le(int value) {
    _scratch.setInt64(0, value, Endian.little);
    _builder.add(_scratch.buffer.asUint8List(0, 8).toList());
  }

  void f64be(double value) {
    _scratch.setFloat64(0, value);
    _builder.add(_scratch.buffer.asUint8List(0, 8).toList());
  }

  void f64le(double value) {
    _scratch.setFloat64(0, value, Endian.little);
    _builder.add(_scratch.buffer.asUint8List(0, 8).toList());
  }

  /// Writes [label] as a single length byte followed by its UTF-8 bytes.
  void label(String label) {
    final bytes = utf8.encode(label);
    if (bytes.length > 255) {
      throw ArgumentError('Label too long for a single length byte: $label');
    }
    u8(bytes.length);
    _builder.add(bytes);
  }

  Uint8List takeBytes() => _builder.takeBytes();
}

/// Sequential binary reader mirroring [ByteWriter].
class ByteReader {
  ByteReader(Uint8List bytes)
    : _data = ByteData.sublistView(bytes),
      _length = bytes.length;

  final ByteData _data;
  final int _length;
  int _offset = 0;

  int get remaining => _length - _offset;

  int u8() => _data.getUint8(_offset++);

  int i32be() {
    final v = _data.getInt32(_offset);
    _offset += 4;
    return v;
  }

  int i32le() {
    final v = _data.getInt32(_offset, Endian.little);
    _offset += 4;
    return v;
  }

  int i64be() {
    final v = _data.getInt64(_offset);
    _offset += 8;
    return v;
  }

  int i64le() {
    final v = _data.getInt64(_offset, Endian.little);
    _offset += 8;
    return v;
  }

  double f64be() {
    final v = _data.getFloat64(_offset);
    _offset += 8;
    return v;
  }

  double f64le() {
    final v = _data.getFloat64(_offset, Endian.little);
    _offset += 8;
    return v;
  }

  /// Reads a length-prefixed UTF-8 label written by [ByteWriter.label].
  String label() {
    final length = u8();
    final bytes = Uint8List.sublistView(_data, _offset, _offset + length);
    _offset += length;
    return utf8.decode(bytes);
  }
}
