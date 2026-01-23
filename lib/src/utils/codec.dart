part of 'utils.dart';

/// Utility mixin for codec operations.
mixin KeepCodecUtils {
  /// Obfuscates bytes using a bitwise left rotation (ROL 1).
  Uint8List shiftBytes(Uint8List bytes) {
    for (var i = 0; i < bytes.length; i++) {
      final b = bytes[i];
      bytes[i] = ((b << 1) | (b >> 7)) & 0xFF;
    }
    return bytes;
  }

  /// Reverses the bitwise rotation obfuscation (ROR 1).
  Uint8List unShiftBytes(Uint8List bytes) {
    for (var i = 0; i < bytes.length; i++) {
      final b = bytes[i];
      bytes[i] = ((b >> 1) | (b << 7)) & 0xFF;
    }
    return bytes;
  }

  /// Generates a non-reversible hash for a given [key] name using DJB2.
  /// Used for obfuscating filenames and internal map keys.
  String hash(String key) {
    final bytes = utf8.encode(key);

    var hash = 5381;
    for (final byte in bytes) {
      hash = ((hash << 5) + hash) + byte;
    }

    return hash.toUnsigned(64).toRadixString(36);
  }
}
