import 'package:fin_sage/core/errors/error_boundary.dart';
import 'package:fin_sage/core/utils/extensions.dart';
import 'package:fin_sage/features/reports/report_generator.dart';
import 'package:fin_sage/data/models/transaction_model.dart';
import 'package:fin_sage/l10n/generated/app_localizations.dart';
import 'package:fin_sage/logic/reports/report_cubit.dart';
import 'package:fin_sage/logic/transactions/transaction_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

enum _ReportTypeFilter { all, income, expense }

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  _ReportTypeFilter _typeFilter = _ReportTypeFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final generator = ReportGenerator();
    final localeTag = Localizations.localeOf(context).toLanguageTag();

    return ErrorBoundary(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.reportsTitle)),
        body: SafeArea(
          child: BlocBuilder<TransactionCubit, TransactionState>(
            builder: (context, txState) {
              final filteredTxs = _filterTransactions(txState.items);
              final income = filteredTxs
                  .where((tx) => tx.type == TransactionType.income)
                  .fold<double>(0, (sum, tx) => sum + tx.amount);
              final expense = filteredTxs
                  .where((tx) => tx.type == TransactionType.expense)
                  .fold<double>(0, (sum, tx) => sum + tx.amount);
              final balance = income - expense;

              return Padding(
                padding: const EdgeInsets.all(16),
                child: BlocBuilder<ReportCubit, ReportState>(
                  builder: (context, state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton.icon(
                          onPressed: state.loading ? null : () => _pickMonth(context),
                          icon: const Icon(Icons.calendar_month_outlined),
                          label: Text(
                            l10n.selectedMonthLabel(
                              DateFormat.yMMMM(localeTag).format(_selectedMonth),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ReportFilterChip(
                              label: l10n.allType,
                              selected: _typeFilter == _ReportTypeFilter.all,
                              onTap: () => setState(() => _typeFilter = _ReportTypeFilter.all),
                            ),
                            _ReportFilterChip(
                              label: l10n.incomeType,
                              selected: _typeFilter == _ReportTypeFilter.income,
                              onTap: () => setState(() => _typeFilter = _ReportTypeFilter.income),
                            ),
                            _ReportFilterChip(
                              label: l10n.expenseType,
                              selected: _typeFilter == _ReportTypeFilter.expense,
                              onTap: () => setState(() => _typeFilter = _ReportTypeFilter.expense),
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
                                Text(l10n.transactionCount(filteredTxs.length)),
                                const SizedBox(height: 8),
                                Text('${l10n.monthlyIncome}: ${income.toCurrency(localeTag)}'),
                                Text('${l10n.monthlyExpense}: ${expense.toCurrency(localeTag)}'),
                                const SizedBox(height: 8),
                                Text(
                                  '${l10n.netBalance}: ${balance.toCurrency(localeTag)}',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: state.loading
                              ? null
                              : () {
                                  context.read<ReportCubit>().run(() async {
                                    if (filteredTxs.isEmpty) {
                                      throw StateError(l10n.noDataToExport);
                                    }
                                    final title = l10n.monthlyReportTitle(
                                      DateFormat.yMMMM(localeTag).format(_selectedMonth),
                                    );
                                    final pdf = await generator.generatePdf(filteredTxs, title: title);
                                    await Printing.layoutPdf(onLayout: (_) async => pdf);
                                  });
                                },
                          icon: const Icon(Icons.picture_as_pdf),
                          label: Text(l10n.exportPdf),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: state.loading
                              ? null
                              : () {
                                  context.read<ReportCubit>().run(() async {
                                    if (filteredTxs.isEmpty) {
                                      throw StateError(l10n.noDataToExport);
                                    }
                                    final file = await generator.exportCsvFile(filteredTxs);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(l10n.csvSaved(file.path))),
                                      );
                                    }
                                  });
                                },
                          icon: const Icon(Icons.table_chart),
                          label: Text(l10n.exportCsv),
                        ),
                        if (state.loading) ...[
                          const SizedBox(height: 24),
                          const Center(child: CircularProgressIndicator()),
                        ],
                        if (state.error != null) ...[
                          const SizedBox(height: 24),
                          Text(
                            state.error!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                        ],
                      ],
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

  List<TransactionModel> _filterTransactions(List<TransactionModel> items) {
    return items
        .where((tx) => tx.date.year == _selectedMonth.year && tx.date.month == _selectedMonth.month)
        .where((tx) {
          return switch (_typeFilter) {
            _ReportTypeFilter.all => true,
            _ReportTypeFilter.income => tx.type == TransactionType.income,
            _ReportTypeFilter.expense => tx.type == TransactionType.expense,
          };
        })
        .toList(growable: false);
  }

  Future<void> _pickMonth(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedMonth = DateTime(date.year, date.month);
      });
    }
  }
}

class _ReportFilterChip extends StatelessWidget {
  const _ReportFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
