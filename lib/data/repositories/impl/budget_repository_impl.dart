import 'package:fin_sage/data/datasources/local/local_database_datasource.dart';
import 'package:fin_sage/data/models/budget_model.dart';
import 'package:fin_sage/data/repositories/budget_repository.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  BudgetRepositoryImpl(this._local);

  final LocalDatabaseDataSource _local;

  @override
  Future<List<BudgetModel>> fetchBudgets() => _local.getBudgets();

  @override
  Future<void> saveBudget(BudgetModel budget) => _local.saveBudget(budget);

  @override
  Future<void> deleteBudget(int budgetId) => _local.deleteBudget(budgetId);
}
