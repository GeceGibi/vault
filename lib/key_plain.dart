part of 'keep.dart';

/// A standard implementation of [KeepKey] that stores data as plain JSON.
///
/// [KeepKeyPlain] is the default key type used for most data that does not
/// require encryption. It handles both internal (in-memory) and external
/// (file-based) storage seamlessly.
class KeepKeyPlain<T> extends KeepKey<T> {
  /// Creates a [KeepKeyPlain].
  KeepKeyPlain({
    required super.name,
    required super.keep,
    super.removable = false,
    super.useExternalStorage = false,
  });

  @override
  KeepKeyPlain<T> call(Object? subKeyName) {
    return KeepKeyPlain<T>(
      name: '$name.$subKeyName',
      removable: removable,
      keep: keep,
      useExternalStorage: useExternalStorage,
    );
  }

  @override
  T? readSync() {
    try {
      return switch (useExternalStorage) {
        true => keep.external.readSync(this),
        false => keep.internal.readSync(this),
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
    await keep._ensureInitialized;

    try {
      return switch (useExternalStorage) {
        true => await keep.external.read(this),
        false => keep.internal.read(this),
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
    await keep._ensureInitialized;
    keep._controller.add(this);

    if (value == null) {
      await remove();
      return;
    }

    try {
      if (useExternalStorage) {
        await keep.external.write(this, value);
      } else {
        await keep.internal.write(this, value);
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
