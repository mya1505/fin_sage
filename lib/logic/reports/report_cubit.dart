import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReportState extends Equatable {
  const ReportState({this.loading = false, this.success = false, this.error});

  final bool loading;
  final bool success;
  final String? error;

  ReportState copyWith({bool? loading, bool? success, String? error}) {
    return ReportState(
      loading: loading ?? this.loading,
      success: success ?? this.success,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, success, error];
}

class ReportCubit extends Cubit<ReportState> {
  ReportCubit() : super(const ReportState());

  Future<void> run(Future<void> Function() action) async {
    emit(state.copyWith(loading: true, success: false, error: null));
    try {
      await action();
      emit(state.copyWith(loading: false, success: true));
    } catch (e) {
      emit(state.copyWith(loading: false, success: false, error: e.toString()));
    }
  }
}
