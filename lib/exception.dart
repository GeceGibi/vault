part of 'vault.dart';

/// Exception thrown when a vault operation fails.
class VaultException<T> implements Exception {
  /// Creates a [VaultException].
  const VaultException(this.message, {this.key, this.error, this.stackTrace});

  /// The error message.
  final String message;

  /// The associated [VaultKey], if any.
  final VaultKey<T>? key;

  /// The underlying error object.
  final Object? error;

  /// The stack trace where the error occurred.
  final StackTrace? stackTrace;

  @override
  String toString() {
    final buffer = StringBuffer()
      ..write('VaultException: $message')
      ..write(', key: ${key?.name}')
      ..write(', error: $error')
      ..write(', stackTrace: $stackTrace');

    return buffer.toString();
  }
}
