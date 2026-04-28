import 'package:fin_sage/core/errors/error_boundary.dart';
import 'package:fin_sage/core/utils/extensions.dart';
import 'package:fin_sage/core/utils/validators.dart';
import 'package:fin_sage/core/widgets/loading_skeleton.dart';
import 'package:fin_sage/data/models/category_model.dart';
import 'package:fin_sage/data/models/transaction_model.dart';
import 'package:fin_sage/l10n/generated/app_localizations.dart';
import 'package:fin_sage/logic/transactions/transaction_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

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
        appBar: AppBar(
          title: Text(l10n.transactionsTitle),
          actions: [
            IconButton(
              onPressed: () => _showCreateCategoryDialog(context),
              tooltip: l10n.manageCategories,
              icon: const Icon(Icons.category_outlined),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showTransactionForm(context),
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
              final message = switch (state.error!) {
                final error when error.contains('Category already exists') => l10n.categoryExists,
                final error when error.contains('Category is still used') => l10n.categoryInUse,
                final error when error.contains('Default category cannot be archived') =>
                  l10n.defaultCategoryArchiveBlocked,
                _ => state.error!,
              };
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
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
                            '${DateFormat.yMMMd(locale).format(tx.date)} • $categoryName • ${isIncome ? l10n.incomeType : l10n.expenseType}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${isIncome ? '+' : '-'}${tx.amount.toCurrency(locale)}',
                                style: TextStyle(color: amountColor, fontWeight: FontWeight.w700),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: tx.id == null ? null : () => _showTransactionForm(context, existing: tx),
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
      await HapticFeedback.mediumImpact();
      await context.read<TransactionCubit>().removeTransaction(id);
    }
  }

  Future<void> _showTransactionForm(BuildContext context, {TransactionModel? existing}) async {
    final l10n = AppLocalizations.of(context)!;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final amountCtrl = TextEditingController(text: existing == null ? '' : existing.amount.toStringAsFixed(0));
    DateTime selectedDate = existing?.date ?? DateTime.now();
    TransactionType selectedType = existing?.type ?? TransactionType.expense;
    final state = context.read<TransactionCubit>().state;
    final categories = state.categories;
    final hasExistingCategory = existing != null && categories.any((category) => category.id == existing.categoryId);
    int selectedCategoryId = hasExistingCategory
        ? existing!.categoryId
        : (categories.isNotEmpty ? (categories.first.id ?? 1) : (existing?.categoryId ?? 1));

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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            enabled: false,
                            decoration: InputDecoration(labelText: l10n.categoryLabel, hintText: '#1'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () => _showCreateCategoryDialog(sheetContext),
                            icon: const Icon(Icons.add),
                            label: Text(l10n.addCategory),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(DateFormat.yMMMd(localeTag).format(selectedDate)),
                      subtitle: Text(l10n.dateLabel),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: sheetContext,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
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
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) {
                          return;
                        }

                        final dateError = Validators.requiredDate(selectedDate);
                        if (dateError != null) {
                          return;
                        }

                        final model = TransactionModel(
                          id: existing?.id,
                          title: titleCtrl.text.trim(),
                          amount: double.parse(amountCtrl.text.replaceAll(',', '.')),
                          date: selectedDate,
                          categoryId: selectedCategoryId,
                          type: selectedType,
                        );
                        await HapticFeedback.lightImpact();

                        if (existing == null) {
                          context.read<TransactionCubit>().createTransaction(model);
                        } else {
                          context.read<TransactionCubit>().updateTransaction(model);
                        }
                        Navigator.pop(sheetContext);
                      },
                      child: Text(existing == null ? l10n.saveLabel : l10n.updateActionLabel),
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

  Future<void> _showCreateCategoryDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final colorCtrl = TextEditingController(text: '#0D3B66');
    final iconCtrl = TextEditingController(text: 'wallet');
    final cubit = context.read<TransactionCubit>();

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        var categories = List<CategoryModel>.from(cubit.state.categories);
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(l10n.manageCategories),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (categories.isNotEmpty) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l10n.categoryLabel,
                            style: Theme.of(dialogContext).textTheme.titleSmall,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 180),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: categories.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, index) {
                              final category = categories[index];
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(category.name),
                                subtitle: Text(category.colorHex),
                                trailing: category.id == null || category.id == 1
                                    ? null
                                    : IconButton(
                                        icon: const Icon(Icons.archive_outlined),
                                        onPressed: () async {
                                          final approved = await _confirmArchiveCategory(
                                            dialogContext,
                                            category.name,
                                          );
                                          if (!approved || category.id == null) {
                                            return;
                                          }
                                          await HapticFeedback.selectionClick();
                                          await cubit.archiveCategory(category.id!);
                                          if (cubit.state.error == null) {
                                            setDialogState(() {
                                              categories = List<CategoryModel>.from(cubit.state.categories);
                                            });
                                          }
                                        },
                                      ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: nameCtrl,
                        decoration: InputDecoration(labelText: l10n.categoryNameLabel),
                        validator: (value) => _errorFromCode(l10n, Validators.categoryName(value)),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: colorCtrl,
                        decoration: InputDecoration(labelText: l10n.colorHexLabel),
                        validator: (value) => _errorFromCode(l10n, Validators.hexColor(value)),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: iconCtrl,
                        decoration: InputDecoration(labelText: l10n.iconLabel),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(l10n.cancelLabel),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }
                    await HapticFeedback.lightImpact();
                    await cubit.createCategory(
                          CategoryModel(
                            id: null,
                            name: nameCtrl.text.trim(),
                            colorHex: colorCtrl.text.trim().isEmpty ? '#0D3B66' : colorCtrl.text.trim(),
                            icon: iconCtrl.text.trim().isEmpty ? 'wallet' : iconCtrl.text.trim(),
                          ),
                        );
                    if (cubit.state.error == null) {
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext, true);
                      }
                    }
                  },
                  child: Text(l10n.saveLabel),
                ),
              ],
            );
          },
        );
      },
    );

    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.categoryCreated)));
    }
  }

  Future<bool> _confirmArchiveCategory(BuildContext context, String categoryName) async {
    final l10n = AppLocalizations.of(context)!;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.archiveCategoryTitle),
          content: Text(l10n.archiveCategoryBody(categoryName)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.archiveActionLabel),
            ),
          ],
        );
      },
    );
    return approved == true;
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
      case 'categoryNameRequired':
        return l10n.categoryNameRequired;
      case 'categoryNameTooLong':
        return l10n.categoryNameTooLong;
      case 'invalidColorHex':
        return l10n.invalidColorHex;
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
