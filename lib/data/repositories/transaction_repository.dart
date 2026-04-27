import 'package:fin_sage/data/models/category_model.dart';
import 'package:fin_sage/data/models/transaction_model.dart';

abstract class TransactionRepository {
  Future<List<TransactionModel>> fetchTransactions();
  Future<void> saveTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(int transactionId);
  Future<List<CategoryModel>> fetchCategories();
  Future<Map<String, double>> monthlySummary();
}
