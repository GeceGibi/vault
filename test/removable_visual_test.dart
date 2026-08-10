import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:keep/keep.dart';

class TestKeep extends Keep {
  TestKeep()
    : super(
        'TestKeep',
        encrypter: SimpleKeepEncrypter(
          secureKey: 'secure_test_key_32_chars_long!!',
        ),
      );

  final KeepKeyPlain<String> extRemovable1 = Keep.kString(
    'ext_removable_1',
    useExternal: true,
    removable: true,
  );

  final KeepKeyPlain<String> extRemovable2 = Keep.kString(
    'ext_removable_2',
    useExternal: true,
    removable: true,
  );

  final KeepKeyPlain<String> extNonRemovable = Keep.kString(
    'ext_non_removable',
    useExternal: true,
    removable: false,
  );
}

void main() {
  test('External Removable Visual Test', () async {
    final tempDir = Directory(
      '${Directory.current.path}/test/removable_visual_data',
    );
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
    await tempDir.create(recursive: true);

    final storage = TestKeep();
    await storage.init(path: tempDir.path);

    final externalDir = Directory('${storage.root.path}/external');

    void listFiles(String label) {
      print('\n--- $label ---');
      if (!externalDir.existsSync()) {
        print('  (external directory does not exist)');
        return;
      }
      final files = externalDir.listSync();
      if (files.isEmpty) {
        print('  (no files)');
      } else {
        for (final file in files) {
          print('  📄 ${file.uri.pathSegments.last}');
        }
      }
    }

    listFiles('Initial State');

    // Write 3 keys
    print('\n✍️  Writing extRemovable1...');
    await storage.extRemovable1.write('value1');
    listFiles('After extRemovable1');

    print('\n✍️  Writing extRemovable2...');
    await storage.extRemovable2.write('value2');
    listFiles('After extRemovable2');

    print('\n✍️  Writing extNonRemovable...');
    await storage.extNonRemovable.write('value3');
    listFiles('After extNonRemovable');

    // Clear removable
    print('\n🗑️  Calling clearRemovable()...');
    await storage.clearRemovable();
    listFiles('After clearRemovable()');

    // Verify
    print('\n--- Verification ---');
    final removable1Exists = await storage.extRemovable1.exists;
    final removable2Exists = await storage.extRemovable2.exists;
    final nonRemovableExists = await storage.extNonRemovable.exists;
    final nonRemovableValue = await storage.extNonRemovable.read();

    print('extRemovable1 exists: $removable1Exists');
    print('extRemovable2 exists: $removable2Exists');
    print('extNonRemovable exists: $nonRemovableExists');
    print('extNonRemovable value: $nonRemovableValue');

    expect(removable1Exists, isFalse);
    expect(removable2Exists, isFalse);
    expect(nonRemovableExists, isTrue);
    expect(nonRemovableValue, 'value3');

    // Cleanup
    // await tempDir.delete(recursive: true);

    print('\n✅ Test Complete!');
  });
}
