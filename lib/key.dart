part of 'keep.dart';

/// Represents a typed key within the [Keep].
class KeepKey<T> extends Stream<KeepKey<T>> {
  /// Creates a [KeepKey].
  ///
  /// [name] Unique identifier for the key.
  /// [keep] The keep instance this key belongs to.
  /// [removable] If true, this key can be cleared during mass operations.
  /// [useExternalStorage] If true, values are stored in individual files.
  KeepKey({
    required this.name,
    required this.keep,
    this.removable = false,
    this.useExternalStorage = false,
  });

  /// The keep instance this key belongs to.
  final Keep keep;

  /// The unique name/path of this key.
  final String name;

  /// Whether this key is removable during mass operations.
  final bool removable;

  /// Whether this key uses its own file for storage.
  final bool useExternalStorage;

  /// Creates a sub-key by appending [subKeyName] to current [name].
  KeepKey<T> call(Object? subKeyName) {
    return KeepKey<T>(
      name: '$name.$subKeyName',
      removable: removable,
      keep: keep,
      useExternalStorage: useExternalStorage,
    );
  }

  /// Returns true if this key currently exists in storage.
  FutureOr<bool> get exists async {
    await keep._ensureInitialized;

    try {
      if (useExternalStorage) {
        return keep.external.exists(this);
      }

      return keep.internal.exists(this);
    } catch (e, s) {
      final exception = toException(
        e.toString(),
        error: e,
        stackTrace: s,
      );

      keep.onError?.call(exception);

      throw exception;
    }
  }

  /// Synchronously checks if this key currently exists in storage.
  bool get existsSync {
    try {
      if (useExternalStorage) {
        return keep.external.existsSync(this);
      }

      return keep.internal.existsSync(this);
    } catch (e, s) {
      final exception = toException(
        e.toString(),
        error: e,
        stackTrace: s,
      );

      keep.onError?.call(exception);

      throw exception;
    }
  }

  /// Removes this key from storage.
  Future<void> remove() async {
    await keep._ensureInitialized;

    try {
      if (useExternalStorage) {
        await keep.external.remove(this);
      } else {
        keep.internal.remove(this);
      }
    } catch (e, s) {
      final exception = toException(
        e.toString(),
        error: e,
        stackTrace: s,
      );

      keep.onError?.call(exception);

      throw exception;
    }
  }

  /// Reads the value and returns [defaultValue] if not found.
  Future<T> readSafe(T defaultValue) async {
    return (await read()) ?? defaultValue;
  }

  /// Synchronously reads the value and returns [defaultValue] if not found.
  ///
  /// See [readSync] for warnings.
  T readSafeSync(T defaultValue) {
    return readSync() ?? defaultValue;
  }

  /// Synchronously reads the value from storage.
  ///
  /// **WARNING:** This method assumes the keep is already initialized.
  /// Calling this before [init] completes may throw an error or cause unexpected behavior.
  /// For external storage, this performs a blocking I/O operation.
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

  /// Reads the value from storage.
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

  /// Writes the [value] to storage.
  ///
  /// If [value] is null, the key is removed.
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
        keep.internal.write(this, value);
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

  /// Atomically updates the stored value using [updateFn].
  Future<void> update(T Function(T? currentValue) updateFn) async {
    try {
      final currentValue = await read();
      final newValue = updateFn(currentValue);
      await write(newValue);
    } on KeepException<T> catch (e) {
      keep.onError?.call(e);
      rethrow;
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

  /// Creates a [KeepException] for this key with the given [message].
  KeepException<T> toException(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    return KeepException(
      message,
      key: this,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  StreamSubscription<KeepKey<T>> listen(
    void Function(KeepKey<T> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return keep.onChange
        .where((key) => key.name == name)
        .cast<KeepKey<T>>()
        .listen(
          onData,
          onError: onError,
          onDone: onDone,
          cancelOnError: cancelOnError,
        );
  }
}
