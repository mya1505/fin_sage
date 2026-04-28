import 'package:equatable/equatable.dart';
import 'package:fin_sage/data/datasources/local/settings_storage.dart';
import 'package:fin_sage/data/models/budget_model.dart';
import 'package:fin_sage/data/repositories/budget_repository.dart';
import 'package:fin_sage/features/budgets/budget_notification_service.dart';
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
  BudgetCubit(this._repo, this._notificationService, this._settingsStorage) : super(const BudgetState());

  final BudgetRepository _repo;
  final BudgetNotificationService _notificationService;
  final SettingsStorage _settingsStorage;
  final Set<int> _notifiedBudgetIds = <int>{};

  Future<void> loadBudgets() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final items = await _repo.fetchBudgets();
      emit(state.copyWith(loading: false, items: items));
      await _notifyExceededBudgets(items);
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> saveBudget(BudgetModel model) async {
    emit(state.copyWith(error: null));
    try {
      await _repo.saveBudget(model);
      await loadBudgets();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _notifyExceededBudgets(List<BudgetModel> items) async {
    final notificationsEnabled = await _settingsStorage.loadNotificationsEnabled();
    if (!notificationsEnabled) {
      return;
    }

    for (final budget in items) {
      final id = budget.id;
      if (id == null || budget.usageRatio < 1 || _notifiedBudgetIds.contains(id)) {
        continue;
      }
      await _notificationService.notifyBudgetExceeded(budgetId: id);
      _notifiedBudgetIds.add(id);
    }
  }
}
