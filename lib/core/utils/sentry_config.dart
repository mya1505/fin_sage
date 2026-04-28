class SentryConfig {
  static const double defaultTraceSampleRate = 0.1;

  static double resolveTraceSampleRate(String raw) {
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed < 0 || parsed > 1) {
      return defaultTraceSampleRate;
    }
    return parsed;
  }
}
