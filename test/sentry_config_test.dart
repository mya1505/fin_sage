import 'package:fin_sage/core/utils/sentry_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolveTraceSampleRate returns parsed value when valid', () {
    expect(SentryConfig.resolveTraceSampleRate('0'), 0);
    expect(SentryConfig.resolveTraceSampleRate('0.5'), 0.5);
    expect(SentryConfig.resolveTraceSampleRate('1'), 1);
  });

  test('resolveTraceSampleRate falls back when invalid', () {
    expect(
      SentryConfig.resolveTraceSampleRate('invalid'),
      SentryConfig.defaultTraceSampleRate,
    );
    expect(
      SentryConfig.resolveTraceSampleRate('-0.1'),
      SentryConfig.defaultTraceSampleRate,
    );
    expect(
      SentryConfig.resolveTraceSampleRate('1.1'),
      SentryConfig.defaultTraceSampleRate,
    );
  });
}
