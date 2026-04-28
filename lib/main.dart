import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fin_sage/core/constants/app_routes.dart';
import 'package:fin_sage/core/constants/app_theme.dart';
import 'package:fin_sage/core/di/service_locator.dart';
import 'package:fin_sage/core/errors/error_boundary.dart';
import 'package:fin_sage/core/utils/sentry_config.dart';
import 'package:fin_sage/features/budgets/budget_notification_service.dart';
import 'package:fin_sage/l10n/generated/app_localizations.dart';
import 'package:fin_sage/features/settings/backup_scheduler.dart';
import 'package:fin_sage/logic/auth/auth_cubit.dart';
import 'package:fin_sage/logic/budgets/budget_cubit.dart';
import 'package:fin_sage/logic/dashboard/dashboard_cubit.dart';
import 'package:fin_sage/logic/reports/report_cubit.dart';
import 'package:fin_sage/logic/settings/settings_cubit.dart';
import 'package:fin_sage/logic/transactions/transaction_cubit.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ServiceLocator.init();
  await sl<BudgetNotificationService>().initialize();
  await BackupScheduler.initialize();
  await BackupScheduler.scheduleEvery24Hours();

  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN', defaultValue: '');
      options.tracesSampleRate = SentryConfig.resolveTraceSampleRate(
        const String.fromEnvironment('SENTRY_TRACE_SAMPLE_RATE', defaultValue: '0.1'),
      );
    },
    appRunner: () {
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        unawaited(Sentry.captureException(details.exception, stackTrace: details.stack));
      };

      PlatformDispatcher.instance.onError = (error, stackTrace) {
        unawaited(Sentry.captureException(error, stackTrace: stackTrace));
        return true;
      };

      runZonedGuarded(
        () => runApp(const ErrorBoundary(child: FinSageApp())),
        (error, stackTrace) => Sentry.captureException(error, stackTrace: stackTrace),
      );
    },
  );
}

class FinSageApp extends StatelessWidget {
  const FinSageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AuthCubit>()..bootstrap()),
        BlocProvider(create: (_) => sl<DashboardCubit>()..loadOverview()),
        BlocProvider(create: (_) => sl<TransactionCubit>()..loadTransactions()),
        BlocProvider(create: (_) => sl<BudgetCubit>()..loadBudgets()),
        BlocProvider(create: (_) => sl<ReportCubit>()),
        BlocProvider(create: (_) => sl<SettingsCubit>()..loadSettings()),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          return MaterialApp(
            title: 'FinSage',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settingsState.themeMode,
            locale: settingsState.locale,
            initialRoute: AppRoutes.root,
            onGenerateRoute: AppRoutes.onGenerateRoute,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
          );
        },
      ),
    );
  }
}
