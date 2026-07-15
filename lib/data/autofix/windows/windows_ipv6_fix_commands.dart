/// Builds Windows PowerShell / native networking commands for IPv6 fixes.
///
/// Commands are descriptions only — this type never runs them.
final class WindowsIpv6FixCommands {
  const WindowsIpv6FixCommands();

  /// PowerShell: disable the IPv6 binding (`ms_tcpip6`) on all adapters.
  String disableIpv6PowerShell() {
    return _powershell(
      r"Get-NetAdapter | ForEach-Object { "
      r"Disable-NetAdapterBinding -Name $_.Name -ComponentID ms_tcpip6 "
      r"-ErrorAction SilentlyContinue }",
    );
  }

  /// PowerShell: enable the IPv6 binding (`ms_tcpip6`) on all adapters.
  String enableIpv6PowerShell() {
    return _powershell(
      r"Get-NetAdapter | ForEach-Object { "
      r"Enable-NetAdapterBinding -Name $_.Name -ComponentID ms_tcpip6 "
      r"-ErrorAction SilentlyContinue }",
    );
  }

  /// Native `netsh` equivalent used as a secondary reference command.
  String disableIpv6Netsh() {
    return 'netsh interface ipv6 set global randomizeidentifiers=disabled store=persistent';
  }

  /// Native `netsh` companion for re-enabling typical IPv6 global behavior.
  String enableIpv6Netsh() {
    return 'netsh interface ipv6 set global randomizeidentifiers=enabled store=persistent';
  }

  /// Primary command exposed through [FixResult.executedCommand].
  String primaryCommand({required bool enable}) {
    return enable ? enableIpv6PowerShell() : disableIpv6PowerShell();
  }

  String _powershell(String script) {
    return 'powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$script"';
  }
}
