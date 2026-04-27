import 'package:fin_sage/data/datasources/local/settings_storage.dart';
import 'package:fin_sage/data/models/backup_file_model.dart';
import 'package:equatable/equatable.dart';
import 'package:fin_sage/data/repositories/backup_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const Object _keepError = Object();

enum SettingsOperation { none, backup, preview, restore }

class SettingsState extends Equatable {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.locale,
    this.backupInProgress = false,
    this.restorePreview = const [],
    this.lastCompletedOperation = SettingsOperation.none,
    this.error,
  });

  final ThemeMode themeMode;
  final Locale? locale;
  final bool backupInProgress;
  final List<BackupFileModel> restorePreview;
  final SettingsOperation lastCompletedOperation;
  final String? error;

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool clearLocale = false,
    bool? backupInProgress,
    List<BackupFileModel>? restorePreview,
    SettingsOperation? lastCompletedOperation,
    Object? error = _keepError,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: clearLocale ? null : locale ?? this.locale,
      backupInProgress: backupInProgress ?? this.backupInProgress,
      restorePreview: restorePreview ?? this.restorePreview,
      lastCompletedOperation: lastCompletedOperation ?? this.lastCompletedOperation,
      error: identical(error, _keepError) ? this.error : error as String?,
    );
  }

  @override
  List<Object?> get props => [
        themeMode,
        locale,
        backupInProgress,
        restorePreview,
        lastCompletedOperation,
        error,
      ];
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repo, this._settingsStorage) : super(const SettingsState());

  final BackupRepository _repo;
  final SettingsStorage _settingsStorage;

  Future<void> loadSettings() async {
    try {
      final mode = await _settingsStorage.loadThemeMode();
      final locale = await _settingsStorage.loadLocale();
      emit(
        state.copyWith(
          themeMode: mode,
          locale: locale,
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

  Future<void> backupNow() async {
    emit(
      state.copyWith(
        backupInProgress: true,
        lastCompletedOperation: SettingsOperation.none,
        error: null,
      ),
    );
    try {
      await _repo.backupNow();
      emit(
        state.copyWith(
          backupInProgress: false,
          lastCompletedOperation: SettingsOperation.backup,
        ),
      );
    } catch (e) {
      emit(state.copyWith(backupInProgress: false, error: e.toString()));
    }
  }

  Future<void> loadRestorePreview() async {
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
}
