import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AutoBackupTelemetry extends Equatable {
  const AutoBackupTelemetry({
    this.lastAttemptAt,
    this.lastSuccessAt,
    this.lastError,
  });

  final DateTime? lastAttemptAt;
  final DateTime? lastSuccessAt;
  final String? lastError;

  @override
  List<Object?> get props => [lastAttemptAt, lastSuccessAt, lastError];
}

abstract class AutoBackupTelemetryStorage {
  Future<AutoBackupTelemetry> loadTelemetry();
  Future<void> markAttempt(DateTime timestamp);
  Future<void> markSuccess(DateTime timestamp);
  Future<void> markFailure(DateTime timestamp, String error);
}

class SharedPrefsAutoBackupTelemetryStorage implements AutoBackupTelemetryStorage {
  SharedPrefsAutoBackupTelemetryStorage(this._prefs);

  static const String lastAttemptAtKey = 'backup.auto.last_attempt_at';
  static const String lastSuccessAtKey = 'backup.auto.last_success_at';
  static const String lastErrorKey = 'backup.auto.last_error';
  static const int _maxErrorLength = 500;

  final SharedPreferences _prefs;

  @override
  Future<AutoBackupTelemetry> loadTelemetry() async {
    final lastAttemptRaw = _prefs.getString(lastAttemptAtKey);
    final lastSuccessRaw = _prefs.getString(lastSuccessAtKey);
    final lastErrorRaw = _prefs.getString(lastErrorKey);

    return AutoBackupTelemetry(
      lastAttemptAt: _parseDate(lastAttemptRaw),
      lastSuccessAt: _parseDate(lastSuccessRaw),
      lastError: (lastErrorRaw == null || lastErrorRaw.isEmpty) ? null : lastErrorRaw,
    );
  }

  @override
  Future<void> markAttempt(DateTime timestamp) async {
    await _prefs.setString(lastAttemptAtKey, timestamp.toIso8601String());
  }

  @override
  Future<void> markSuccess(DateTime timestamp) async {
    await _prefs.setString(lastAttemptAtKey, timestamp.toIso8601String());
    await _prefs.setString(lastSuccessAtKey, timestamp.toIso8601String());
    await _prefs.remove(lastErrorKey);
  }

  @override
  Future<void> markFailure(DateTime timestamp, String error) async {
    await _prefs.setString(lastAttemptAtKey, timestamp.toIso8601String());
    final normalized = error.trim();
    final limited = normalized.length <= _maxErrorLength
        ? normalized
        : normalized.substring(0, _maxErrorLength);
    await _prefs.setString(lastErrorKey, limited);
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }
}
