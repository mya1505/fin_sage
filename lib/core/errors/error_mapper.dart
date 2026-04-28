import 'package:fin_sage/core/errors/app_exception.dart';

String mapErrorMessage(Object error) {
  if (error is AppException) {
    return error.message;
  }

  final raw = error.toString().trim();
  if (raw.isEmpty) {
    return 'Unexpected error';
  }

  const prefixes = <String>[
    'Exception: ',
    'StateError: ',
    'ArgumentError: ',
    'Invalid argument(s): ',
  ];

  for (final prefix in prefixes) {
    if (raw.startsWith(prefix)) {
      return raw.substring(prefix.length).trim();
    }
  }

  return raw;
}
