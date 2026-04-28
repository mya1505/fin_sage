import 'package:bloc_test/bloc_test.dart';
import 'package:fin_sage/core/errors/app_exception.dart';
import 'package:fin_sage/data/models/category_model.dart';
import 'package:fin_sage/data/models/transaction_model.dart';
import 'package:fin_sage/data/repositories/transaction_repository.dart';
import 'package:fin_sage/logic/transactions/transaction_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late MockTransactionRepository repository;

  setUpAll(() {
    registerFallbackValue(
      const CategoryModel(id: null, name: 'Fallback', colorHex: '#0D3B66', icon: 'wallet'),
    );
    registerFallbackValue(
      TransactionModel(
        id: 1,
        title: 'Fallback',
        amount: 1,
        date: DateTime(2026, 1, 1),
        categoryId: 1,
        type: TransactionType.expense,
      ),
    );
  });

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

  blocTest<TransactionCubit, TransactionState>(
    'createCategory emits stable code when repository throws app exception',
    build: () {
      when(
        () => repository.saveCategory(any()),
      ).thenThrow(const AppException('Category already exists', code: 'category_already_exists'));
      return TransactionCubit(repository);
    },
    act: (cubit) => cubit.createCategory(
      const CategoryModel(id: null, name: 'Food', colorHex: '#F4A261', icon: 'restaurant'),
    ),
    expect: () => [
      const TransactionState(loading: false, items: [], categories: [], error: null),
      const TransactionState(
        loading: false,
        items: [],
        categories: [],
        error: 'category_already_exists',
      ),
    ],
  );

  blocTest<TransactionCubit, TransactionState>(
    'createCategory saves category and reloads items',
    build: () {
      when(() => repository.saveCategory(any())).thenAnswer((_) async {});
      when(() => repository.fetchTransactions()).thenAnswer((_) async => transactions);
      when(() => repository.fetchCategories()).thenAnswer((_) async => categories);
      return TransactionCubit(repository);
    },
    act: (cubit) => cubit.createCategory(
      const CategoryModel(id: null, name: 'Food', colorHex: '#F4A261', icon: 'restaurant'),
    ),
    expect: () => [
      const TransactionState(loading: false, items: [], categories: [], error: null),
      const TransactionState(loading: true),
      TransactionState(loading: false, items: transactions, categories: categories),
    ],
    verify: (_) => verify(() => repository.saveCategory(any())).called(1),
  );

  blocTest<TransactionCubit, TransactionState>(
    'archiveCategory archives category and reloads items',
    build: () {
      when(() => repository.archiveCategory(2)).thenAnswer((_) async {});
      when(() => repository.fetchTransactions()).thenAnswer((_) async => transactions);
      when(() => repository.fetchCategories()).thenAnswer((_) async => categories);
      return TransactionCubit(repository);
    },
    act: (cubit) => cubit.archiveCategory(2),
    expect: () => [
      const TransactionState(loading: false, items: [], categories: [], error: null),
      const TransactionState(loading: true),
      TransactionState(loading: false, items: transactions, categories: categories),
    ],
    verify: (_) => verify(() => repository.archiveCategory(2)).called(1),
  );

  blocTest<TransactionCubit, TransactionState>(
    'updateTransaction updates item and reloads list',
    build: () {
      when(() => repository.updateTransaction(any())).thenAnswer((_) async {});
      when(() => repository.fetchTransactions()).thenAnswer((_) async => transactions);
      when(() => repository.fetchCategories()).thenAnswer((_) async => categories);
      return TransactionCubit(repository);
    },
    act: (cubit) => cubit.updateTransaction(
      TransactionModel(
        id: 1,
        title: 'Lunch Updated',
        amount: 50000,
        date: DateTime(2026, 4, 27),
        categoryId: 1,
        type: TransactionType.expense,
      ),
    ),
    expect: () => [
      const TransactionState(loading: false, items: [], categories: [], error: null),
      const TransactionState(loading: true),
      TransactionState(loading: false, items: transactions, categories: categories),
    ],
    verify: (_) => verify(() => repository.updateTransaction(any())).called(1),
  );
}
