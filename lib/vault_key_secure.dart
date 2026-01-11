part of 'vault.dart';

class VaultKeySecure<T> extends VaultKey<T> {
  VaultKeySecure({
    required super.name,
    required super.vault,
    required super.fromStorage,
    required super.toStorage,
    required super.removable,
    required super.useExternalStorage,
  });

  @override
  Future<T?> read() {
    return super.read();
  }

  @override
  Future<void> write(T value) {
    return super.write(value);
  }
}
