import 'package:fin_sage/features/auth/auth_page.dart';
import 'package:fin_sage/features/dashboard/dashboard_page.dart';
import 'package:fin_sage/core/errors/error_boundary.dart';
import 'package:fin_sage/logic/auth/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthGatePage extends StatelessWidget {
  const AuthGatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          switch (state.status) {
            case AuthStatus.initial:
            case AuthStatus.loading:
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            case AuthStatus.unauthenticated:
            case AuthStatus.error:
              return const AuthPage();
            case AuthStatus.authenticated:
              return const DashboardPage();
          }
        },
      ),
    );
  }
}
