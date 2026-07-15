import 'fix_action.dart';

/// Outcome of attempting or planning a [FixActionKind].
final class FixResult {
  const FixResult({
    required this.action,
    required this.success,
    required this.executed,
    this.message,
    this.error,
    this.executedCommand,
    this.platform,
    this.requiresElevation = false,
    this.metadata = const {},
  });

  /// Fix ran and applied successfully.
  factory FixResult.success(
    FixActionKind action, {
    required String message,
    String? executedCommand,
    FixPlatform? platform,
    bool requiresElevation = false,
    Map<String, String> metadata = const {},
  }) {
    return FixResult(
      action: action,
      success: true,
      executed: true,
      message: message,
      executedCommand: executedCommand,
      platform: platform,
      requiresElevation: requiresElevation,
      metadata: metadata,
    );
  }

  /// Fix was attempted (or rejected) and did not apply.
  factory FixResult.failure(
    FixActionKind action, {
    required String message,
    String? error,
    bool executed = true,
    String? executedCommand,
    FixPlatform? platform,
    bool requiresElevation = false,
    Map<String, String> metadata = const {},
  }) {
    return FixResult(
      action: action,
      success: false,
      executed: executed,
      message: message,
      error: error,
      executedCommand: executedCommand,
      platform: platform,
      requiresElevation: requiresElevation,
      metadata: metadata,
    );
  }

  /// Fix is prepared for the host but was not executed.
  factory FixResult.planned(
    FixActionKind action, {
    required String message,
    required String executedCommand,
    required FixPlatform platform,
    bool requiresElevation = false,
    String? error,
    bool success = true,
    Map<String, String> metadata = const {},
  }) {
    return FixResult(
      action: action,
      success: success,
      executed: false,
      message: message,
      error: error,
      executedCommand: executedCommand,
      platform: platform,
      requiresElevation: requiresElevation,
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
      platform: platform,
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

  /// User dismissed the OS authentication dialog — not an error.
  factory FixResult.cancelled(
    FixActionKind action, {
    FixPlatform? platform,
    String? executedCommand,
    Map<String, String> metadata = const {},
  }) {
    return FixResult(
      action: action,
      success: false,
      executed: false,
      message: 'UserCancelled',
      platform: platform,
      executedCommand: executedCommand,
      metadata: {
        'outcome': 'UserCancelled',
        ...metadata,
      },
    );
  }

  final FixActionKind action;

  /// Whether the provider considers the request fulfilled.
  final bool success;

  /// Whether a platform command was invoked (success or failure).
  final bool executed;

  final String? message;
  final String? error;

  /// Command that was run, or the prepared command when [executed] is false.
  final String? executedCommand;

  /// Platform this result applies to.
  final FixPlatform? platform;

  /// Whether applying [executedCommand] needs elevated privileges.
  final bool requiresElevation;

  final Map<String, String> metadata;

  /// True when the user cancelled the native authentication dialog.
  bool get wasCancelled =>
      message == 'UserCancelled' || metadata['outcome'] == 'UserCancelled';

  @override
  bool operator ==(Object other) {
    return other is FixResult &&
        other.action == action &&
        other.success == success &&
        other.executed == executed &&
        other.message == message &&
        other.error == error &&
        other.executedCommand == executedCommand &&
        other.platform == platform &&
        other.requiresElevation == requiresElevation;
  }

  @override
  int get hashCode => Object.hash(
        action,
        success,
        executed,
        message,
        error,
        executedCommand,
        platform,
        requiresElevation,
      );
}
