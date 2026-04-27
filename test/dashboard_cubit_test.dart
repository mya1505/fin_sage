import 'package:bloc_test/bloc_test.dart';
import 'package:fin_sage/data/models/transaction_model.dart';
import 'package:fin_sage/data/repositories/transaction_repository.dart';
import 'package:fin_sage/logic/dashboard/dashboard_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late MockTransactionRepository repository;

  final now = DateTime.now();
  final items = [
    TransactionModel(
      id: 1,
      title: 'Salary',
      amount: 15000000,
      date: DateTime(now.year, now.month, 2),
      categoryId: 1,
      type: TransactionType.income,
    ),
    TransactionModel(
      id: 2,
      title: 'Groceries',
      amount: 550000,
      date: DateTime(now.year, now.month, 3),
      categoryId: 1,
      type: TransactionType.expense,
    ),
    TransactionModel(
      id: 3,
      title: 'Old Expense',
      amount: 250000,
      date: DateTime(now.year, now.month == 1 ? 12 : now.month - 1, 28),
      categoryId: 1,
      type: TransactionType.expense,
    ),
  ];

  setUp(() {
    repository = MockTransactionRepository();
  });

  blocTest<DashboardCubit, DashboardState>(
    'loadOverview emits summary with recent transactions and monthly count',
    build: () {
      when(() => repository.monthlySummary()).thenAnswer((_) async => {
            'income': 15000000,
            'expense': 550000,
          });
      when(() => repository.fetchTransactions()).thenAnswer((_) async => items);
      return DashboardCubit(repository);
    },
    act: (cubit) => cubit.loadOverview(),
    expect: () => [
      const DashboardState(loading: true),
      isA<DashboardState>()
          .having((s) => s.loading, 'loading', false)
          .having((s) => s.income, 'income', 15000000)
          .having((s) => s.expense, 'expense', 550000)
          .having((s) => s.recentTransactions.length, 'recent count', 3)
          .having((s) => s.monthlyTransactionCount, 'monthly count', 2),
    ],
  );

  blocTest<DashboardCubit, DashboardState>(
    'loadOverview emits error state when repository throws',
    build: () {
      when(() => repository.monthlySummary()).thenThrow(Exception('summary failed'));
      when(() => repository.fetchTransactions()).thenAnswer((_) async => items);
      return DashboardCubit(repository);
    },
    act: (cubit) => cubit.loadOverview(),
    expect: () => [
      const DashboardState(loading: true),
      isA<DashboardState>().having((s) => s.error, 'error', contains('summary failed')),
    ],
  );
}
