import 'package:equatable/equatable.dart';
import 'package:fin_sage/data/repositories/backup_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.backupInProgress = false,
    this.restorePreview = const [],
    this.error,
  });

  final ThemeMode themeMode;
  final bool backupInProgress;
  final List<String> restorePreview;
  final String? error;

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? backupInProgress,
    List<String>? restorePreview,
    String? error,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      backupInProgress: backupInProgress ?? this.backupInProgress,
      restorePreview: restorePreview ?? this.restorePreview,
      error: error,
    );
  }

  @override
  List<Object?> get props => [themeMode, backupInProgress, restorePreview, error];
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repo) : super(const SettingsState());

  final BackupRepository _repo;

  Future<void> loadSettings() async {}

  void setThemeMode(ThemeMode mode) {
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> backupNow() async {
    emit(state.copyWith(backupInProgress: true, error: null));
    try {
      await _repo.backupNow();
      emit(state.copyWith(backupInProgress: false));
    } catch (e) {
      emit(state.copyWith(backupInProgress: false, error: e.toString()));
    }
  }

  Future<void> loadRestorePreview() async {
    emit(state.copyWith(backupInProgress: true, error: null));
    try {
      final preview = await _repo.restorePreview();
      emit(state.copyWith(backupInProgress: false, restorePreview: preview));
    } catch (e) {
      emit(state.copyWith(backupInProgress: false, error: e.toString()));
    }
  }

  Future<void> restoreByFileId(String fileId) async {
    emit(state.copyWith(backupInProgress: true, error: null));
    try {
      await _repo.restoreFromFile(fileId);
      emit(state.copyWith(backupInProgress: false));
    } catch (e) {
      emit(state.copyWith(backupInProgress: false, error: e.toString()));
    }
  }
}
