class Validators {
  static String? amount(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 'amountRequired';
    }
    final value = double.tryParse(input.replaceAll(',', '.'));
    if (value == null) {
      return 'amountInvalid';
    }
    if (value <= 0) {
      return 'amountMustBePositive';
    }
    if (value > 1000000000000) {
      return 'amountTooLarge';
    }
    return null;
  }

  static String? requiredDate(DateTime? input) {
    if (input == null) {
      return 'dateRequired';
    }
    final now = DateTime.now();
    if (input.isAfter(now.add(const Duration(days: 1)))) {
      return 'dateFutureNotAllowed';
    }
    return null;
  }
}
