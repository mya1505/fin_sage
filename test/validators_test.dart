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

  group('Validators.categoryName', () {
    test('returns required error for empty', () {
      expect(Validators.categoryName(''), 'categoryNameRequired');
    });

    test('returns too long error for over 30 chars', () {
      expect(Validators.categoryName('abcdefghijklmnopqrstuvwxyz12345'), 'categoryNameTooLong');
    });

    test('returns null for valid category name', () {
      expect(Validators.categoryName('Utilities'), isNull);
    });
  });

  group('Validators.hexColor', () {
    test('returns null for empty value', () {
      expect(Validators.hexColor(''), isNull);
    });

    test('returns invalid error for malformed hex', () {
      expect(Validators.hexColor('#12ABZ9'), 'invalidColorHex');
    });

    test('returns null for valid hex color', () {
      expect(Validators.hexColor('#0D3B66'), isNull);
    });
  });
}
