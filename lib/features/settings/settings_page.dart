import 'package:fin_sage/core/constants/lottie_placeholders.dart';
import 'package:fin_sage/core/errors/error_boundary.dart';
import 'package:fin_sage/l10n/generated/app_localizations.dart';
import 'package:fin_sage/logic/settings/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ErrorBoundary(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.settingsTitle)),
        body: SafeArea(
          child: BlocBuilder<SettingsCubit, SettingsState>(
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
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: state.backupInProgress ? null : cubit.backupNow,
                    icon: const Icon(Icons.cloud_upload),
                    label: Text(l10n.backupNow),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: state.backupInProgress ? null : cubit.loadRestorePreview,
                    icon: const Icon(Icons.restore),
                    label: Text(l10n.restorePreview),
                  ),
                  const SizedBox(height: 16),
                  Lottie.asset(LottiePlaceholders.backupAnimation, height: 140),
                  const SizedBox(height: 12),
                  ...state.restorePreview.map((file) {
                    final createdAt = file.createdAt?.toIso8601String() ?? '-';
                    return Card(
                      child: ListTile(
                        title: Text(file.name),
                        subtitle: Text('$createdAt • ${file.size} bytes'),
                        trailing: IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () => cubit.restoreByFileId(file.id),
                        ),
                      ),
                    );
                  }),
                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        state.error!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
