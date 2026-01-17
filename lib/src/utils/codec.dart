part of 'utils.dart';

/// Represents the type of a stored value in binary format.
enum KeepValueType {
  /// Unknown type.
  tUnknown(0),

  /// Integer type.
  tInt(1),

  /// Double type.
  tDouble(2),

  /// Boolean type.
  tBool(3),

  /// String type.
  tString(4),

  /// List type.
  tList(5),

  /// Map type.
  tMap(6)
  ;

  const KeepValueType(this.byte);

  /// The byte value used in binary encoding.
  final int byte;

  /// Returns the [KeepValueType] for the given [byte], or null if not found.
  static KeepValueType? fromByte(int byte) {
    for (final type in values) {
      if (type.byte == byte) return type;
    }
    return null;
  }

  /// Parses the raw [value] to the expected type.
  T? parse<T>(Object? value) {
    if (value == null) {
      return null;
    }

    if (this == tInt) {
      final parsed = value is int ? value : int.tryParse(value.toString());
      return parsed as T?;
    }

    if (this == tDouble) {
      final parsed = value is double
          ? value
          : (value is num
                ? value.toDouble()
                : double.tryParse(value.toString()));
      return parsed as T?;
    }

    if (this == tBool) {
      final parsed = value is bool ? value : (value == 'true' || value == 1);
      return parsed as T?;
    }

    if (this == tString) {
      return value.toString() as T?;
    }

    if (this == tList) {
      return (value is List ? value : null) as T?;
    }

    if (this == tMap) {
      return (value is Map ? value : null) as T?;
    }

    return null;
  }
}

/// Handles binary encoding and decoding of Keep data structures.
class KeepCodec {
  /// Flag bitmask for **Removable** keys (Bit 0).
  @internal
  static const int flagRemovable = 1;

  /// Indicates that the payload is encrypted.
  @internal
  static const int flagSecure = 2;

  /// Infers the [KeepValueType] from a dynamic value.
  static KeepValueType inferType(Object? value) {
    if (value is int) return .tInt;
    if (value is double) return .tDouble;
    if (value is bool) return .tBool;
    if (value is String) return .tString;
    if (value is List) return .tList;
    if (value is Map) return .tMap;
    return .tUnknown;
  }

  /// Encodes all entries into a single binary block (for Internal Storage).
  static Uint8List encodeAll(Map<String, KeepMemoryValue> entries) {
    final buffer = BytesBuilder();

    entries.forEach((key, entry) {
      final keyBytes = utf8.encode(key);
      if (keyBytes.length > 255) return;

      final jsonString = jsonEncode(entry.value);
      final valBytes = utf8.encode(jsonString);

      // [KeyLen] [Key] [Flags] [Version] [Type] [ValLen] [Value]
      buffer
        ..addByte(keyBytes.length)
        ..add(keyBytes)
        ..addByte(entry.flags)
        ..addByte(entry.version)
        ..addByte(entry.type.byte);

      final valLen = valBytes.length;
      buffer
        ..addByte((valLen >> 24) & 0xFF)
        ..addByte((valLen >> 16) & 0xFF)
        ..addByte((valLen >> 8) & 0xFF)
        ..addByte(valLen & 0xFF)
        // Add value
        ..add(valBytes);
    });

    return shiftBytes(buffer.toBytes());
  }

  /// Decodes a binary block into a map of entries (for Internal Storage).
  static Map<String, KeepMemoryValue> decodeAll(Uint8List bytes) {
    if (bytes.isEmpty) return {};

    final data = unShiftBytes(Uint8List.fromList(bytes));
    final map = <String, KeepMemoryValue>{};
    var offset = 0;

    while (offset < data.length) {
      if (offset + 1 > data.length) break;

      // 1. Read Key
      final keyLen = data[offset++];
      if (offset + keyLen > data.length) break;
      final key = utf8.decode(data.sublist(offset, offset + keyLen));
      offset += keyLen;

      // 2. Read Flags, Version & Type
      if (offset + 3 > data.length) break;
      final flags = data[offset++];
      final version = data[offset++];
      final type = data[offset++];

      // 3. Read Value Length
      if (offset + 4 > data.length) break;
      final valLen =
          ((data[offset] << 24) |
                  (data[offset + 1] << 16) |
                  (data[offset + 2] << 8) |
                  (data[offset + 3]))
              .toUnsigned(32);
      offset += 4;

      if (offset + valLen > data.length) break;

      // 4. Read Value
      final jsonString = utf8.decode(data.sublist(offset, offset + valLen));
      final value = jsonDecode(jsonString);
      offset += valLen;

      map[key] = KeepMigration.migrate(
        KeepMemoryValue(
          value,
          flags,
          version: version,
          type: KeepValueType.fromByte(type),
        ),
      );
    }

    return map;
  }

  /// Encodes a single payload (for External Storage).
  static Uint8List encodePayload(dynamic value, int flags) {
    final buffer = BytesBuilder();
    final jsonString = jsonEncode(value);
    final valBytes = utf8.encode(jsonString);

    // [Flags] [Version] [Type] [JSON]
    final type = inferType(value);
    buffer
      ..addByte(flags)
      ..addByte(Keep.version)
      ..addByte(type.byte)
      ..add(valBytes);

    return shiftBytes(buffer.toBytes());
  }

  /// Decodes a binary payload into a [KeepMemoryValue] (for External Storage).
  static KeepMemoryValue? decodePayload(Uint8List bytes) {
    if (bytes.isEmpty) {
      return null;
    }

    final data = unShiftBytes(bytes);
    if (data.length < 3) {
      return null;
    }

    final flags = data[0];
    final version = data[1];
    final type = data[2];

    try {
      final jsonBytes = data.sublist(3);
      final jsonString = utf8.decode(jsonBytes);
      final value = jsonDecode(jsonString);

      return KeepMigration.migrate(
        KeepMemoryValue(
          value,
          flags,
          version: version,
          type: KeepValueType.fromByte(type),
        ),
      );
    } catch (error, stackTrace) {
      final exception = KeepException<dynamic>(
        'Failed to decode payload',
        stackTrace: stackTrace,
        error: error,
      );

      throw exception;
    }
  }

  /// Generates a non-reversible hash for a given [key] name using DJB2.
  /// Used for obfuscating filenames and internal map keys.
  static String generateHash(String key) {
    final bytes = utf8.encode(key);
    var hash = 5381;
    for (final byte in bytes) {
      hash = ((hash << 5) + hash) + byte;
    }
    return hash.toUnsigned(64).toRadixString(36);
  }

  /// Obfuscates bytes using a bitwise left rotation (ROL 1).
  static Uint8List shiftBytes(Uint8List bytes) {
    for (var i = 0; i < bytes.length; i++) {
      final b = bytes[i];
      bytes[i] = ((b << 1) | (b >> 7)) & 0xFF;
    }
    return Uint8List.fromList(bytes);
  }

  /// Reverses the bitwise rotation obfuscation (ROR 1).
  static Uint8List unShiftBytes(Uint8List bytes) {
    for (var i = 0; i < bytes.length; i++) {
      final b = bytes[i];
      bytes[i] = ((b >> 1) | (b << 7)) & 0xFF;
    }
    return bytes;
  }
}
