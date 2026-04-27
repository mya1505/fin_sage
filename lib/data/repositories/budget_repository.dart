import 'package:fin_sage/data/models/budget_model.dart';

abstract class BudgetRepository {
  Future<List<BudgetModel>> fetchBudgets();
  Future<void> saveBudget(BudgetModel budget);
}
