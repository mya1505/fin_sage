import 'package:bloc_test/bloc_test.dart';
import 'package:fin_sage/data/models/category_model.dart';
import 'package:fin_sage/data/models/transaction_model.dart';
import 'package:fin_sage/data/repositories/transaction_repository.dart';
import 'package:fin_sage/logic/transactions/transaction_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late MockTransactionRepository repository;

  const categories = [
    CategoryModel(id: 1, name: 'General', colorHex: '#0D3B66', icon: 'wallet'),
  ];

  final transactions = [
    TransactionModel(
      id: 1,
      title: 'Lunch',
      amount: 45000,
      date: DateTime(2026, 4, 27),
      categoryId: 1,
      type: TransactionType.expense,
    ),
  ];

  setUp(() {
    repository = MockTransactionRepository();
  });

  blocTest<TransactionCubit, TransactionState>(
    'loadTransactions emits loading then populated state',
    build: () {
      when(() => repository.fetchTransactions()).thenAnswer((_) async => transactions);
      when(() => repository.fetchCategories()).thenAnswer((_) async => categories);
      return TransactionCubit(repository);
    },
    act: (cubit) => cubit.loadTransactions(),
    expect: () => [
      const TransactionState(loading: true),
      TransactionState(loading: false, items: transactions, categories: categories),
    ],
  );

  blocTest<TransactionCubit, TransactionState>(
    'loadTransactions emits error when repository throws',
    build: () {
      when(() => repository.fetchTransactions()).thenThrow(Exception('db failure'));
      when(() => repository.fetchCategories()).thenAnswer((_) async => categories);
      return TransactionCubit(repository);
    },
    act: (cubit) => cubit.loadTransactions(),
    expect: () => [
      const TransactionState(loading: true),
      isA<TransactionState>().having((s) => s.error, 'error', contains('db failure')),
    ],
  );
}
