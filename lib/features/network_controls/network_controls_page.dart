import 'package:flutter/material.dart';

import '../../data/autofix/shell/dart_io_shell_command_executor.dart';
import '../../design_system/design_system.dart';
import '../../di/app_services.dart';
import '../../domain/autofix/auto_fix_service.dart';
import '../../domain/autofix/models/fix_result.dart';
import '../../domain/autofix/platform_fix_executor.dart';
import '../diagnostics/diagnostics_page.dart';
import '../diagnostics/human_message.dart';
import 'apply_network_changes_dialog.dart';
import 'ipv6_preference.dart';
import 'ipv6_preference_probe.dart';
import 'network_controls_controller.dart';

/// Manual network preference controls for advanced users.
class NetworkControlsPage extends StatefulWidget {
  const NetworkControlsPage({
    super.key,
    this.autoFix,
    this.controller,
  });

  final AutoFixService? autoFix;
  final NetworkControlsController? controller;

  @override
  State<NetworkControlsPage> createState() => _NetworkControlsPageState();
}

class _NetworkControlsPageState extends State<NetworkControlsPage> {
  late final NetworkControlsController _controller;
  var _booting = true;
  var _working = false;
  String? _progressLabel;
  String? _successMessage;
  String? _failureMessage;
  String? _failureTechnical;

  @override
  void initState() {
    super.initState();
    final autoFix = widget.autoFix ?? AppServices.autoFix;
    _controller = widget.controller ??
        NetworkControlsController(
          autoFix: autoFix,
          probe: Ipv6PreferenceProbe(
            shell: const DartIoShellCommandExecutor(),
            autoFix: autoFix,
          ),
        );
    _boot();
  }

  Future<void> _boot() async {
    await _controller.load();
    if (!mounted) return;
    setState(() => _booting = false);
  }

  Future<void> _refresh() async {
    setState(() {
      _booting = true;
      _successMessage = null;
      _failureMessage = null;
      _failureTechnical = null;
    });
    await _controller.load();
    if (!mounted) return;
    setState(() => _booting = false);
  }

  Future<void> _apply() async {
    if (!_controller.hasPendingChanges || _working) return;

    final confirmed = await showApplyNetworkChangesDialog(context);
    if (confirmed != ApplyNetworkChangesResult.confirmed || !mounted) return;

    setState(() {
      _working = true;
      _progressLabel = AutoFixPhase.applying.label;
      _successMessage = null;
      _failureMessage = null;
      _failureTechnical = null;
    });

    late final FixResult result;
    try {
      result = await _controller.applySelection(
        onPhase: (phase) {
          if (!mounted) return;
          setState(() => _progressLabel = phase.label);
        },
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _failureTechnical = error.toString();
        _failureMessage = HumanMessage.fromProbeError(
          error.toString(),
          fallback: 'Couldn’t update preferences.',
        );
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _working = false;
      if (result.wasCancelled) {
        _successMessage = null;
        _failureMessage = null;
        _failureTechnical = null;
      } else if (result.success) {
        _successMessage = 'Settings updated.';
        _failureMessage = null;
        _failureTechnical = null;
      } else {
        _failureTechnical = [
          if (result.error != null) result.error!,
          if (result.metadata['stderr'] != null) result.metadata['stderr']!,
          if (result.executedCommand != null) result.executedCommand!,
        ].where((part) => part.trim().isNotEmpty).join('\n');
        _failureMessage = HumanMessage.fromProbeError(
          result.message ?? result.error,
          fallback: 'That change didn’t go through. Try again.',
        );
      }
    });
    if (result.success) {
      if (AppServices.settings.settings.autoRerunAfterFixes) {
        _runDiagnostics();
      }
    }
  }

  Future<void> _restore() async {
    if (_working) return;

    final confirmed = await showApplyNetworkChangesDialog(context);
    if (confirmed != ApplyNetworkChangesResult.confirmed || !mounted) return;

    setState(() {
      _working = true;
      _progressLabel = AutoFixPhase.restoring.label;
      _successMessage = null;
      _failureMessage = null;
      _failureTechnical = null;
    });

    late final FixResult result;
    try {
      result = await _controller.restoreDefaults(
        onPhase: (phase) {
          if (!mounted) return;
          setState(() => _progressLabel = phase.label);
        },
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _failureTechnical = error.toString();
        _failureMessage = HumanMessage.fromProbeError(
          error.toString(),
          fallback: 'Couldn’t restore defaults.',
        );
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _working = false;
      if (result.wasCancelled) {
        _successMessage = null;
        _failureMessage = null;
        _failureTechnical = null;
      } else if (result.success) {
        _successMessage = 'Settings updated.';
        _failureMessage = null;
        _failureTechnical = null;
      } else {
        _failureTechnical = [
          if (result.error != null) result.error!,
          if (result.metadata['stderr'] != null) result.metadata['stderr']!,
        ].where((part) => part.trim().isNotEmpty).join('\n');
        _failureMessage = HumanMessage.fromProbeError(
          result.message ?? result.error,
          fallback: 'Restore didn’t finish. Try again.',
        );
      }
    });
    if (result.success) {
      if (AppServices.settings.settings.autoRerunAfterFixes) {
        _runDiagnostics();
      }
    }
  }

  void _runDiagnostics() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondary) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: const DiagnosticsPage(),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: PageAtmosphere(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.desktopMaxWidth,
              ),
              child: Column(
                children: [
                  _Toolbar(
                    onBack: () => Navigator.of(context).maybePop(),
                    onRefresh: _working || _booting ? null : _refresh,
                  ),
                  Expanded(
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.xl,
                            AppSpacing.md,
                            AppSpacing.xl,
                            AppSpacing.xxl,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 640),
                                child: _booting
                                    ? const _LoadingCard()
                                    : GlassCard(
                                        padding: const EdgeInsets.all(
                                          AppSpacing.lg,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Network',
                                              style: text.titleLarge?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: AppSpacing.xxs,
                                            ),
                                            Text(
                                              'Choose how this device prefers network paths.',
                                              style: text.bodyMedium?.copyWith(
                                                color:
                                                    AppColors.onSurfaceVariant,
                                                height: 1.4,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: AppSpacing.lg,
                                            ),
                                            _CurrentStateRow(
                                              preference:
                                                  _controller.detected,
                                              detail:
                                                  _controller.statusDetail,
                                            ),
                                            const SizedBox(
                                              height: AppSpacing.lg,
                                            ),
                                            Text(
                                              'IPv6',
                                              style:
                                                  text.labelMedium?.copyWith(
                                                color:
                                                    AppColors.onSurfaceMuted,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: AppSpacing.sm,
                                            ),
                                            for (final option in const [
                                              Ipv6Preference.automatic,
                                              Ipv6Preference.preferIpv4,
                                              Ipv6Preference.disableIpv6,
                                            ])
                                              _PreferenceOption(
                                                preference: option,
                                                groupValue:
                                                    _controller.selected,
                                                enabled: !_working &&
                                                    _controller
                                                        .supportsPlatform,
                                                onSelected: () {
                                                  setState(() {
                                                    _controller
                                                        .select(option);
                                                    _successMessage = null;
                                                    _failureMessage = null;
                                                    _failureTechnical = null;
                                                  });
                                                },
                                              ),
                                            if (_working) ...[
                                              const SizedBox(
                                                height: AppSpacing.md,
                                              ),
                                              InlineProgress(
                                                label: _progressLabel ??
                                                    'Applying…',
                                              ),
                                            ],
                                            if (_successMessage != null) ...[
                                              const SizedBox(
                                                height: AppSpacing.md,
                                              ),
                                              Text(
                                                _successMessage!,
                                                style: text.bodyMedium
                                                    ?.copyWith(
                                                  color: AppColors.success,
                                                  height: 1.4,
                                                ),
                                              ),
                                              const SizedBox(
                                                height: AppSpacing.sm,
                                              ),
                                              SecondaryButton(
                                                label:
                                                    'Scan again',
                                                icon: Icons.refresh_rounded,
                                                onPressed: _runDiagnostics,
                                              ),
                                            ],
                                            if (_failureMessage != null) ...[
                                              const SizedBox(
                                                height: AppSpacing.md,
                                              ),
                                              Text(
                                                _failureMessage!,
                                                style:
                                                    text.bodySmall?.copyWith(
                                                  color: AppColors.error,
                                                  height: 1.4,
                                                ),
                                              ),
                                              if (_failureTechnical !=
                                                      null &&
                                                  _failureTechnical!
                                                      .isNotEmpty)
                                                Theme(
                                                  data: Theme.of(context)
                                                      .copyWith(
                                                    dividerColor:
                                                        Colors.transparent,
                                                  ),
                                                  child: Material(
                                                    color: Colors
                                                        .transparent,
                                                    child: ExpansionTile(
                                                      tilePadding:
                                                          EdgeInsets.zero,
                                                      title: Text(
                                                        'Technical details',
                                                        style: text
                                                            .labelMedium
                                                            ?.copyWith(
                                                          color: AppColors
                                                              .primary,
                                                        ),
                                                      ),
                                                      children: [
                                                        Align(
                                                          alignment: Alignment
                                                              .centerLeft,
                                                          child:
                                                              SelectableText(
                                                            _failureTechnical!,
                                                            style: text
                                                                .bodySmall
                                                                ?.copyWith(
                                                              fontFamily:
                                                                  'Menlo',
                                                              fontFamilyFallback:
                                                                  const [
                                                                'Consolas',
                                                                'monospace',
                                                              ],
                                                              color: AppColors
                                                                  .onSurfaceMuted,
                                                              height: 1.4,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                            ],
                                            const SizedBox(
                                              height: AppSpacing.lg,
                                            ),
                                            const Divider(
                                              height: 1,
                                              color:
                                                  AppColors.outlineSubtle,
                                            ),
                                            const SizedBox(
                                              height: AppSpacing.lg,
                                            ),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: SecondaryButton(
                                                    label:
                                                        'Restore defaults',
                                                    icon:
                                                        Icons.undo_rounded,
                                                    expanded: true,
                                                    onPressed: (_working ||
                                                            !_controller
                                                                .supportsPlatform)
                                                        ? null
                                                        : _restore,
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: AppSpacing.sm,
                                                ),
                                                Expanded(
                                                  child: PrimaryButton(
                                                    label: 'Apply',
                                                    icon:
                                                        Icons.tune_rounded,
                                                    expanded: true,
                                                    onPressed: (_working ||
                                                            !_controller
                                                                .hasPendingChanges ||
                                                            !_controller
                                                                .supportsPlatform)
                                                        ? null
                                                        : _apply,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (!_controller
                                                .supportsPlatform) ...[
                                              const SizedBox(
                                                height: AppSpacing.md,
                                              ),
                                              Text(
                                                'Network Controls aren’t available here.',
                                                style: text.bodySmall
                                                    ?.copyWith(
                                                  color: AppColors
                                                      .onSurfaceMuted,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.onBack,
    required this.onRefresh,
  });

  final VoidCallback onBack;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.outlineSubtle),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_rounded,
              size: AppSpacing.iconInline,
            ),
            style: IconButton.styleFrom(
              foregroundColor: AppColors.onSurfaceVariant,
              hoverColor: AppColors.surfaceHigh,
              minimumSize: const Size(32, 32),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.xsAll,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Network Controls',
            style: text.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Refresh status',
            onPressed: onRefresh,
            icon: const Icon(
              Icons.refresh_rounded,
              size: AppSpacing.iconInline,
            ),
            style: IconButton.styleFrom(
              foregroundColor: AppColors.onSurfaceVariant,
              hoverColor: AppColors.surfaceHigh,
              minimumSize: const Size(32, 32),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.xsAll,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return FeedbackState.loading(
      title: 'Reading settings',
      body: 'Checking current network preference.',
      compact: true,
    );
  }
}

class _CurrentStateRow extends StatelessWidget {
  const _CurrentStateRow({
    required this.preference,
    this.detail,
  });

  final Ipv6Preference preference;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    final tone = switch (preference) {
      Ipv6Preference.automatic => StatusBadgeTone.success,
      Ipv6Preference.preferIpv4 => StatusBadgeTone.info,
      Ipv6Preference.disableIpv6 => StatusBadgeTone.warning,
      Ipv6Preference.unknown => StatusBadgeTone.neutral,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow.withValues(alpha: 0.65),
        borderRadius: AppRadius.smAll,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Current',
                style: text.labelSmall?.copyWith(
                  color: AppColors.onSurfaceMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              StatusBadge(label: preference.statusLabel, tone: tone),
            ],
          ),
          if (detail != null && detail!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              detail!,
              style: text.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreferenceOption extends StatefulWidget {
  const _PreferenceOption({
    required this.preference,
    required this.groupValue,
    required this.enabled,
    required this.onSelected,
  });

  final Ipv6Preference preference;
  final Ipv6Preference groupValue;
  final bool enabled;
  final VoidCallback onSelected;

  @override
  State<_PreferenceOption> createState() => _PreferenceOptionState();
}

class _PreferenceOptionState extends State<_PreferenceOption> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    final enabled = widget.enabled;
    final selected = widget.groupValue == widget.preference;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: MouseRegion(
        onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
        onExit: enabled ? (_) => setState(() => _hovered = false) : null,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? widget.onSelected : null,
            borderRadius: AppRadius.smAll,
            hoverColor: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : _hovered
                        ? AppColors.surfaceHigh.withValues(alpha: 0.5)
                        : Colors.transparent,
                borderRadius: AppRadius.smAll,
                border: Border.all(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.45)
                      : AppColors.outlineSubtle,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    size: AppSpacing.iconInline,
                    color: selected
                        ? AppColors.primary
                        : AppColors.onSurfaceMuted,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.preference.optionLabel,
                      style: text.titleSmall?.copyWith(
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
