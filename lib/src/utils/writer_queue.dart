part of 'utils.dart';

/// A helper to manage debounced and queued side-effect operations (like writes).
///
/// This class ensures that operations with the same [id] are:
/// 1. **Debounced**: Rapid successive calls cancel previous pending timers
/// 2. **Queued**: Operations execute sequentially, waiting for previous ones to complete
@internal
class KeepWriteQueue {
  final Map<String, _PendingOp<dynamic>> _pendingOps = {};
  final Map<String, Future<dynamic>> _activeOperations = {};

  /// Runs an [action] for the given [id] with an optional [delay].
  ///
  /// **Debounce behavior:**
  /// If a new action with the same [id] arrives within [delay], the previous
  /// pending action's timer is canceled and its completer is completed with an error.
  /// This prevents awaiting callers from hanging indefinitely.
  ///
  /// **Queue behavior:**
  /// Once the [delay] passes, the action enters a sequential queue for that [id]
  /// and waits for any ongoing operation to finish before executing.
  ///
  /// **Parameters:**
  /// - [id]: Unique identifier for grouping operations
  /// - [action]: The async function to execute
  /// - [delay]: Debounce delay before execution (default: zero)
  /// - [onError]: Optional callback invoked when [action] throws an error
  ///
  /// **Returns:**
  /// A [Future] that completes with the result of [action], or completes with
  /// an error if [action] throws or if the operation is superseded by a newer one.
  ///
  /// **Example:**
  /// ```dart
  /// final queue = KeepWriteQueue();
  ///
  /// // These calls will be debounced - only the last one executes
  /// queue.run(id: 'user1', action: () => saveUser('Alice'), delay: Duration(milliseconds: 300));
  /// queue.run(id: 'user1', action: () => saveUser('Bob'), delay: Duration(milliseconds: 300));
  /// // First call is canceled, only 'Bob' is saved after 300ms
  ///
  /// // These execute sequentially for the same id
  /// queue.run(id: 'user1', action: () => operation1());
  /// queue.run(id: 'user1', action: () => operation2());
  /// // operation2 waits for operation1 to complete
  /// ```
  Future<T> run<T>({
    required String id,
    required Future<T> Function() action,
    Duration delay = Duration.zero,
    void Function(KeepException<dynamic> error)? onError,
  }) {
    final completer = Completer<T>();

    // Cancel existing pending operation for this id (Debounce)
    _pendingOps.remove(id)?.cancel();

    // Schedule the action to run after the delay
    final timer = Timer(delay, () {
      _pendingOps.remove(id);
      unawaited(_executeQueued(id, action, completer, onError));
    });

    _pendingOps[id] = _PendingOp(
      timer: timer,
      completer: completer,
    );

    return completer.future;
  }

  /// Executes an [action] in a sequential queue for the given [id].
  ///
  /// This method ensures that operations with the same [id] execute one at a time.
  /// It waits for any previous operation to complete before starting the new one.
  ///
  /// **Parameters:**
  /// - [id]: Unique identifier for the operation queue
  /// - [action]: The async function to execute
  /// - [completer]: The completer to resolve with the action's result or error
  /// - [onError]: Optional callback invoked when [action] throws an error
  Future<void> _executeQueued<T>(
    String id,
    Future<T> Function() action,
    Completer<T> completer,
    void Function(KeepException<dynamic> error)? onError,
  ) async {
    // Wait for any previous operation with the same id to complete
    final previousOperation = _activeOperations[id];
    if (previousOperation != null) {
      await previousOperation.catchError((_) => null);
    }

    // Track this operation as the active one
    final currentOperationCompleter = Completer<T>();
    _activeOperations[id] = currentOperationCompleter.future;

    try {
      // Execute the action
      final result = await action();

      // Complete both the internal and external completers with the result
      if (!currentOperationCompleter.isCompleted) {
        currentOperationCompleter.complete(result);
      }
      if (!completer.isCompleted) {
        completer.complete(result);
      }
    } catch (error, stackTrace) {
      // Wrap non-KeepException errors
      final exception = (error is KeepException)
          ? error
          : KeepException<dynamic>(
              error.toString(),
              error: error,
              stackTrace: stackTrace,
            );

      // Notify error callback if provided
      onError?.call(exception);

      // Complete both completers with the error
      if (!currentOperationCompleter.isCompleted) {
        currentOperationCompleter.completeError(exception);
      }
      if (!completer.isCompleted) {
        completer.completeError(exception);
      }
    } finally {
      // Clean up if this is still the active operation
      if (_activeOperations[id] == currentOperationCompleter.future) {
        _activeOperations.remove(id)?.ignore();
      }
    }
  }

  /// Cancels all pending debounce timers.
  ///
  /// This should be called when the storage is being disposed to prevent
  /// pending scheduled writes from executing on a closed/deleted file system.
  /// All pending operations will be completed with an error.
  void dispose() {
    for (final op in _pendingOps.values) {
      op.cancel();
    }
    _pendingOps.clear();
    _activeOperations.clear();
  }
}

/// Holds a pending debounced operation.
///
/// Contains the timer and completer that will be canceled/completed
/// if a newer operation with the same id arrives before the delay expires.
class _PendingOp<T> {
  _PendingOp({
    required this.timer,
    required this.completer,
  });

  /// The timer that schedules the operation execution after the debounce delay
  final Timer timer;

  /// The completer that will be resolved when the operation executes or is canceled
  final Completer<T> completer;

  /// Cancels the pending operation by stopping the timer.
  ///
  /// Tries to complete with `null` so callers awaiting `write()` don't see an exception.
  /// If `T` is strictly non-nullable and `null` is unsafe, falls back to error.
  void cancel() {
    timer.cancel();
    if (!completer.isCompleted) {
      try {
        // Most Keep operations return void or T?, so null is usually fine.
        completer.complete(null as T?);
      } catch (_) {
        completer.completeError(
          const KeepException<dynamic>('Operation superseded by newer request'),
        );
      }
    }
  }
}
