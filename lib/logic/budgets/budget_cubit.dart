import 'package:equatable/equatable.dart';
import 'package:fin_sage/data/models/budget_model.dart';
import 'package:fin_sage/data/repositories/budget_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BudgetState extends Equatable {
  const BudgetState({this.loading = false, this.items = const [], this.error});

  final bool loading;
  final List<BudgetModel> items;
  final String? error;

  BudgetState copyWith({bool? loading, List<BudgetModel>? items, String? error}) {
    return BudgetState(
      loading: loading ?? this.loading,
      items: items ?? this.items,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, items, error];
}

class BudgetCubit extends Cubit<BudgetState> {
  BudgetCubit(this._repo) : super(const BudgetState());

  final BudgetRepository _repo;

  Future<void> loadBudgets() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final items = await _repo.fetchBudgets();
      emit(state.copyWith(loading: false, items: items));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> saveBudget(BudgetModel model) async {
    await _repo.saveBudget(model);
    await loadBudgets();
  }
}
