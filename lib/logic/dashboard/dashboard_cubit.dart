import 'package:equatable/equatable.dart';
import 'package:fin_sage/core/errors/error_mapper.dart';
import 'package:fin_sage/data/models/transaction_model.dart';
import 'package:fin_sage/data/repositories/transaction_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardState extends Equatable {
  const DashboardState({
    this.loading = false,
    this.income = 0,
    this.expense = 0,
    this.recentTransactions = const [],
    this.monthlyTransactionCount = 0,
    this.error,
  });

  final bool loading;
  final double income;
  final double expense;
  final List<TransactionModel> recentTransactions;
  final int monthlyTransactionCount;
  final String? error;

  double get balance => income - expense;

  DashboardState copyWith({
    bool? loading,
    double? income,
    double? expense,
    List<TransactionModel>? recentTransactions,
    int? monthlyTransactionCount,
    String? error,
  }) {
    return DashboardState(
      loading: loading ?? this.loading,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      monthlyTransactionCount: monthlyTransactionCount ?? this.monthlyTransactionCount,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        income,
        expense,
        recentTransactions,
        monthlyTransactionCount,
        error,
      ];
}

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._repo) : super(const DashboardState());

  final TransactionRepository _repo;

  Future<void> loadOverview() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final result = await Future.wait([
        _repo.monthlySummary(),
        _repo.fetchTransactions(),
      ]);
      final summary = result[0] as Map<String, double>;
      final transactions = result[1] as List<TransactionModel>;
      final now = DateTime.now();
      final monthlyCount = transactions
          .where((tx) => tx.date.year == now.year && tx.date.month == now.month)
          .length;

      emit(
        state.copyWith(
          loading: false,
          income: summary['income'] ?? 0,
          expense: summary['expense'] ?? 0,
          recentTransactions: transactions.take(5).toList(),
          monthlyTransactionCount: monthlyCount,
        ),
      );
    } catch (e) {
      emit(state.copyWith(loading: false, error: mapErrorMessage(e)));
    }
  }
}
