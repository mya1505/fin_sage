import 'package:fin_sage/core/errors/error_boundary.dart';
import 'package:fin_sage/features/reports/report_generator.dart';
import 'package:fin_sage/l10n/generated/app_localizations.dart';
import 'package:fin_sage/logic/reports/report_cubit.dart';
import 'package:fin_sage/logic/transactions/transaction_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final generator = ReportGenerator();

    return ErrorBoundary(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.reportsTitle)),
        body: SafeArea(
          child: BlocBuilder<ReportCubit, ReportState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: state.loading
                          ? null
                          : () {
                              context.read<ReportCubit>().run(() async {
                                final txs = context.read<TransactionCubit>().state.items;
                                final pdf = await generator.generatePdf(txs);
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
                                final txs = context.read<TransactionCubit>().state.items;
                                await generator.generateCsv(txs);
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
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
