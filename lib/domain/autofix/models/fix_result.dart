import 'fix_action.dart';

/// Outcome of attempting (or planning) a [FixActionKind].
final class FixResult {
  const FixResult({
    required this.action,
    required this.success,
    required this.executed,
    this.message,
    this.error,
    this.metadata = const {},
  });

  /// Fix ran and applied successfully.
  factory FixResult.success(
    FixActionKind action, {
    required String message,
    Map<String, String> metadata = const {},
  }) {
    return FixResult(
      action: action,
      success: true,
      executed: true,
      message: message,
      metadata: metadata,
    );
  }

  /// Fix was attempted (or rejected) and did not apply.
  factory FixResult.failure(
    FixActionKind action, {
    required String message,
    String? error,
    bool executed = true,
    Map<String, String> metadata = const {},
  }) {
    return FixResult(
      action: action,
      success: false,
      executed: executed,
      message: message,
      error: error,
      metadata: metadata,
    );
  }

  /// Successful dry-run / catalog acknowledgement (no system change).
  factory FixResult.acknowledged(
    FixActionKind action, {
    String? message,
  }) {
    return FixResult(
      action: action,
      success: true,
      executed: false,
      message: message ?? 'Fix registered but not executed.',
    );
  }

  /// Action is known but not implemented on this provider yet.
  factory FixResult.notImplemented(FixActionKind action) {
    return FixResult(
      action: action,
      success: false,
      executed: false,
      error: 'Fix "${action.name}" is not implemented yet.',
    );
  }

  /// Action is unsupported on the current platform.
  factory FixResult.unsupported(FixActionKind action, FixPlatform platform) {
    return FixResult(
      action: action,
      success: false,
      executed: false,
      error: 'Fix "${action.name}" is unsupported on ${platform.name}.',
    );
  }

  /// Planned future capability.
  factory FixResult.comingSoon(FixActionKind action) {
    return FixResult(
      action: action,
      success: false,
      executed: false,
      error: 'Fix "${action.name}" is planned for a future release.',
    );
  }

  final FixActionKind action;

  /// Whether the provider considers the request fulfilled.
  final bool success;

  /// Whether a platform command was invoked (success or failure).
  final bool executed;

  final String? message;
  final String? error;
  final Map<String, String> metadata;

  @override
  bool operator ==(Object other) {
    return other is FixResult &&
        other.action == action &&
        other.success == success &&
        other.executed == executed &&
        other.message == message &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(action, success, executed, message, error);
}
