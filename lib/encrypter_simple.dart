part of 'vault.dart';

/// Default XOR-based implementation of [VaultEncrypter].
///
/// This provides basic obfuscation (not strong encryption).
/// For sensitive data, implement [VaultEncrypter] with AES-GCM or use
/// platform-native secure storage.
class SimpleVaultEncrypter extends VaultEncrypter {
  /// Creates a [SimpleVaultEncrypter] with a [secureKey].
  SimpleVaultEncrypter({required this.secureKey});

  /// The key used for XOR obfuscation.
  final String secureKey;

  @override
  Future<void> init() async {}

  @override
  String encrypt(Object? value) {
    final text = jsonEncode(value);
    final result = <int>[];
    for (var i = 0; i < text.length; i++) {
      result.add(
        text.codeUnitAt(i) ^ secureKey.codeUnitAt(i % secureKey.length),
      );
    }
    return base64Encode(result);
  }

  @override
  String decrypt(String value) {
    final bytes = base64Decode(value);
    final result = <int>[];
    for (var i = 0; i < bytes.length; i++) {
      result.add(bytes[i] ^ secureKey.codeUnitAt(i % secureKey.length));
    }
    return String.fromCharCodes(result);
  }
}
