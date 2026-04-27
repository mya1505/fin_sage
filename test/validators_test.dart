import 'package:fin_sage/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.amount', () {
    test('returns required error for empty', () {
      expect(Validators.amount(''), 'amountRequired');
    });

    test('returns invalid error for non numeric', () {
      expect(Validators.amount('abc'), 'amountInvalid');
    });

    test('returns null for valid amount', () {
      expect(Validators.amount('12000.50'), isNull);
    });
  });
}
