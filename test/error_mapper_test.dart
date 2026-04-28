import 'package:fin_sage/core/errors/app_exception.dart';
import 'package:fin_sage/core/errors/error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns app exception code when available', () {
    const error = AppException('custom message', code: 'x');
    expect(mapErrorMessage(error), 'x');
  });

  test('falls back to app exception message when code is absent', () {
    const error = AppException('custom message');
    expect(mapErrorMessage(error), 'custom message');
  });

  test('strips standard exception prefixes', () {
    expect(mapErrorMessage(Exception('x failed')), 'x failed');
    expect(mapErrorMessage(StateError('state failed')), 'state failed');
  });

  test('falls back to string value for unknown errors', () {
    expect(mapErrorMessage(42), '42');
  });
}
