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
    final today = DateTime.now();
    final selectedDate = DateTime(input.year, input.month, input.day);
    final maxAllowed = DateTime(today.year, today.month, today.day);
    if (selectedDate.isAfter(maxAllowed)) {
      return 'dateFutureNotAllowed';
    }
    return null;
  }

  static String? categoryName(String? input) {
    final value = input?.trim() ?? '';
    if (value.isEmpty) {
      return 'categoryNameRequired';
    }
    if (value.length > 30) {
      return 'categoryNameTooLong';
    }
    return null;
  }

  static String? hexColor(String? input) {
    final value = (input ?? '').trim();
    final regex = RegExp(r'^#[0-9a-fA-F]{6}$');
    if (value.isEmpty) {
      return null;
    }
    if (!regex.hasMatch(value)) {
      return 'invalidColorHex';
    }
    return null;
  }
}
