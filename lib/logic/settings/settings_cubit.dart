import 'package:fin_sage/data/datasources/local/auto_backup_telemetry_storage.dart';
import 'package:fin_sage/data/datasources/local/local_database_datasource.dart';
import 'package:fin_sage/data/datasources/local/settings_storage.dart';
import 'package:fin_sage/data/models/backup_file_model.dart';
import 'package:equatable/equatable.dart';
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
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(state.copyWith(themeMode: mode, error: null));
    try {
      await _settingsStorage.saveThemeMode(mode);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
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
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    emit(state.copyWith(notificationsEnabled: enabled, error: null));
    try {
      await _settingsStorage.saveNotificationsEnabled(enabled);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> backupNow() async {
    if (state.backupInProgress) {
      return;
    }
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
    } catch (e) {
      emit(state.copyWith(backupInProgress: false, error: e.toString()));
    }
  }

  Future<void> scheduleAutoBackupValidation() async {
    if (state.backupInProgress) {
      return;
    }
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
    } catch (e) {
      emit(state.copyWith(backupInProgress: false, error: e.toString()));
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
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> loadRestorePreview() async {
    if (state.backupInProgress) {
      return;
    }
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
    } catch (e) {
      emit(state.copyWith(backupInProgress: false, error: e.toString()));
    }
  }

  Future<void> restoreByFileId(String fileId) async {
    if (state.backupInProgress) {
      return;
    }
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
    } catch (e) {
      emit(state.copyWith(backupInProgress: false, error: e.toString()));
    }
  }

  Future<void> resetLocalData() async {
    if (state.backupInProgress) {
      return;
    }
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
    } catch (e) {
      emit(state.copyWith(backupInProgress: false, error: e.toString()));
    }
  }
}
