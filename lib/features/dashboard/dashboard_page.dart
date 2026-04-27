import 'package:fl_chart/fl_chart.dart';
import 'package:fin_sage/core/constants/app_routes.dart';
import 'package:fin_sage/core/constants/icons/home_icon.dart';
import 'package:fin_sage/core/constants/icons/report_icon.dart';
import 'package:fin_sage/core/constants/icons/transaction_icon.dart';
import 'package:fin_sage/core/errors/error_boundary.dart';
import 'package:fin_sage/core/utils/extensions.dart';
import 'package:fin_sage/core/widgets/animated_balance_chart.dart';
import 'package:fin_sage/core/widgets/loading_skeleton.dart';
import 'package:fin_sage/core/widgets/premium_card.dart';
import 'package:fin_sage/l10n/generated/app_localizations.dart';
import 'package:fin_sage/logic/dashboard/dashboard_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ErrorBoundary(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.dashboardTitle)),
        body: SafeArea(
          child: BlocBuilder<DashboardCubit, DashboardState>(
            builder: (context, state) {
              if (state.loading) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      LoadingSkeleton(height: 180),
                      SizedBox(height: 16),
                      LoadingSkeleton(height: 220),
                    ],
                  ),
                );
              }

              final locale = Localizations.localeOf(context).toLanguageTag();
              final spots = [
                FlSpot(0, 1),
                FlSpot(1, (state.income * 0.2).clamp(1, 100000).toDouble()),
                FlSpot(2, (state.expense * 0.2).clamp(1, 100000).toDouble()),
                FlSpot(3, state.balance.abs().clamp(1, 100000).toDouble()),
              ];

              return RefreshIndicator(
                onRefresh: context.read<DashboardCubit>().loadOverview,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    PremiumCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.totalBalance),
                          const SizedBox(height: 8),
                          Text(
                            state.balance.toCurrency(locale),
                            textScaler: MediaQuery.textScalerOf(context),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          Text('${l10n.monthlyIncome}: ${state.income.toCurrency(locale)}'),
                          Text('${l10n.monthlyExpense}: ${state.expense.toCurrency(locale)}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedBalanceChart(spots: spots),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _RouteChip(
                          label: l10n.transactionsTitle,
                          route: AppRoutes.transactions,
                          svg: kTransactionIconSvg,
                        ),
                        _RouteChip(label: l10n.budgetsTitle, route: AppRoutes.budgets, svg: kHomeIconSvg),
                        _RouteChip(label: l10n.reportsTitle, route: AppRoutes.reports, svg: kReportIconSvg),
                        _RouteChip(label: l10n.settingsTitle, route: AppRoutes.settings, svg: kHomeIconSvg),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RouteChip extends StatelessWidget {
  const _RouteChip({required this.label, required this.route, required this.svg});

  final String label;
  final String route;
  final String svg;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: SvgPicture.string(svg, width: 18, height: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      onPressed: () => Navigator.pushNamed(context, route),
    );
  }
}
