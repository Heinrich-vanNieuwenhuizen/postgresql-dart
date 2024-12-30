import 'dart:typed_data';

class PlatformBitHandler {
  static bool? _is32Bit;

  /// Detects if the current platform is 32-bit
  static bool is32Bit() {
    if (_is32Bit != null) return _is32Bit!;

    try {
      // Try to create a big number that only works on 64-bit systems
      final testNum = ByteData(8)..setInt64(0, (BigInt.from(1) << 63).toInt());
      print(testNum);
      _is32Bit = false;
    } catch (e) {
      _is32Bit = true;
    }

    return _is32Bit!;
  }

  /// Safely converts a 64-bit integer to a platform-appropriate size
  static int convertInt64ToCompatible(int value) {
    if (!is32Bit()) return value;

    // For 32-bit platforms, we need to handle potential overflow
    if (value > 2147483647 || value < -2147483648) {
      // Return max/min safe integer for 32-bit systems
      return value.isNegative ? -2147483648 : 2147483647;
    }

    return value;
  }

  /// Safely reads a 64-bit integer from ByteData for the current platform
  static int readInt64(ByteData data, int offset) {
    if (!is32Bit()) {
      try {
        return data.getInt64(offset);
      } catch (e) {
        // Fallback to 32-bit if 64-bit operation fails
        return _readInt64As32Bit(data, offset);
      }
    }
    return _readInt64As32Bit(data, offset);
  }

  /// Handles reading 64-bit integers on 32-bit platforms by splitting into two 32-bit integers
  static int _readInt64As32Bit(ByteData data, int offset) {
    final highBits = data.getInt32(offset);
    final lowBits = data.getInt32(offset + 4);

    // On 32-bit platforms, we'll return the lower 32 bits if the number is too large
    if (highBits == 0) {
      return lowBits;
    } else if (highBits == -1 && lowBits < 0) {
      return lowBits;
    }

    // Return max/min value based on sign
    return highBits < 0 ? -2147483648 : 2147483647;
  }

  /// Safely writes a 64-bit integer to ByteData for the current platform
  static void writeInt64(ByteData data, int offset, int value) {
    if (!is32Bit()) {
      try {
        data.setInt64(offset, value);
        return;
      } catch (e) {
        // Fallback to 32-bit if 64-bit operation fails
        _writeInt64As32Bit(data, offset, value);
      }
    } else {
      _writeInt64As32Bit(data, offset, value);
    }
  }

  /// Handles writing 64-bit integers on 32-bit platforms by splitting into two 32-bit integers
  static void _writeInt64As32Bit(ByteData data, int offset, int value) {
    if (value > 2147483647 || value < -2147483648) {
      // Handle overflow by writing max/min values
      final isNegative = value < 0;
      data.setInt32(offset, isNegative ? -1 : 0);
      data.setInt32(offset + 4, isNegative ? -2147483648 : 2147483647);
    } else {
      // For values within 32-bit range
      data.setInt32(offset, value < 0 ? -1 : 0);
      data.setInt32(offset + 4, value);
    }
  }

  /// Safely reads a 64-bit float from ByteData for the current platform
  static double readFloat64(ByteData data, int offset) {
    if (!is32Bit()) {
      try {
        return data.getFloat64(offset);
      } catch (e) {
        // Fallback to 32-bit if 64-bit operation fails
        return _readFloat64As32Bit(data, offset);
      }
    }
    return _readFloat64As32Bit(data, offset);
  }

  /// Handles reading 64-bit floats on 32-bit platforms by converting to 32-bit float
  static double _readFloat64As32Bit(ByteData data, int offset) {
    // Read the raw bytes as 32-bit floats
    final highFloat = data.getFloat32(offset);
    final lowFloat = data.getFloat32(offset + 4);

    // Combine the values, prioritizing the high bits for precision
    if (highFloat.abs() > 0) {
      return highFloat * (2 << 31) + lowFloat;
    }
    return lowFloat;
  }

  /// Safely writes a 64-bit float to ByteData for the current platform
  static void writeFloat64(ByteData data, int offset, double value) {
    if (!is32Bit()) {
      try {
        data.setFloat64(offset, value);
        return;
      } catch (e) {
        // Fallback to 32-bit if 64-bit operation fails
        _writeFloat64As32Bit(data, offset, value);
      }
    } else {
      _writeFloat64As32Bit(data, offset, value);
    }
  }

  /// Handles writing 64-bit floats on 32-bit platforms by splitting into two 32-bit floats
  static void _writeFloat64As32Bit(ByteData data, int offset, double value) {
    // Handle special cases
    if (value.isNaN) {
      data.setUint32(offset, 0x7FF80000); // NaN pattern
      data.setUint32(offset + 4, 0);
      return;
    }
    if (value.isInfinite) {
      if (value.isNegative) {
        data.setUint32(offset, 0xFFF00000); // -Infinity pattern
        data.setUint32(offset + 4, 0);
      } else {
        data.setUint32(offset, 0x7FF00000); // +Infinity pattern
        data.setUint32(offset + 4, 0);
      }
      return;
    }

    // Split the value into high and low parts
    final highPart = value / (2 << 31);
    final lowPart = value % (2 << 31);

    // Write as 32-bit floats
    data.setFloat32(offset, highPart);
    data.setFloat32(offset + 4, lowPart);
  }

  static void setInt64(ByteData bd, int i, int input) {
    if (is32Bit()) {
      _writeInt64As32Bit(bd, i, input);
    } else {
      bd.setInt64(i, input);
    }
  }

  static void setFloat64(ByteData bd, int i, double input) {
    if (is32Bit()) {
      _writeFloat64As32Bit(bd, i, input);
    } else {
      bd.setFloat64(i, input);
    }
  }

  static int getInt64(ByteData bytes, int i) {
    if (is32Bit()) {
      return _readInt64As32Bit(bytes, i);
    } else {
      return bytes.getInt64(i);
    }
  }

  static double getFloat64(ByteData bytes, int i) {
    if (is32Bit()) {
      return _readFloat64As32Bit(bytes, i);
    } else {
      return bytes.getFloat64(i);
    }
  }
}
