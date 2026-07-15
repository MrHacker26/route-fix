/// Auto Fix data adapters — platform providers and orchestration.
library;

export 'adapters/auto_fix_provider_adapter.dart';
export 'executors/linux_platform_fix_executor.dart';
export 'executors/macos_platform_fix_executor.dart';
export 'executors/unsupported_platform_fix_executor.dart';
export 'executors/windows_platform_fix_executor.dart';
export 'linux_fix_provider.dart';
export 'macos_fix_provider.dart';
export 'platform_fix_provider_factory.dart';
export 'repository/in_memory_auto_fix_repository.dart';
export 'service/default_auto_fix_service.dart';
export 'shell/dart_io_shell_command_executor.dart';
export 'windows/windows_admin_requirement.dart';
export 'windows/windows_ipv6_fix_commands.dart';
export 'windows_fix_provider.dart';
