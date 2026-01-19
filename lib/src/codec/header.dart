part of 'codec.dart';

/// Metadata extracted from a Keep payload header without full decoding.
///
/// This lightweight structure contains essential information about a stored
/// value, allowing for efficient filtering and introspection.
class KeepHeader {
  /// Creates a header with the given metadata.
  KeepHeader({
    required this.storeName,
    required this.name,
    required this.flags,
    required this.version,
    required this.type,
  });

  /// The hashed storage key.
  final String storeName;

  /// The original key name.
  final String name;

  /// Metadata flags (removable, secure, etc.).
  final int flags;

  /// The codec version used to encode this value.
  final int version;

  /// The data type of the stored value.
  final KeepType type;
}
