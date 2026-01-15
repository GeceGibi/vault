import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:keep/keep.dart';

class TestKeep extends Keep {
  TestKeep()
    : super(
        encrypter: SimpleKeepEncrypter(
          secureKey: 'secure_test_key_32_chars_long!!',
        ),
      );

  KeepKey<String> get username => key.string('username');
  KeepKey<String> get username2 => key.string('username');
  KeepKey<String> get username3 => key.string('username');
  KeepKeySecure<String> get secureToken => key.stringSecure(
    'token',
  ); // Internal Secure

  KeepKey<String> get extData => key.string(
    'ext_data',
    useExternalStorage: true,
  ); // External

  KeepKeySecure<String> get extSecure => key.stringSecure(
    'ext_secure',
    useExternalStorage: true,
  ); // External Secure
}

void main() {
  test('Generate Data for Inspection', () async {
    final dir = Directory('${Directory.current.path}/test/keep_data_inspect');

    // Clean start
    // if (dir.existsSync()) {
    //   await dir.delete(recursive: true);
    // }
    await dir.create(recursive: true);

    print('Storage Path: ${dir.path}');

    final storage = TestKeep();
    await storage.init(path: dir.path);

    // 1. Internal Plain
    print('Internal Plain: ${await storage.username.read()}');
    print('Internal Plain 2: ${await storage.username2.read()}');
    print('Internal Plain 3: ${await storage.username3.read()}');
    ;
    await storage.username.write('john_doe_plain');

    print(storage.keys);

    // 2. Internal Secure
    print('Internal Secure: ${await storage.secureToken.read()}');
    await storage.secureToken.write('secret_token_123');

    // 3. External Plain
    print('External Plain: ${await storage.extData.read()}');
    await storage.extData.write('external_file_content_plain');

    // 4. External Secure
    print('External Secure: ${await storage.extSecure.read()}');
    await storage.extSecure.write('external_secret_content');

    // Wait for internal storage debounce timer (150ms) + IO
    await Future<void>.delayed(const Duration(seconds: 1));

    print('Data generated successfully! Check ${dir.path}');
  });
}
