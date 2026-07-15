import 'package:flutter/material.dart';

import '../../core/app_info.dart';
import '../../design_system/design_system.dart';
import '../../domain/repositories/settings_repository.dart';
import '../about/about_dialog.dart';
import 'app_settings_controller.dart';

/// Lightweight preferences for RouteFix.
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.controller,
  });

  final AppSettingsController controller;

  static const _timeoutOptions = <int>[5, 8, 12, 20];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final settings = controller.settings;
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
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _Section(
                                          title: 'Appearance',
                                          child: Column(
                                            children: [
                                              for (final option
                                                  in AppAppearance.values)
                                                _RadioRow(
                                                  label: switch (option) {
                                                    AppAppearance.dark =>
                                                      'Dark',
                                                    AppAppearance.system =>
                                                      'System',
                                                  },
                                                  subtitle: switch (option) {
                                                    AppAppearance.dark =>
                                                      'Always use the dark interface.',
                                                    AppAppearance.system =>
                                                      'Follow the system appearance.',
                                                  },
                                                  selected: settings
                                                          .appearance ==
                                                      option,
                                                  onTap: () => controller
                                                      .setAppearance(option),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppSpacing.sectionGap,
                                        ),
                                        _Section(
                                          title: 'Diagnostics',
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Probe timeout',
                                                style: text.titleSmall
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(
                                                height: AppSpacing.xxs,
                                              ),
                                              Text(
                                                'How long each network check may wait.',
                                                style: text.bodySmall
                                                    ?.copyWith(
                                                  color: AppColors
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                              const SizedBox(
                                                height: AppSpacing.sm,
                                              ),
                                              Wrap(
                                                spacing: AppSpacing.xs,
                                                runSpacing: AppSpacing.xs,
                                                children: [
                                                  for (final seconds
                                                      in _timeoutOptions)
                                                    _ChipChoice(
                                                      label: '${seconds}s',
                                                      selected: settings
                                                              .diagnosticsTimeoutSeconds ==
                                                          seconds,
                                                      onTap: () => controller
                                                          .setDiagnosticsTimeoutSeconds(
                                                        seconds,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(
                                                height: AppSpacing.lg,
                                              ),
                                              _ToggleRow(
                                                title:
                                                    'Auto rerun after fixes',
                                                subtitle:
                                                    'Scan again when an Auto Fix succeeds.',
                                                value: settings
                                                    .autoRerunAfterFixes,
                                                onChanged: controller
                                                    .setAutoRerunAfterFixes,
                                              ),
                                              const SizedBox(
                                                height: AppSpacing.sm,
                                              ),
                                              _ToggleRow(
                                                title:
                                                    'Show technical details',
                                                subtitle:
                                                    'Expand Technical details by default.',
                                                value: settings
                                                    .showTechnicalDetailsByDefault,
                                                onChanged: controller
                                                    .setShowTechnicalDetailsByDefault,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppSpacing.sectionGap,
                                        ),
                                        _Section(
                                          title: 'About',
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        AppRadius.smAll,
                                                    child: Image.asset(
                                                      AppAssets.appIcon,
                                                      width: 40,
                                                      height: 40,
                                                      filterQuality:
                                                          FilterQuality.medium,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: AppSpacing.sm,
                                                  ),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          AppInfo.name,
                                                          style: text
                                                              .titleMedium
                                                              ?.copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600,
                                                          ),
                                                        ),
                                                        Text(
                                                          'Version ${AppInfo.versionLabel}',
                                                          style: text
                                                              .bodySmall
                                                              ?.copyWith(
                                                            color: AppColors
                                                                .onSurfaceMuted,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(
                                                height: AppSpacing.md,
                                              ),
                                              Text(
                                                AppInfo.tagline,
                                                style: text.bodyMedium
                                                    ?.copyWith(
                                                  color: AppColors
                                                      .onSurfaceVariant,
                                                  height: 1.45,
                                                ),
                                              ),
                                              const SizedBox(
                                                height: AppSpacing.lg,
                                              ),
                                              SecondaryButton(
                                                label: 'About RouteFix',
                                                icon: Icons.info_outline_rounded,
                                                onPressed: () =>
                                                    showAboutRouteFixDialog(
                                                  context,
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
      },
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.onBack});

  final VoidCallback onBack;

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
            'Settings',
            style: text.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: text.labelMedium?.copyWith(
              color: AppColors.onSurfaceMuted,
              letterSpacing: 0.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _RadioRow extends StatelessWidget {
  const _RadioRow({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.smAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: text.titleSmall?.copyWith(
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: text.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
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
    );
  }
}

class _ChipChoice extends StatelessWidget {
  const _ChipChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smAll,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.14)
                : AppColors.surfaceHigh.withValues(alpha: 0.45),
            borderRadius: AppRadius.smAll,
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.45)
                  : AppColors.outlineSubtle,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.textTheme.labelLarge?.copyWith(
              color: selected ? AppColors.primary : AppColors.onSurface,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: text.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.onPrimary,
          activeTrackColor: AppColors.primary,
        ),
      ],
    );
  }
}
