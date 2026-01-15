part of 'key.dart';

/// A standard implementation of [KeepKey] that stores data as plain JSON.
///
/// [KeepKeyPlain] is the default key type used for most data that does not
/// require encryption. It handles both internal (in-memory) and external
/// (file-based) storage seamlessly.
class KeepKeyPlain<T> extends KeepKey<T> {
  /// Creates a [KeepKeyPlain].
  ///
  /// [name] is the unique identifier for this key.
  /// [removable] indicates if the key should be cleared by [Keep.clearRemovable].
  /// [useExternalStorage] indicates if the value should be stored in its own file.
  /// [storage] is an optional custom storage adapter for this specific key.
  KeepKeyPlain({
    required super.name,
    super.removable = false,
    super.useExternalStorage = false,
    super.storage,
  });

  @override
  KeepKeyPlain<T> call(Object? subKeyName) {
    final key = KeepKeyPlain<T>(
      name: '$name.$subKeyName',
      removable: removable,
      useExternalStorage: useExternalStorage,
      storage: storage,
    )..bind(keep);
    return key;
  }

  @override
  T? readSync() {
    try {
      return switch (useExternalStorage) {
        true => externalStorage.readSync(this),
        false => keep.internalStorage.readSync(this),
      };
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

  @override
  Future<T?> read() async {
    await keep.ensureInitialized;

    try {
      return switch (useExternalStorage) {
        true => await externalStorage.read(this),
        false => keep.internalStorage.read(this),
      };
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

  @override
  Future<void> write(T? value) async {
    await keep.ensureInitialized;
    keep.onChangeController.add(this);

    if (value == null) {
      await remove();
      return;
    }

    try {
      if (useExternalStorage) {
        await externalStorage.write(this, value);
      } else {
        await keep.internalStorage.write(this, value);
      }
    } catch (error, stackTrace) {
      final exception = toException(
        error.toString(),
        error: error,
        stackTrace: stackTrace,
      );

      keep.onError?.call(exception);

      throw exception;
    }
  }
}
