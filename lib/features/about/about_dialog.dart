import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_info.dart';
import '../../design_system/design_system.dart';

/// Shows the RouteFix About dialog.
Future<void> showAboutRouteFixDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.62),
    builder: (context) => const AboutRouteFixDialog(),
  );
}

/// Logo, version, Flutter, platform, GitHub, and license.
class AboutRouteFixDialog extends StatefulWidget {
  const AboutRouteFixDialog({super.key});

  @override
  State<AboutRouteFixDialog> createState() => _AboutRouteFixDialogState();
}

class _AboutRouteFixDialogState extends State<AboutRouteFixDialog> {
  late final Future<String> _flutterVersion = AppInfo.resolveFlutterVersion();

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: AppRadius.mdAll,
                    child: Image.asset(
                      AppAssets.appIcon,
                      width: 48,
                      height: 48,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppInfo.name,
                          style: text.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Network routing diagnostics',
                          style: text.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const Divider(height: 1, color: AppColors.outlineSubtle),
              const SizedBox(height: AppSpacing.md),
              _MetaRow(label: 'Version', value: AppInfo.versionLabel),
              FutureBuilder<String>(
                future: _flutterVersion,
                builder: (context, snapshot) {
                  final value =
                      snapshot.connectionState == ConnectionState.waiting
                          ? '…'
                          : (snapshot.data ?? 'Unavailable');
                  return _MetaRow(label: 'Flutter', value: value);
                },
              ),
              _MetaRow(label: 'Platform', value: AppInfo.platformLabel),
              _MetaRow(label: 'License', value: AppInfo.license),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AppInfo.licenseCopyright,
                style: text.labelSmall?.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Divider(height: 1, color: AppColors.outlineSubtle),
              const SizedBox(height: AppSpacing.md),
              Text(
                'GitHub',
                style: text.labelMedium?.copyWith(
                  color: AppColors.onSurfaceMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppInfo.githubLabel,
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy link',
                    onPressed: () => _copyGithub(context),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.onSurfaceVariant,
                      minimumSize: const Size(32, 32),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Open',
                    onPressed: () => _openGithub(context),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.onSurfaceVariant,
                      minimumSize: const Size(32, 32),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerRight,
                child: SecondaryButton(
                  label: 'Close',
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openGithub(BuildContext context) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('open', [AppInfo.githubUrl]);
      } else if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', AppInfo.githubUrl]);
      } else {
        await Process.run('xdg-open', [AppInfo.githubUrl]);
      }
    } on Object {
      if (!context.mounted) return;
      await _copyGithub(context);
    }
  }

  Future<void> _copyGithub(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: AppInfo.githubUrl));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied')),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = AppTypography.textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: text.bodyMedium?.copyWith(
                color: AppColors.onSurfaceMuted,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: text.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
