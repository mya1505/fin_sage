import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class AppEventLogger {
  static void info(String event, {Map<String, Object?> data = const {}}) {
    _log(level: 'info', event: event, data: data);
  }

  static void warning(String event, {Map<String, Object?> data = const {}}) {
    _log(level: 'warning', event: event, data: data);
  }

  static void error(
    String event, {
    Map<String, Object?> data = const {},
    Object? error,
  }) {
    final payload = <String, Object?>{
      ...data,
      if (error != null) 'error': error.toString(),
    };
    _log(level: 'error', event: event, data: payload);
  }

  static void _log({
    required String level,
    required String event,
    required Map<String, Object?> data,
  }) {
    final normalized = <String, Object?>{};
    data.forEach((key, value) {
      normalized[key] = _normalizeValue(value);
    });

    final payload = <String, Object?>{
      'level': level,
      'event': event,
      'data': normalized,
      'ts': DateTime.now().toUtc().toIso8601String(),
    };

    debugPrint('[FinSageEvent] ${jsonEncode(payload)}');
    try {
      unawaited(
        Sentry.addBreadcrumb(
          Breadcrumb(
            category: 'finsage.$level',
            message: event,
            data: normalized.map((k, v) => MapEntry(k, v?.toString())),
            level: _toSentryLevel(level),
          ),
        ),
      );
    } catch (_) {
      // Keep logger non-blocking in all runtime contexts (tests/background isolate).
    }
  }

  static Object? _normalizeValue(Object? value) {
    if (value == null || value is num || value is bool || value is String) {
      return value;
    }
    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }
    if (value is Duration) {
      return value.inMilliseconds;
    }
    return value.toString();
  }

  static SentryLevel _toSentryLevel(String level) {
    switch (level) {
      case 'error':
        return SentryLevel.error;
      case 'warning':
        return SentryLevel.warning;
      default:
        return SentryLevel.info;
    }
  }
}
