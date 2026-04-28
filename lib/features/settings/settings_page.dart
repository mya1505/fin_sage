import 'dart:async';

import 'package:fin_sage/core/constants/app_routes.dart';
import 'package:fin_sage/core/constants/lottie_placeholders.dart';
import 'package:fin_sage/core/errors/error_boundary.dart';
import 'package:fin_sage/core/utils/extensions.dart';
import 'package:fin_sage/l10n/generated/app_localizations.dart';
import 'package:fin_sage/logic/auth/auth_cubit.dart';
import 'package:fin_sage/logic/budgets/budget_cubit.dart';
import 'package:fin_sage/logic/dashboard/dashboard_cubit.dart';
import 'package:fin_sage/logic/settings/settings_cubit.dart';
import 'package:fin_sage/logic/transactions/transaction_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeTag = Localizations.localeOf(context).toLanguageTag();

    return ErrorBoundary(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.settingsTitle)),
        body: SafeArea(
          child: BlocConsumer<SettingsCubit, SettingsState>(
            listenWhen: (previous, current) =>
                previous.error != current.error ||
                previous.lastCompletedOperation != current.lastCompletedOperation,
            listener: (context, state) {
              final messenger = ScaffoldMessenger.of(context);
              if (state.error != null) {
                final message = _errorMessage(l10n, state.error!);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
                return;
              }

              String? message;
              switch (state.lastCompletedOperation) {
                case SettingsOperation.backup:
                  message = l10n.backupCompleted;
                  break;
                case SettingsOperation.preview:
                  message = l10n.restorePreviewLoaded;
                  break;
                case SettingsOperation.restore:
                  message = l10n.restoreCompleted;
                  unawaited(_refreshAfterRestore(context));
                  break;
                case SettingsOperation.reset:
                  message = l10n.localDataResetCompleted;
                  break;
                case SettingsOperation.autoBackupValidation:
                  message = l10n.autoBackupValidationScheduled;
                  unawaited(context.read<SettingsCubit>().refreshAutoBackupTelemetry());
                  break;
                case SettingsOperation.none:
                  break;
              }

              if (message != null) {
                unawaited(HapticFeedback.lightImpact());
                messenger.showSnackBar(SnackBar(content: Text(message)));
              }
            },
            builder: (context, state) {
              final cubit = context.read<SettingsCubit>();

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.darkMode),
                    trailing: Switch(
                      value: state.themeMode == ThemeMode.dark,
                      onChanged: (value) => cubit.setThemeMode(value ? ThemeMode.dark : ThemeMode.light),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.languageLabel),
                    trailing: DropdownButton<String>(
                      isDense: true,
                      value: state.locale?.languageCode ?? 'system',
                      onChanged: (value) {
                        if (value == null || value == 'system') {
                          cubit.setLocale(null);
                          return;
                        }
                        cubit.setLocale(Locale(value));
                      },
                      items: [
                        DropdownMenuItem(value: 'system', child: Text(l10n.systemDefault)),
                        DropdownMenuItem(value: 'en', child: Text(l10n.englishLanguage)),
                        DropdownMenuItem(value: 'id', child: Text(l10n.indonesianLanguage)),
                      ],
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.budgetNotificationsLabel),
                    trailing: Switch(
                      value: state.notificationsEnabled,
                      onChanged: (value) => cubit.setNotificationsEnabled(value),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: state.backupInProgress
                        ? null
                        : () async {
                            await HapticFeedback.mediumImpact();
                            await cubit.backupNow();
                          },
                    icon: const Icon(Icons.cloud_upload),
                    label: Text(l10n.backupNow),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.lastBackupAt == null
                        ? l10n.noBackupHistory
                        : l10n.lastBackupLabel(
                            DateFormat.yMd(localeTag).add_Hm().format(state.lastBackupAt!.toLocal()),
                          ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: state.backupInProgress
                        ? null
                        : () async {
                            await HapticFeedback.selectionClick();
                            await cubit.loadRestorePreview();
                          },
                    icon: const Icon(Icons.restore),
                    label: Text(l10n.restorePreview),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: state.backupInProgress
                        ? null
                        : () async {
                            await HapticFeedback.selectionClick();
                            await cubit.scheduleAutoBackupValidation();
                          },
                    icon: const Icon(Icons.schedule_send_outlined),
                    label: Text(l10n.validateAutoBackupLabel),
                  ),
                  const SizedBox(height: 8),
                  _AutoBackupStatus(state: state),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: state.backupInProgress ? null : () => _confirmResetLocalData(context),
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: Text(l10n.resetLocalDataLabel),
                  ),
                  const SizedBox(height: 16),
                  Lottie.asset(LottiePlaceholders.backupAnimation, height: 140),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: () => _confirmSignOut(context),
                    icon: const Icon(Icons.logout),
                    label: Text(l10n.signOutLabel),
                  ),
                  const SizedBox(height: 12),
                  if (state.restorePreview.isEmpty)
                    Text(l10n.noBackupFiles)
                  else
                    ...state.restorePreview.map((file) {
                      final createdAt = file.createdAt == null
                          ? '-'
                          : DateFormat.yMMMd(localeTag).add_Hm().format(file.createdAt!.toLocal());
                      final fileSize = file.size.toReadableBytes();
                      return Card(
                        child: ListTile(
                          title: Text(file.name),
                          subtitle: Text('$createdAt • $fileSize'),
                          trailing: IconButton(
                            icon: const Icon(Icons.download),
                            tooltip: l10n.restoreActionLabel,
                            onPressed: () => _confirmRestore(context, file.id),
                          ),
                        ),
                      );
                    }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmResetLocalData(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.resetLocalDataLabel),
          content: Text(l10n.resetLocalDataConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.resetActionLabel),
            ),
          ],
        );
      },
    );

    if (approved == true && context.mounted) {
      await context.read<SettingsCubit>().resetLocalData();
      if (!context.mounted) {
        return;
      }
      await context.read<TransactionCubit>().loadTransactions();
      await context.read<BudgetCubit>().loadBudgets();
      await context.read<DashboardCubit>().loadOverview();
    }
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.signOutLabel),
          content: Text(l10n.signOutConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.signOutLabel),
            ),
          ],
        );
      },
    );

    if (approved == true && context.mounted) {
      await context.read<AuthCubit>().signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.root, (_) => false);
      }
    }
  }

  Future<void> _confirmRestore(BuildContext context, String fileId) async {
    final l10n = AppLocalizations.of(context);
    final shouldRestore = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.restoreConfirmTitle),
          content: Text(l10n.restoreConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.restoreActionLabel),
            ),
          ],
        );
      },
    );

    if (shouldRestore == true) {
      await context.read<SettingsCubit>().restoreByFileId(fileId);
    }
  }

  Future<void> _refreshAfterRestore(BuildContext context) async {
    if (!context.mounted) {
      return;
    }
    await context.read<TransactionCubit>().loadTransactions();
    if (!context.mounted) {
      return;
    }
    await context.read<BudgetCubit>().loadBudgets();
    if (!context.mounted) {
      return;
    }
    await context.read<DashboardCubit>().loadOverview();
  }

  String _errorMessage(AppLocalizations l10n, String rawMessage) {
    final lower = rawMessage.toLowerCase();
    if (lower.contains('backup file invalid or corrupted')) {
      return l10n.backupInvalidFile;
    }
    if (lower.contains('backup checksum mismatch')) {
      return l10n.backupChecksumMismatch;
    }
    return rawMessage;
  }
}

class _AutoBackupStatus extends StatelessWidget {
  const _AutoBackupStatus({required this.state});

  final SettingsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final attempt = state.autoBackupLastAttemptAt == null
        ? l10n.autoBackupNeverRun
        : l10n.autoBackupLastAttempt(
            DateFormat.yMd(localeTag).add_Hm().format(state.autoBackupLastAttemptAt!.toLocal()),
          );
    final success = state.autoBackupLastSuccessAt == null
        ? l10n.autoBackupNoSuccessYet
        : l10n.autoBackupLastSuccess(
            DateFormat.yMd(localeTag).add_Hm().format(state.autoBackupLastSuccessAt!.toLocal()),
          );
    final error = state.autoBackupLastError;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.autoBackupStatusTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => context.read<SettingsCubit>().refreshAutoBackupTelemetry(),
                  tooltip: l10n.refreshLabel,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(attempt),
            const SizedBox(height: 4),
            Text(success),
            if (error != null && error.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                l10n.autoBackupLastError(error),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
