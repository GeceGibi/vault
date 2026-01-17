part of 'key.dart';

/// Manages registration and persistence of sub-keys.
///
/// Sub-keys are stored in a separate file (hashed) associated with the parent key.
class SubKeyManager<T> {
  /// Creates a [SubKeyManager] for the given [parent] key.
  SubKeyManager(this._parent);

  final KeepKey<T> _parent;

  /// In-memory cache of registered sub-key names.
  final _keyNames = <String>[];

  /// The file name for storing sub-key names, derived from the parent key's name.
  late final String _fileName = KeepCodec.generateHash('${_parent.name}\$sk');

  /// File path: `root/hash(parentName$sk)`
  File get _file => File('${_parent._keep.root.path}/$_fileName');

  /// Registers a sub-key name synchronously.
  ///
  /// Adds to memory immediately and schedules a background sync to merge with disk.
  void register(KeepKey<T> key) {
    if (_keyNames.contains(key.name)) {
      return;
    }

    _keyNames.add(key.name);
    _scheduleSync();
  }

  /// Returns the list of registered sub-keys.
  List<KeepKey<T>> get keys => List.unmodifiable(
    _keyNames.map((name) => _parent(name.split(r'$').last)),
  );

  Timer? _timer;

  /// Schedules a debounced sync operation (150ms delay).
  void _scheduleSync() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 150), _performSync);
  }

  /// Merges memory keys with disk keys and saves the result atomically if changed.
  Future<void> _performSync() async {
    final diskKeys = <String>{};

    if (_file.existsSync()) {
      final bytes = await _file.readAsBytes();
      try {
        final decoded = KeepCodec.decodePayload(bytes);
        if (decoded?.value is List) {
          diskKeys.addAll((decoded!.value as List).cast<String>());
        }
      } catch (error, stackTrace) {
        final exception = KeepException<T>(
          'Failed to decode sub-key file',
          error: error,
          stackTrace: stackTrace,
        );

        _parent._keep.onError?.call(exception);
        throw exception;
      }
    }

    // Merge: Disk + Memory (Union)
    final allKeys = {...diskKeys, ..._keyNames};

    // Update memory to reflect full state (Disk + Memory)
    _keyNames
      ..clear()
      ..addAll(allKeys);

    // If disk already has all keys, no need to write
    if (setEquals(diskKeys, allKeys)) {
      return;
    }

    // Atomic write: Write to temp file -> Rename
    final tempFile = File(
      '${_file.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );

    // Use KeepCodec to encode (Shift bytes)
    await tempFile.writeAsBytes(KeepCodec.encodePayload(allKeys.toList(), 0));
    await tempFile.rename(_file.path);
  }
}
