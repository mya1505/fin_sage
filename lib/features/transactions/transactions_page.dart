import 'package:fin_sage/core/errors/error_boundary.dart';
import 'package:fin_sage/core/utils/extensions.dart';
import 'package:fin_sage/core/utils/validators.dart';
import 'package:fin_sage/core/widgets/loading_skeleton.dart';
import 'package:fin_sage/data/models/category_model.dart';
import 'package:fin_sage/data/models/transaction_model.dart';
import 'package:fin_sage/l10n/generated/app_localizations.dart';
import 'package:fin_sage/logic/transactions/transaction_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum _TransactionFilter { all, income, expense }

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final TextEditingController _searchController = TextEditingController();
  _TransactionFilter _filter = _TransactionFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ErrorBoundary(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.transactionsTitle)),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCreateForm(context),
          label: Text(l10n.addTransaction),
          icon: const Icon(Icons.add),
        ),
        body: SafeArea(
          child: BlocConsumer<TransactionCubit, TransactionState>(
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
                  itemCount: 8,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, __) => const LoadingSkeleton(height: 70),
                );
              }

              final filteredItems = _applyFilters(state.items);

              if (state.items.isEmpty) {
                return Center(child: Text(l10n.emptyTransactions));
              }

              final locale = Localizations.localeOf(context).toLanguageTag();
              final incomeTotal = filteredItems
                  .where((tx) => tx.type == TransactionType.income)
                  .fold<double>(0, (sum, tx) => sum + tx.amount);
              final expenseTotal = filteredItems
                  .where((tx) => tx.type == TransactionType.expense)
                  .fold<double>(0, (sum, tx) => sum + tx.amount);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: l10n.searchTransactions,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _FilterChip(
                        label: l10n.allType,
                        active: _filter == _TransactionFilter.all,
                        onTap: () => setState(() => _filter = _TransactionFilter.all),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: l10n.incomeType,
                        active: _filter == _TransactionFilter.income,
                        onTap: () => setState(() => _filter = _TransactionFilter.income),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: l10n.expenseType,
                        active: _filter == _TransactionFilter.expense,
                        onTap: () => setState(() => _filter = _TransactionFilter.expense),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.monthlyIncome),
                          Text(
                            incomeTotal.toCurrency(locale),
                            style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(l10n.monthlyExpense),
                          Text(
                            expenseTotal.toCurrency(locale),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (filteredItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Center(child: Text(l10n.noMatchingTransactions)),
                    )
                  else
                    ...filteredItems.map((tx) {
                      final isIncome = tx.type == TransactionType.income;
                      final amountColor = isIncome ? Colors.green.shade700 : Theme.of(context).colorScheme.error;
                      final categoryName = _categoryNameById(state.categories, tx.categoryId);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          tileColor: Theme.of(context).colorScheme.surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          title: Text(tx.title),
                          subtitle: Text(
                            '${tx.date.toIso8601String().split('T').first} • $categoryName • ${isIncome ? l10n.incomeType : l10n.expenseType}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${isIncome ? '+' : '-'}${tx.amount.toCurrency(locale)}',
                                style: TextStyle(color: amountColor, fontWeight: FontWeight.w700),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: tx.id == null ? null : () => _confirmDelete(context, tx.id!),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<TransactionModel> _applyFilters(List<TransactionModel> items) {
    final query = _searchController.text.trim().toLowerCase();
    return items.where((tx) {
      final typeMatch = switch (_filter) {
        _TransactionFilter.all => true,
        _TransactionFilter.income => tx.type == TransactionType.income,
        _TransactionFilter.expense => tx.type == TransactionType.expense,
      };

      if (!typeMatch) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      return tx.title.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _confirmDelete(BuildContext context, int id) async {
    final l10n = AppLocalizations.of(context)!;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.confirmDeleteTitle),
          content: Text(l10n.confirmDeleteBody),
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
      await context.read<TransactionCubit>().removeTransaction(id);
    }
  }

  Future<void> _showCreateForm(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TransactionType selectedType = TransactionType.expense;
    final state = context.read<TransactionCubit>().state;
    final categories = state.categories;
    int selectedCategoryId = categories.isNotEmpty ? (categories.first.id ?? 1) : 1;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                    TextFormField(
                      controller: titleCtrl,
                      decoration: InputDecoration(labelText: l10n.titleLabel),
                      validator: (v) => v == null || v.trim().isEmpty ? l10n.requiredField : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountCtrl,
                      decoration: InputDecoration(labelText: l10n.amountLabel),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final code = Validators.amount(v);
                        return _errorFromCode(l10n, code);
                      },
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(l10n.transactionTypeLabel),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(l10n.expenseType),
                          selected: selectedType == TransactionType.expense,
                          onSelected: (_) => setState(() => selectedType = TransactionType.expense),
                        ),
                        ChoiceChip(
                          label: Text(l10n.incomeType),
                          selected: selectedType == TransactionType.income,
                          onSelected: (_) => setState(() => selectedType = TransactionType.income),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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
                            setState(() => selectedCategoryId = value);
                          }
                        },
                      )
                    else
                      TextFormField(
                        enabled: false,
                        decoration: InputDecoration(labelText: l10n.categoryLabel, hintText: 'General'),
                      ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(selectedDate.toIso8601String().split('T').first),
                      subtitle: Text(l10n.dateLabel),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: sheetContext,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                        );
                        if (date != null) {
                          setState(() => selectedDate = date);
                        }
                      },
                    ),
                    Builder(
                      builder: (_) {
                        final code = Validators.requiredDate(selectedDate);
                        final error = _errorFromCode(l10n, code);
                        if (error == null) {
                          return const SizedBox.shrink();
                        }
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) {
                          return;
                        }

                        final dateError = Validators.requiredDate(selectedDate);
                        if (dateError != null) {
                          return;
                        }

                        context.read<TransactionCubit>().createTransaction(
                              TransactionModel(
                                id: null,
                                title: titleCtrl.text.trim(),
                                amount: double.parse(amountCtrl.text.replaceAll(',', '.')),
                                date: selectedDate,
                                categoryId: selectedCategoryId,
                                type: selectedType,
                              ),
                            );
                        Navigator.pop(sheetContext);
                      },
                      child: Text(l10n.saveLabel),
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
      case 'dateRequired':
        return l10n.dateRequired;
      case 'dateFutureNotAllowed':
        return l10n.dateFutureNotAllowed;
      default:
        return null;
    }
  }

  String _categoryNameById(List<CategoryModel> categories, int id) {
    for (final category in categories) {
      if (category.id == id) {
        return category.name;
      }
    }
    return '#$id';
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (_) => onTap(),
    );
  }
}
