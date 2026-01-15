part of 'keep.dart';

/// A specialized [KeepKey] that automatically encrypts and decrypts data
/// using the keep's [KeepEncrypter].
///
/// The key name is hashed with DJB2 for path obfuscation.
class KeepKeySecure<T> extends KeepKey<T> {
  /// Creates a [KeepKeySecure].
  KeepKeySecure({
    required super.name,
    required super.keep,
    required this.fromStorage,
    required this.toStorage,
    super.removable,
    super.useExternalStorage,
  });

  /// Converts raw storage data to typed object [T].
  final T? Function(Object? value) fromStorage;

  /// Converts typed object [T] to raw storage data.
  final Object? Function(T value) toStorage;

  /// Generates the hashed name for a given [key].
  static String generateHash(String key) {
    final bytes = utf8.encode(key);
    var hash = 5381; // DJB2 starting value

    for (final byte in bytes) {
      // (hash * 33) + byte
      hash = ((hash << 5) + hash) + byte;
    }

    // Avoid negative by converting to unsigned 64-bit and radix-36
    return hash.toUnsigned(64).toRadixString(36);
  }

  /// Returns key name hashed with DJB2 for path obscuring.
  String get hashedName => generateHash(super.name);

  @override
  String get name => hashedName;

  @override
  T? readSync() {
    try {
      final encryptedData = switch (useExternalStorage) {
        true => keep.external.readSync<String>(this),
        false => keep.internal.readSync<String>(this),
      };

      if (encryptedData == null) {
        return null;
      }

      final decrypted = keep.encrypter.decryptSync(encryptedData);
      return fromStorage(jsonDecode(decrypted));
    } catch (error, stackTrace) {
      final exception = toException(
        error.toString(),
        error: error,
        stackTrace: stackTrace,
      );

      keep.onError?.call(exception);
      unawaited(remove());
      return null;
    }
  }

  /// Reads, decrypts, and deserializes the value from storage.
  @override
  Future<T?> read() async {
    await keep._ensureInitialized;

    try {
      final encryptedData = switch (useExternalStorage) {
        true => await keep.external.read<String>(this),
        false => await keep.internal.read<String>(this),
      };

      if (encryptedData == null) {
        return null;
      }

      final decrypted = await keep.encrypter.decrypt(encryptedData);
      return fromStorage(await compute(jsonDecode, decrypted));
    } catch (error, stackTrace) {
      final exception = toException(
        error.toString(),
        error: error,
        stackTrace: stackTrace,
      );

      keep.onError?.call(exception);

      unawaited(remove());
      return null;
    }
  }

  /// Serializes, encrypts, and writes the value to storage.
  @override
  Future<void> write(T? value) async {
    await keep._ensureInitialized;

    if (value == null) {
      await remove();
      return;
    }
    final storageValue = toStorage(value);

    final encrypted = await keep.encrypter.encrypt(
      await compute(jsonEncode, storageValue),
    );

    keep._controller.add(this);

    if (useExternalStorage) {
      await keep.external.write(this, encrypted);
    } else {
      keep.internal.write(this, encrypted);
    }
  }
}
