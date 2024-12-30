import 'dart:typed_data' as tp;
import 'package:postgres/community/platform_bit_handler.dart';

final class ByteData {
  final tp.ByteData bytes;
  final ByteBuffer _buffer;

  ByteData(int i)
      : bytes = tp.ByteData(i),
        _buffer = ByteBuffer(tp.ByteData(i));

  ByteData._wrap(this.bytes) : _buffer = ByteBuffer(bytes);

  ByteBuffer get buffer => _buffer;

  void setInt64(int i, int input) =>
      PlatformBitHandler.setInt64(bytes, i, input);
  int getInt64(int i) => PlatformBitHandler.getInt64(bytes, i);

  void setFloat64(int i, double input) =>
      PlatformBitHandler.setFloat64(bytes, i, input);
  double getFloat64(int i) => PlatformBitHandler.getFloat64(bytes, i);

  void setInt32(int i, int input) => bytes.setInt32(i, input);
  int getInt32(int i) => bytes.getInt32(i);

  void setFloat32(int i, double input) => bytes.setFloat32(i, input);
  double getFloat32(int i) => bytes.getFloat32(i);

  void setInt16(int i, int input) => bytes.setInt16(i, input);
  int getInt16(int i) => bytes.getInt16(i);

  void setInt8(int i, int j) => bytes.setInt8(i, j);
  int getInt8(int i) => bytes.getInt8(i);

  void setUint32(int i, int j) => bytes.setUint32(i, j);
  int getUint32(int i) => bytes.getUint32(i);

  void setUint8(int i, int j) => bytes.setUint8(i, j);
  int getUint8(int i) => bytes.getUint8(i);

  factory ByteData.view(tp.ByteBuffer buffer,
      [int offsetInBytes = 0, int? length]) {
    final viewedData = buffer.asByteData(offsetInBytes, length);
    return ByteData._wrap(viewedData);
  }

  int get lengthInBytes => bytes.lengthInBytes;
}

final class ByteBuffer {
  final tp.ByteData _data;

  ByteBuffer(this._data);

  tp.Uint8List asUint8List([int offsetInBytes = 0, int? length]) =>
      _data.buffer.asUint8List(_data.offsetInBytes + offsetInBytes,
          length ?? (_data.lengthInBytes - offsetInBytes));

  ByteData asByteData([int offsetInBytes = 0, int? length]) {
    final viewedData = _data.buffer.asByteData(
        _data.offsetInBytes + offsetInBytes,
        length ?? (_data.lengthInBytes - offsetInBytes));
    return ByteData._wrap(viewedData);
  }

  int get lengthInBytes => _data.lengthInBytes;
}
