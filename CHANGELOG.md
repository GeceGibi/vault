## [0.0.1]

### Added
- Initial release
- `Vault` - Main storage controller with hybrid storage architecture
- `VaultKey<T>` - Typed keys for type-safe read/write operations
- `VaultKeySecure<T>` - Encrypted keys with DJB2 name hashing
- `VaultKeyManager` - Factory for creating typed keys
  - `integer()`, `string()`, `boolean()`, `decimal()`, `map()`, `list()`
  - Secure variants for all types
  - `custom<T>()` for custom object serialization
- `VaultStorage` - Abstract base for custom storage backends
- `VaultEncrypter` - Interface for custom encryption implementations
- `SimpleVaultEncrypter` - Default XOR-based obfuscation
- `VaultBuilder` - Reactive widget for UI updates
- `VaultException` - Structured error handling
- Internal storage with debounced JSON persistence
- External storage with per-key file isolation
- Stream-based reactivity for key changes
