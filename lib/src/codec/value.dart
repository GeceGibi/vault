part of 'codec.dart';

class KeepKeyValue extends KeepKeyHeader {
  KeepKeyValue({
    required this.value,
    required super.name,
    required super.flags,
    required super.version,
    required super.type,
    required super.storeName,
  });

  /// Parses a [KeepKeyValue] from raw bytes, automatically detecting codec version.
  static KeepKeyValue? fromBytes(Uint8List bytes) {
    return KeepCodec.of(bytes).decode();
  }

  final Object? value;
}
