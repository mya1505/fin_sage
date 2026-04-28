import 'package:fin_sage/data/datasources/local/auto_backup_telemetry_storage.dart';
import 'package:fin_sage/data/datasources/local/local_database_datasource.dart';
import 'package:fin_sage/data/datasources/local/settings_storage.dart';
import 'package:fin_sage/data/models/backup_file_model.dart';
import 'package:equatable/equatable.dart';
import 'package:fin_sage/core/errors/error_mapper.dart';
import 'package:fin_sage/core/utils/app_event_logger.dart';
import 'package:fin_sage/data/repositories/backup_repository.dart';
import 'package:fin_sage/features/settings/backup_scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const Object _keepError = Object();

enum SettingsOperation { none, backup, preview, restore, reset, autoBackupValidation }

class SettingsState extends Equatable {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.locale,
    this.notificationsEnabled = true,
    this.lastBackupAt,
    this.backupInProgress = false,
    this.restorePreview = const [],
    this.autoBackupLastAttemptAt,
    this.autoBackupLastSuccessAt,
    this.autoBackupLastError,
    this.lastCompletedOperation = SettingsOperation.none,
    this.error,
  });

  final ThemeMode themeMode;
  final Locale? locale;
  final bool notificationsEnabled;
  final DateTime? lastBackupAt;
  final bool backupInProgress;
  final List<BackupFileModel> restorePreview;
  final DateTime? autoBackupLastAttemptAt;
  final DateTime? autoBackupLastSuccessAt;
  final String? autoBackupLastError;
  final SettingsOperation lastCompletedOperation;
  final String? error;

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool clearLocale = false,
    bool? notificationsEnabled,
    DateTime? lastBackupAt,
    bool? backupInProgress,
    List<BackupFileModel>? restorePreview,
    DateTime? autoBackupLastAttemptAt,
    DateTime? autoBackupLastSuccessAt,
    Object? autoBackupLastError = _keepError,
    SettingsOperation? lastCompletedOperation,
    Object? error = _keepError,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: clearLocale ? null : locale ?? this.locale,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      backupInProgress: backupInProgress ?? this.backupInProgress,
      restorePreview: restorePreview ?? this.restorePreview,
      autoBackupLastAttemptAt: autoBackupLastAttemptAt ?? this.autoBackupLastAttemptAt,
      autoBackupLastSuccessAt: autoBackupLastSuccessAt ?? this.autoBackupLastSuccessAt,
      autoBackupLastError: identical(autoBackupLastError, _keepError)
          ? this.autoBackupLastError
          : autoBackupLastError as String?,
      lastCompletedOperation: lastCompletedOperation ?? this.lastCompletedOperation,
      error: identical(error, _keepError) ? this.error : error as String?,
    );
  }

  @override
  List<Object?> get props => [
        themeMode,
        locale,
        notificationsEnabled,
        lastBackupAt,
        backupInProgress,
        restorePreview,
        autoBackupLastAttemptAt,
        autoBackupLastSuccessAt,
        autoBackupLastError,
        lastCompletedOperation,
        error,
      ];
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(
    this._repo,
    this._settingsStorage,
    this._localDatabaseDataSource,
    this._telemetryStorage,
    this._validationScheduler,
  )
      : super(const SettingsState());

  final BackupRepository _repo;
  final SettingsStorage _settingsStorage;
  final LocalDatabaseDataSource _localDatabaseDataSource;
  final AutoBackupTelemetryStorage _telemetryStorage;
  final AutoBackupValidationScheduler _validationScheduler;

  Future<void> loadSettings() async {
    try {
      final mode = await _settingsStorage.loadThemeMode();
      final locale = await _settingsStorage.loadLocale();
      final notificationsEnabled = await _settingsStorage.loadNotificationsEnabled();
      final lastBackupAt = await _settingsStorage.loadLastBackupAt();
      final telemetry = await _telemetryStorage.loadTelemetry();
      emit(
        state.copyWith(
          themeMode: mode,
          locale: locale,
          notificationsEnabled: notificationsEnabled,
          lastBackupAt: lastBackupAt,
          autoBackupLastAttemptAt: telemetry.lastAttemptAt,
          autoBackupLastSuccessAt: telemetry.lastSuccessAt,
          autoBackupLastError: telemetry.lastError,
          lastCompletedOperation: SettingsOperation.none,
          error: null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: mapErrorMessage(e)));
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(state.copyWith(themeMode: mode, error: null));
    try {
      await _settingsStorage.saveThemeMode(mode);
    } catch (e) {
      emit(state.copyWith(error: mapErrorMessage(e)));
    }
  }

  Future<void> setLocale(Locale? locale) async {
    emit(state.copyWith(error: null));
    try {
      if (locale == null) {
        emit(state.copyWith(clearLocale: true));
        await _settingsStorage.saveLocale(null);
        return;
      }

      emit(state.copyWith(locale: locale));
      await _settingsStorage.saveLocale(locale);
    } catch (e) {
      emit(state.copyWith(error: mapErrorMessage(e)));
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    emit(state.copyWith(notificationsEnabled: enabled, error: null));
    try {
      await _settingsStorage.saveNotificationsEnabled(enabled);
    } catch (e) {
      emit(state.copyWith(error: mapErrorMessage(e)));
    }
  }

  Future<void> backupNow() async {
    if (state.backupInProgress) {
      AppEventLogger.warning('settings.backup.ignored_in_progress');
      return;
    }
    AppEventLogger.info('settings.backup.started');
    emit(
      state.copyWith(
        backupInProgress: true,
        lastCompletedOperation: SettingsOperation.none,
        error: null,
      ),
    );
    try {
      await _repo.backupNow();
      final now = DateTime.now();
      await _settingsStorage.saveLastBackupAt(now);
      emit(
        state.copyWith(
          backupInProgress: false,
          lastBackupAt: now,
          lastCompletedOperation: SettingsOperation.backup,
        ),
      );
      AppEventLogger.info('settings.backup.completed', data: {'last_backup_at': now});
    } catch (e) {
      AppEventLogger.error('settings.backup.failed', error: e);
      emit(state.copyWith(backupInProgress: false, error: mapErrorMessage(e)));
    }
  }

  Future<void> scheduleAutoBackupValidation() async {
    if (state.backupInProgress) {
      AppEventLogger.warning('settings.auto_backup_validation.ignored_in_progress');
      return;
    }
    AppEventLogger.info('settings.auto_backup_validation.started');
    emit(
      state.copyWith(
        backupInProgress: true,
        lastCompletedOperation: SettingsOperation.none,
        error: null,
      ),
    );
    try {
      await _validationScheduler.scheduleValidationNow();
      final telemetry = await _telemetryStorage.loadTelemetry();
      emit(
        state.copyWith(
          backupInProgress: false,
          autoBackupLastAttemptAt: telemetry.lastAttemptAt,
          autoBackupLastSuccessAt: telemetry.lastSuccessAt,
          autoBackupLastError: telemetry.lastError,
          lastCompletedOperation: SettingsOperation.autoBackupValidation,
        ),
      );
      AppEventLogger.info('settings.auto_backup_validation.scheduled');
    } catch (e) {
      AppEventLogger.error('settings.auto_backup_validation.failed', error: e);
      emit(state.copyWith(backupInProgress: false, error: mapErrorMessage(e)));
    }
  }

  Future<void> refreshAutoBackupTelemetry() async {
    try {
      final telemetry = await _telemetryStorage.loadTelemetry();
      emit(
        state.copyWith(
          autoBackupLastAttemptAt: telemetry.lastAttemptAt,
          autoBackupLastSuccessAt: telemetry.lastSuccessAt,
          autoBackupLastError: telemetry.lastError,
          error: null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: mapErrorMessage(e)));
    }
  }

  Future<void> loadRestorePreview() async {
    if (state.backupInProgress) {
      AppEventLogger.warning('settings.restore_preview.ignored_in_progress');
      return;
    }
    AppEventLogger.info('settings.restore_preview.started');
    emit(
      state.copyWith(
        backupInProgress: true,
        lastCompletedOperation: SettingsOperation.none,
        error: null,
      ),
    );
    try {
      final preview = await _repo.restorePreview();
      emit(
        state.copyWith(
          backupInProgress: false,
          restorePreview: preview,
          lastCompletedOperation: SettingsOperation.preview,
        ),
      );
      AppEventLogger.info(
        'settings.restore_preview.completed',
        data: {'files_count': preview.length},
      );
    } catch (e) {
      AppEventLogger.error('settings.restore_preview.failed', error: e);
      emit(state.copyWith(backupInProgress: false, error: mapErrorMessage(e)));
    }
  }

  Future<void> restoreByFileId(String fileId) async {
    if (state.backupInProgress) {
      AppEventLogger.warning(
        'settings.restore.ignored_in_progress',
        data: {'file_id': fileId},
      );
      return;
    }
    AppEventLogger.info('settings.restore.started', data: {'file_id': fileId});
    emit(
      state.copyWith(
        backupInProgress: true,
        lastCompletedOperation: SettingsOperation.none,
        error: null,
      ),
    );
    try {
      await _repo.restoreFromFile(fileId);
      emit(
        state.copyWith(
          backupInProgress: false,
          lastCompletedOperation: SettingsOperation.restore,
        ),
      );
      AppEventLogger.info('settings.restore.completed', data: {'file_id': fileId});
    } catch (e) {
      AppEventLogger.error(
        'settings.restore.failed',
        data: {'file_id': fileId},
        error: e,
      );
      emit(state.copyWith(backupInProgress: false, error: mapErrorMessage(e)));
    }
  }

  Future<void> resetLocalData() async {
    if (state.backupInProgress) {
      AppEventLogger.warning('settings.reset_local_data.ignored_in_progress');
      return;
    }
    AppEventLogger.info('settings.reset_local_data.started');
    emit(
      state.copyWith(
        backupInProgress: true,
        lastCompletedOperation: SettingsOperation.none,
        error: null,
      ),
    );
    try {
      await _localDatabaseDataSource.resetLocalData();
      emit(
        state.copyWith(
          backupInProgress: false,
          restorePreview: const [],
          lastCompletedOperation: SettingsOperation.reset,
        ),
      );
      AppEventLogger.info('settings.reset_local_data.completed');
    } catch (e) {
      AppEventLogger.error('settings.reset_local_data.failed', error: e);
      emit(state.copyWith(backupInProgress: false, error: mapErrorMessage(e)));
    }
  }
}
