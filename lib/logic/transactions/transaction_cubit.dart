import 'package:equatable/equatable.dart';
import 'package:fin_sage/data/models/category_model.dart';
import 'package:fin_sage/data/models/transaction_model.dart';
import 'package:fin_sage/data/repositories/transaction_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransactionState extends Equatable {
  const TransactionState({
    this.loading = false,
    this.items = const [],
    this.categories = const [],
    this.error,
  });

  final bool loading;
  final List<TransactionModel> items;
  final List<CategoryModel> categories;
  final String? error;

  TransactionState copyWith({
    bool? loading,
    List<TransactionModel>? items,
    List<CategoryModel>? categories,
    String? error,
  }) {
    return TransactionState(
      loading: loading ?? this.loading,
      items: items ?? this.items,
      categories: categories ?? this.categories,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, items, categories, error];
}

class TransactionCubit extends Cubit<TransactionState> {
  TransactionCubit(this._repo) : super(const TransactionState());

  final TransactionRepository _repo;

  Future<void> loadTransactions() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final result = await Future.wait([
        _repo.fetchTransactions(),
        _repo.fetchCategories(),
      ]);
      emit(
        state.copyWith(
          loading: false,
          items: result[0] as List<TransactionModel>,
          categories: result[1] as List<CategoryModel>,
        ),
      );
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> createTransaction(TransactionModel model) async {
    emit(state.copyWith(error: null));
    try {
      await _repo.saveTransaction(model);
      await loadTransactions();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> removeTransaction(int id) async {
    emit(state.copyWith(error: null));
    try {
      await _repo.deleteTransaction(id);
      await loadTransactions();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> createCategory(CategoryModel model) async {
    emit(state.copyWith(error: null));
    try {
      await _repo.saveCategory(model);
      await loadTransactions();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
