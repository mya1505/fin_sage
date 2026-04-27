import 'package:equatable/equatable.dart';
import 'package:fin_sage/data/repositories/transaction_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardState extends Equatable {
  const DashboardState({
    this.loading = false,
    this.income = 0,
    this.expense = 0,
    this.error,
  });

  final bool loading;
  final double income;
  final double expense;
  final String? error;

  double get balance => income - expense;

  DashboardState copyWith({bool? loading, double? income, double? expense, String? error}) {
    return DashboardState(
      loading: loading ?? this.loading,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, income, expense, error];
}

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._repo) : super(const DashboardState());

  final TransactionRepository _repo;

  Future<void> loadOverview() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final summary = await _repo.monthlySummary();
      emit(
        state.copyWith(
          loading: false,
          income: summary['income'] ?? 0,
          expense: summary['expense'] ?? 0,
        ),
      );
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }
}
