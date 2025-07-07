import 'package:bilionare_budget_app/controller/transaction_controller.dart';
import 'package:bilionare_budget_app/model/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TransactionController _controller = Get.find();
  String _selectedType = 'All'; // 'All', 'Income', 'Expense'

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      ),
      body: Column(
        children: [
          // Switch Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(
                  value: 'All',
                  label: Text('Semua'),
                  icon: Icon(Icons.list_alt),
                ),
                ButtonSegment<String>(
                  value: 'Income',
                  label: Text('Pemasukan'),
                  icon: Icon(Icons.arrow_downward),
                ),
                ButtonSegment<String>(
                  value: 'Expense',
                  label: Text('Pengeluaran'),
                  icon: Icon(Icons.arrow_upward),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedType = newSelection.first;
                });
              },
            ),
          ),
          // Transaction List
          Expanded(
            child: Obx(() {
              List<TransactionModel> transactions;
              if (_selectedType == 'Income') {
                transactions = _controller.incomeTransactions;
              } else if (_selectedType == 'Expense') {
                transactions = _controller.expenseTransactions;
              } else {
                transactions = _controller.allTransactions;
              }

              if (transactions.isEmpty) {
                return Center(
                  child: Text('Tidak ada transaksi untuk kategori ini.'),
                );
              }

              return ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (ctx, index) {
                  final transaction = transactions[index];
                  final isIncome = transaction.type == 'Income';
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isIncome
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        child: Icon(
                          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isIncome
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                      title: Text(
                        transaction.description?.isNotEmpty == true
                            ? transaction.description!
                            : transaction.category,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        DateFormat('dd MMMM yyyy').format(transaction.date),
                      ),
                      trailing: Text(
                        '${isIncome ? '+' : '-'} ${currencyFormatter.format(transaction.nominal)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isIncome
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
