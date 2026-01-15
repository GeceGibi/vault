part of 'keep.dart';

/// Factory for creating typed [KeepKey] and [KeepKeySecure] instances.
///
/// Access via [Keep.key] to create storage keys with built-in serialization.
class KeepKeyManager {
  /// Creates a [KeepKeyManager] linked to a [keep].
  KeepKeyManager({required Keep keep}) : _keep = keep;
  final Keep _keep;

  /// Creates a standard [int] key.
  KeepKey<int> integer(
    String name, {
    bool removable = false,
    bool useExternalStorage = false,
  }) {
    return _keep._registerKey(
      name,
      () => KeepKey<int>(
        name: name,
        keep: _keep,
        removable: removable,
        useExternalStorage: useExternalStorage,
      ),
    );
  }

  /// Creates an encrypted [int] key using [KeepKeySecure].
  KeepKeySecure<int> integerSecure(
    String name, {
    bool removable = false,
    bool useExternalStorage = false,
  }) {
    return _keep._registerKey(
      KeepKeySecure.generateHash(name),
      () => KeepKeySecure<int>(
        name: name,
        keep: _keep,
        removable: removable,
        useExternalStorage: useExternalStorage,
        toStorage: (value) => value,
        fromStorage: (value) {
          return switch (value) {
            int() => value,
            String() => int.parse(value),
            _ => null,
          };
        },
      ),
    );
  }

  /// Creates a standard [String] key.
  KeepKey<String> string(
    String name, {
    bool removable = false,
    bool useExternalStorage = false,
  }) {
    return _keep._registerKey(
      name,
      () => KeepKey<String>(
        name: name,
        keep: _keep,
        removable: removable,
        useExternalStorage: useExternalStorage,
      ),
    );
  }

  /// Creates an encrypted [String] key using [KeepKeySecure].
  KeepKeySecure<String> stringSecure(
    String name, {
    bool removable = false,
    bool useExternalStorage = false,
  }) {
    return _keep._registerKey(
      KeepKeySecure.generateHash(name),
      () => KeepKeySecure<String>(
        name: name,
        keep: _keep,
        removable: removable,
        useExternalStorage: useExternalStorage,
        toStorage: (value) => value,
        fromStorage: (value) => value?.toString(),
      ),
    );
  }

  /// Creates a standard [bool] key.
  KeepKey<bool> boolean(
    String name, {
    bool removable = false,
    bool useExternalStorage = false,
  }) {
    return _keep._registerKey(
      name,
      () => KeepKey<bool>(
        name: name,
        keep: _keep,
        removable: removable,
        useExternalStorage: useExternalStorage,
      ),
    );
  }

  /// Creates an encrypted [bool] key using [KeepKeySecure].
  KeepKeySecure<bool> booleanSecure(
    String name, {
    bool removable = false,
    bool useExternalStorage = false,
  }) {
    return _keep._registerKey(
      KeepKeySecure.generateHash(name),
      () => KeepKeySecure<bool>(
        name: name,
        keep: _keep,
        removable: removable,
        useExternalStorage: useExternalStorage,
        toStorage: (value) => value,
        fromStorage: (value) {
          return switch (value) {
            bool() => value,
            String() => value == 'true',
            _ => null,
          };
        },
      ),
    );
  }

  /// Creates a standard [double] key.
  KeepKey<double> decimal(
    String name, {
    bool removable = false,
    bool useExternalStorage = false,
  }) {
    return _keep._registerKey(
      name,
      () => KeepKey<double>(
        name: name,
        keep: _keep,
        removable: removable,
        useExternalStorage: useExternalStorage,
      ),
    );
  }

  /// Creates an encrypted [double] key using [KeepKeySecure].
  KeepKeySecure<double> decimalSecure(
    String name, {
    bool removable = false,
    bool useExternalStorage = false,
  }) {
    return _keep._registerKey(
      KeepKeySecure.generateHash(name),
      () => KeepKeySecure<double>(
        name: name,
        keep: _keep,
        removable: removable,
        useExternalStorage: useExternalStorage,
        toStorage: (value) => value,
        fromStorage: (value) {
          return switch (value) {
            double() => value,
            int() => value.toDouble(),
            String() => double.parse(value),
            _ => null,
          };
        },
      ),
    );
  }

  /// Creates a [Map<String, dynamic>] key.
  KeepKey<Map<String, dynamic>> map(
    String name, {
    bool removable = false,
    bool useExternalStorage = false,
  }) {
    return _keep._registerKey(
      name,
      () => KeepKey<Map<String, dynamic>>(
        name: name,
        keep: _keep,
        removable: removable,
        useExternalStorage: useExternalStorage,
      ),
    );
  }

  /// Creates an encrypted [Map<String, dynamic>] key.
  KeepKeySecure<Map<String, dynamic>> mapSecure(
    String name, {
    bool removable = false,
    bool useExternalStorage = false,
  }) {
    return _keep._registerKey(
      KeepKeySecure.generateHash(name),
      () => KeepKeySecure<Map<String, dynamic>>(
        name: name,
        keep: _keep,
        removable: removable,
        useExternalStorage: useExternalStorage,
        toStorage: (value) => value,
        fromStorage: (value) {
          return switch (value) {
            Map() => value.cast<String, dynamic>(),
            _ => null,
          };
        },
      ),
    );
  }

  /// Creates a [List<T>] key.
  KeepKey<List<T>> list<T>(
    String name, {
    bool removable = false,
    bool useExternalStorage = false,
  }) {
    return _keep._registerKey(
      name,
      () => KeepKey<List<T>>(
        name: name,
        keep: _keep,
        removable: removable,
        useExternalStorage: useExternalStorage,
      ),
    );
  }

  /// Creates an encrypted [List<T>] key.
  KeepKeySecure<List<T>> listSecure<T>(
    String name, {
    bool removable = false,
    bool useExternalStorage = false,
  }) {
    return _keep._registerKey(
      KeepKeySecure.generateHash(name),
      () => KeepKeySecure<List<T>>(
        name: name,
        keep: _keep,
        removable: removable,
        useExternalStorage: useExternalStorage,
        toStorage: (value) => value,
        fromStorage: (value) {
          return switch (value) {
            List() => value.cast<T>(),
            _ => null,
          };
        },
      ),
    );
  }

  /// Creates a custom encrypted key with serialization.
  KeepKeySecure<T> custom<T>({
    required String name,
    required T? Function(Object? value) fromStorage,
    required Object? Function(T value) toStorage,
    bool removable = false,
    bool useExternalStorage = false,
  }) {
    return _keep._registerKey(
      KeepKeySecure.generateHash(name),
      () => KeepKeySecure<T>(
        name: name,
        keep: _keep,
        removable: removable,
        useExternalStorage: useExternalStorage,
        toStorage: toStorage,
        fromStorage: fromStorage,
      ),
    );
  }
}
