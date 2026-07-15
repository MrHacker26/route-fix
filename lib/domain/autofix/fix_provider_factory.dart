import 'models/fix_action.dart';
import 'fix_provider.dart';

/// Creates a [FixProvider] for the host without applying any fixes.
///
/// The application depends on this factory (or [FixProvider] from DI) rather
/// than concrete Linux / macOS / Windows adapters.
abstract interface class FixProviderFactory {
  /// Resolves the Auto Fix adapter for the current host.
  ///
  /// Selection only — never mutates the system.
  FixProvider create();

  /// Resolves an adapter for an explicit [platform] (tests / future hosts).
  FixProvider createFor(FixPlatform platform);
}
