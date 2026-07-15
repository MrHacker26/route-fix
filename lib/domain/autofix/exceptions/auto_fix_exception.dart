import '../models/fix_type.dart';

/// Typed failures from the Auto Fix layer.
sealed class AutoFixException implements Exception {
  const AutoFixException(this.message, {this.details});

  final String message;
  final String? details;

  @override
  String toString() =>
      details == null || details!.isEmpty ? message : '$message ($details)';
}

final class AutoFixUnsupportedException extends AutoFixException {
  const AutoFixUnsupportedException([
    String message = 'Auto Fix is not available on this platform.',
    String? details,
  ]) : super(message, details: details);
}

final class AutoFixPermissionException extends AutoFixException {
  const AutoFixPermissionException([
    String message =
        'RouteFix needs administrator permission to apply this change.',
    String? details,
  ]) : super(message, details: details);
}

final class AutoFixExecutionException extends AutoFixException {
  const AutoFixExecutionException(
    super.message, {
    super.details,
    this.exitCode,
    this.stdout,
    this.stderr,
  });

  final int? exitCode;
  final String? stdout;
  final String? stderr;
}

final class AutoFixBusyException extends AutoFixException {
  const AutoFixBusyException([
    String message = 'Another fix is already being applied.',
  ]) : super(message);
}

final class AutoFixNotImplementedException extends AutoFixException {
  AutoFixNotImplementedException(FixType type)
      : super('${type.displayTitle} is planned for a future release.');
}

final class AutoFixValidationException extends AutoFixException {
  const AutoFixValidationException(super.message, {super.details});
}
