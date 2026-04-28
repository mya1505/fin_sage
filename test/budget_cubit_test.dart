import 'package:bloc_test/bloc_test.dart';
import 'package:fin_sage/data/models/budget_model.dart';
import 'package:fin_sage/data/repositories/budget_repository.dart';
import 'package:fin_sage/features/budgets/budget_notification_service.dart';
import 'package:fin_sage/logic/budgets/budget_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBudgetRepository extends Mock implements BudgetRepository {}

class MockBudgetNotificationService extends Mock implements BudgetNotificationService {}

void main() {
  late MockBudgetRepository repository;
  late MockBudgetNotificationService notificationService;

  final budgets = [
    BudgetModel(
      id: 1,
      categoryId: 1,
      month: DateTime(2026, 4),
      limitAmount: 2000000,
      usedAmount: 2500000,
    ),
    BudgetModel(
      id: 2,
      categoryId: 1,
      month: DateTime(2026, 4),
      limitAmount: 3000000,
      usedAmount: 1500000,
    ),
  ];

  setUp(() {
    repository = MockBudgetRepository();
    notificationService = MockBudgetNotificationService();
  });

  blocTest<BudgetCubit, BudgetState>(
    'loadBudgets emits loading and items, then triggers notification for exceeded budget',
    build: () {
      when(() => repository.fetchBudgets()).thenAnswer((_) async => budgets);
      when(() => notificationService.notifyBudgetExceeded(budgetId: 1)).thenAnswer((_) async {});
      return BudgetCubit(repository, notificationService);
    },
    act: (cubit) => cubit.loadBudgets(),
    expect: () => [
      const BudgetState(loading: true),
      BudgetState(loading: false, items: budgets),
    ],
    verify: (_) {
      verify(() => notificationService.notifyBudgetExceeded(budgetId: 1)).called(1);
      verifyNever(() => notificationService.notifyBudgetExceeded(budgetId: 2));
    },
  );

  blocTest<BudgetCubit, BudgetState>(
    'saveBudget emits error when repository fails',
    build: () {
      when(() => repository.saveBudget(any())).thenThrow(Exception('save failed'));
      return BudgetCubit(repository, notificationService);
    },
    act: (cubit) => cubit.saveBudget(
      BudgetModel(
        id: null,
        categoryId: 1,
        month: DateTime(2026, 4),
        limitAmount: 1000000,
        usedAmount: 0,
      ),
    ),
    expect: () => [
      isA<BudgetState>().having((s) => s.error, 'error', contains('save failed')),
    ],
  );
}
