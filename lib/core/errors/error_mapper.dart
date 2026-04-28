import 'package:fin_sage/core/errors/app_error_codes.dart';
import 'package:fin_sage/core/errors/app_exception.dart';

String mapErrorMessage(Object error) {
  if (error is AppException) {
    if (error.code != null && error.code!.isNotEmpty) {
      return error.code!;
    }
    return error.message;
  }

  final raw = error.toString().trim();
  if (raw.isEmpty) {
    return AppErrorCodes.unexpectedError;
  }

  const prefixes = <String>[
    'Exception: ',
    'Exception:',
    'StateError: ',
    'Bad state: ',
    'ArgumentError: ',
    'Invalid argument(s): ',
  ];

  for (final prefix in prefixes) {
    if (raw.startsWith(prefix)) {
      final stripped = raw.substring(prefix.length).trim();
      return stripped.isEmpty ? AppErrorCodes.unexpectedError : stripped;
    }
  }

  return raw;
}
