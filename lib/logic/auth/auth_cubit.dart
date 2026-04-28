import 'package:equatable/equatable.dart';
import 'package:fin_sage/data/repositories/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState extends Equatable {
  const AuthState({this.status = AuthStatus.initial, this.errorMessage});

  final AuthStatus status;
  final String? errorMessage;

  AuthState copyWith({AuthStatus? status, String? errorMessage}) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repo) : super(const AuthState());

  final AuthRepository _repo;

  Future<void> bootstrap() async {
    try {
      final signedIn = await _repo.isSignedIn();
      emit(state.copyWith(status: signedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated));
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.unauthenticated, errorMessage: e.toString()));
    }
  }

  Future<void> signIn() async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final success = await _repo.signInWithGoogle();
      emit(state.copyWith(status: success ? AuthStatus.authenticated : AuthStatus.unauthenticated));
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    emit(state.copyWith(status: AuthStatus.unauthenticated));
  }
}
