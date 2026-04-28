import 'package:fin_sage/core/errors/error_boundary.dart';
import 'package:fin_sage/core/utils/extensions.dart';
import 'package:fin_sage/core/utils/validators.dart';
import 'package:fin_sage/core/widgets/loading_skeleton.dart';
import 'package:fin_sage/core/constants/lottie_placeholders.dart';
import 'package:fin_sage/data/models/budget_model.dart';
import 'package:fin_sage/l10n/generated/app_localizations.dart';
import 'package:fin_sage/logic/budgets/budget_cubit.dart';
import 'package:fin_sage/logic/transactions/transaction_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final categoryMap = {
      for (final category in context.watch<TransactionCubit>().state.categories)
        if (category.id != null) category.id!: category.name,
    };

    return ErrorBoundary(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.budgetsTitle)),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showBudgetForm(context),
          tooltip: l10n.budgetsTitle,
          child: const Icon(Icons.add_chart),
        ),
        body: SafeArea(
          child: BlocConsumer<BudgetCubit, BudgetState>(
            listenWhen: (previous, current) => previous.error != current.error,
            listener: (context, state) {
              if (state.error == null) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error!),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            },
            builder: (context, state) {
              if (state.loading) {
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: 5,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, __) => const LoadingSkeleton(height: 96),
                );
              }

              if (state.items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Lottie.asset(LottiePlaceholders.emptyStateAnimation, height: 140),
                        const SizedBox(height: 12),
                        Text(l10n.noBudgetYet, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: context.read<BudgetCubit>().loadBudgets,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final budget = state.items[index];
                    final ratio = budget.limitAmount == 0 ? 0 : (budget.usedAmount / budget.limitAmount);
                    final progress = ratio.clamp(0, 1).toDouble();
                    final isExceeded = ratio >= 1;
                    final monthLabel = DateFormat.yMMMM(locale).format(budget.month);
                    final categoryLabel = categoryMap[budget.categoryId] ?? '#${budget.categoryId}';

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    monthLabel,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _showBudgetForm(context, existing: budget),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: budget.id == null
                                      ? null
                                      : () => _confirmDeleteBudget(context, budget.id!),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('${l10n.categoryLabel}: $categoryLabel'),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: progress,
                              color: isExceeded ? Theme.of(context).colorScheme.error : Colors.green.shade700,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(ratio * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isExceeded ? Theme.of(context).colorScheme.error : null,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('${l10n.usedLabel}: ${budget.usedAmount.toCurrency(locale)}'),
                            Text('${l10n.limitLabel}: ${budget.limitAmount.toCurrency(locale)}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteBudget(BuildContext context, int budgetId) async {
    final l10n = AppLocalizations.of(context)!;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.confirmDeleteBudgetTitle),
          content: Text(l10n.confirmDeleteBudgetBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.deleteActionLabel),
            ),
          ],
        );
      },
    );

    if (approved == true && context.mounted) {
      await HapticFeedback.mediumImpact();
      await context.read<BudgetCubit>().removeBudget(budgetId);
    }
  }

  Future<void> _showBudgetForm(BuildContext context, {BudgetModel? existing}) async {
    final l10n = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();
    final limitCtrl = TextEditingController(text: existing?.limitAmount.toStringAsFixed(0) ?? '');
    final usedCtrl = TextEditingController(text: existing?.usedAmount.toStringAsFixed(0) ?? '0');
    DateTime selectedMonth =
        existing?.month ?? DateTime(DateTime.now().year, DateTime.now().month);
    final categories = context.read<TransactionCubit>().state.categories;
    final hasExistingCategory =
        existing != null && categories.any((category) => category.id == existing.categoryId);
    int selectedCategoryId = hasExistingCategory
        ? existing!.categoryId
        : (categories.isNotEmpty ? (categories.first.id ?? 1) : (existing?.categoryId ?? 1));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (categories.isNotEmpty)
                      DropdownButtonFormField<int>(
                        value: selectedCategoryId,
                        decoration: InputDecoration(labelText: l10n.categoryLabel),
                        items: categories
                            .map(
                              (category) => DropdownMenuItem<int>(
                                value: category.id ?? 1,
                                child: Text(category.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setSheetState(() => selectedCategoryId = value);
                          }
                        },
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: limitCtrl,
                      decoration: InputDecoration(labelText: l10n.limitLabel),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => _errorFromCode(l10n, Validators.amount(value)),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: usedCtrl,
                      decoration: InputDecoration(labelText: l10n.usedLabel),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null;
                        }
                        final parsed = double.tryParse(value.replaceAll(',', '.'));
                        if (parsed == null) {
                          return l10n.amountInvalid;
                        }
                        if (parsed < 0) {
                          return l10n.amountMustBePositive;
                        }
                        if (parsed > 1000000000000) {
                          return l10n.amountTooLarge;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(DateFormat.yMMMM().format(selectedMonth)),
                      subtitle: Text(l10n.dateLabel),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: sheetContext,
                          initialDate: selectedMonth,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setSheetState(() {
                            selectedMonth = DateTime(picked.year, picked.month);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            child: Text(l10n.cancelLabel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) {
                                return;
                              }
                              await HapticFeedback.lightImpact();
                              await context.read<BudgetCubit>().saveBudget(
                                    BudgetModel(
                                      id: existing?.id,
                                      categoryId: selectedCategoryId,
                                      month: selectedMonth,
                                      limitAmount: double.parse(limitCtrl.text.replaceAll(',', '.')),
                                      usedAmount: double.tryParse(usedCtrl.text.replaceAll(',', '.')) ?? 0,
                                    ),
                                  );
                              if (context.mounted) {
                                Navigator.pop(sheetContext);
                              }
                            },
                            child: Text(existing == null ? l10n.saveLabel : l10n.updateActionLabel),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String? _errorFromCode(AppLocalizations l10n, String? code) {
    switch (code) {
      case 'amountRequired':
        return l10n.amountRequired;
      case 'amountInvalid':
        return l10n.amountInvalid;
      case 'amountMustBePositive':
        return l10n.amountMustBePositive;
      case 'amountTooLarge':
        return l10n.amountTooLarge;
      default:
        return null;
    }
  }
}
