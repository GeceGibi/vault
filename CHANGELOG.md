## [0.0.2]

### Added
- **Static Key Factories:** Added `Keep.integer`, `Keep.stringSecure`, etc., enabling cleaner field declarations without `late`.
- **Decimal Support:** Added `decimal` and `decimalSecure` factories for typed-safe double storage.
- **Inline Documentation:** Added comprehensive DartDocs for all public members and constructors.

### Changed
- **API Simplification:** `Keep.keys` and `Keep.removableKeys` now return `List<KeepKey>` instead of `List<String>`, utilizing the internal registry for faster access.
- **Registry-Based Discovery:** Removed manual disk scanning for key discovery (`keysExternal` removed) in favor of the new automatic registration system.
- **Reactive Cleanup:** `clearRemovable()` now automatically notifies all listeners of the affected keys via `onChangeController`.
- **Metadata Optimization:** Eliminated `meta.keep` file; external storage is now purely code-driven.
- **Structure:** Removed `KeepKeyManager` and organized factories directly within the `Keep` class.

### Fixed
- **Type Safety:** Improved `num` to `double` conversion in decimal factories.
- **Boolean Parsing:** Added support for `1` as truthy in `booleanSecure`.
- **Duplicate Directives:** Cleaned up project file organization and part directives.

## [0.0.1+1]
- Internal build stabilization and testing.

## [0.0.1]
- Initial release