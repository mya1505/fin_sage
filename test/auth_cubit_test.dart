import 'package:bloc_test/bloc_test.dart';
import 'package:fin_sage/data/repositories/auth_repository.dart';
import 'package:fin_sage/logic/auth/auth_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
  });

  blocTest<AuthCubit, AuthState>(
    'bootstrap emits authenticated when user already signed in',
    build: () {
      when(() => repository.isSignedIn()).thenAnswer((_) async => true);
      return AuthCubit(repository);
    },
    act: (cubit) => cubit.bootstrap(),
    expect: () => [const AuthState(status: AuthStatus.authenticated)],
  );

  blocTest<AuthCubit, AuthState>(
    'signIn emits loading and unauthenticated when sign-in result false',
    build: () {
      when(() => repository.signInWithGoogle()).thenAnswer((_) async => false);
      return AuthCubit(repository);
    },
    act: (cubit) => cubit.signIn(),
    expect: () => [
      const AuthState(status: AuthStatus.loading),
      const AuthState(status: AuthStatus.unauthenticated),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'signIn emits error state when repository throws',
    build: () {
      when(() => repository.signInWithGoogle()).thenThrow(Exception('network error'));
      return AuthCubit(repository);
    },
    act: (cubit) => cubit.signIn(),
    expect: () => [
      const AuthState(status: AuthStatus.loading),
      isA<AuthState>().having((s) => s.status, 'status', AuthStatus.error),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'bootstrap emits unauthenticated with error when repository throws',
    build: () {
      when(() => repository.isSignedIn()).thenThrow(Exception('session error'));
      return AuthCubit(repository);
    },
    act: (cubit) => cubit.bootstrap(),
    expect: () => [
      isA<AuthState>()
          .having((s) => s.status, 'status', AuthStatus.unauthenticated)
          .having((s) => s.errorMessage, 'errorMessage', contains('session error')),
    ],
  );
}
