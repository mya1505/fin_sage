import 'package:fin_sage/core/errors/error_boundary.dart';
import 'package:fin_sage/data/models/budget_model.dart';
import 'package:fin_sage/l10n/generated/app_localizations.dart';
import 'package:fin_sage/logic/budgets/budget_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ErrorBoundary(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.budgetsTitle)),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            context.read<BudgetCubit>().saveBudget(
                  BudgetModel(
                    id: null,
                    categoryId: 1,
                    month: DateTime(DateTime.now().year, DateTime.now().month),
                    limitAmount: 5000000,
                    usedAmount: 1500000,
                  ),
                );
          },
          child: const Icon(Icons.add),
        ),
        body: SafeArea(
          child: BlocBuilder<BudgetCubit, BudgetState>(
            builder: (context, state) {
              if (state.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.items.isEmpty) {
                return Center(child: Text(l10n.noBudgetYet));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.items.length,
                itemBuilder: (context, index) {
                  final budget = state.items[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${l10n.categoryLabel} #${budget.categoryId}'),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(value: budget.usageRatio),
                          const SizedBox(height: 8),
                          Text('${l10n.usedLabel}: ${budget.usedAmount.toStringAsFixed(0)}'),
                          Text('${l10n.limitLabel}: ${budget.limitAmount.toStringAsFixed(0)}'),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
