import 'package:fin_sage/features/auth/auth_page.dart';
import 'package:fin_sage/features/auth/auth_gate_page.dart';
import 'package:fin_sage/features/budgets/budgets_page.dart';
import 'package:fin_sage/features/dashboard/dashboard_page.dart';
import 'package:fin_sage/features/reports/reports_page.dart';
import 'package:fin_sage/features/settings/settings_page.dart';
import 'package:fin_sage/features/transactions/transactions_page.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const String root = '/';
  static const String auth = '/auth';
  static const String dashboard = '/dashboard';
  static const String transactions = '/transactions';
  static const String budgets = '/budgets';
  static const String reports = '/reports';
  static const String settings = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case root:
        return _material(const AuthGatePage());
      case auth:
        return _material(const AuthPage());
      case dashboard:
        return _material(const DashboardPage());
      case transactions:
        return _material(const TransactionsPage());
      case budgets:
        return _material(const BudgetsPage());
      case reports:
        return _material(const ReportsPage());
      case settings:
        return _material(const SettingsPage());
      default:
        return _material(const AuthGatePage());
    }
  }

  static MaterialPageRoute<dynamic> _material(Widget child) {
    return MaterialPageRoute(builder: (_) => child);
  }
}
