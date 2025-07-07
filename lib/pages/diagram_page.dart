import 'package:bilionare_budget_app/controller/transaction_controller.dart';
import 'package:bilionare_budget_app/model/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DiagramPage extends StatefulWidget {
  const DiagramPage({super.key});

  @override
  State<DiagramPage> createState() => _DiagramPageState();
}

class _DiagramPageState extends State<DiagramPage> {
  final TransactionController _controller = Get.find();
  String _filter = 'Hari'; // 'Hari', 'Minggu', 'Bulan'

  List<PieChartSectionData> _generateChartSections(
    List<TransactionModel> transactions,
  ) {
    if (transactions.isEmpty) {
      return [
        PieChartSectionData(
          color: Colors.grey.shade300,
          value: 1,
          title: 'Data Kosong',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
      ];
    }

    double totalIncome = transactions
        .where((t) => t.type == 'Income')
        .fold(0, (sum, item) => sum + item.nominal);
    double totalExpense = transactions
        .where((t) => t.type == 'Expense')
        .fold(0, (sum, item) => sum + item.nominal);

    if (totalIncome == 0 && totalExpense == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey.shade300,
          value: 1,
          title: 'Data Kosong',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
      ];
    }

    return [
      PieChartSectionData(
        color: Colors.green.shade400,
        value: totalIncome,
        title:
            '${(totalIncome / (totalIncome + totalExpense) * 100).toStringAsFixed(0)}%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.red.shade400,
        value: totalExpense,
        title:
            '${(totalExpense / (totalIncome + totalExpense) * 100).toStringAsFixed(0)}%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagram Keuangan'),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(value: 'Hari', label: Text('Hari Ini')),
                ButtonSegment<String>(
                  value: 'Minggu',
                  label: Text('Minggu Ini'),
                ),
                ButtonSegment<String>(value: 'Bulan', label: Text('Bulan Ini')),
              ],
              selected: {_filter},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _filter = newSelection.first;
                });
              },
            ),
          ),
          const SizedBox(height: 20),
          // Pie Chart
          SizedBox(
            height: 200,
            child: Obx(() {
              List<TransactionModel> transactions;
              if (_filter == 'Hari') {
                transactions = _controller.dailyTransactions;
              } else if (_filter == 'Minggu') {
                transactions = _controller.weeklyTransactions;
              } else {
                transactions = _controller.monthlyTransactions;
              }
              return PieChart(
                PieChartData(
                  sections: _generateChartSections(transactions),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    color: Colors.green.shade400,
                  ),
                  const SizedBox(width: 8),
                  const Text('Pemasukan'),
                ],
              ),
              Row(
                children: [
                  Container(width: 16, height: 16, color: Colors.red.shade400),
                  const SizedBox(width: 8),
                  const Text('Pengeluaran'),
                ],
              ),
            ],
          ),
          const Divider(height: 40),
          // Transaction List for the selected filter
          Expanded(
            child: Obx(() {
              List<TransactionModel> transactions;
              if (_filter == 'Hari') {
                transactions = _controller.dailyTransactions;
              } else if (_filter == 'Minggu') {
                transactions = _controller.weeklyTransactions;
              } else {
                transactions = _controller.monthlyTransactions;
              }

              if (transactions.isEmpty) {
                return Center(
                  child: Text('Tidak ada transaksi untuk periode ini.'),
                );
              }

              return ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (ctx, index) {
                  final transaction = transactions[index];
                  final isIncome = transaction.type == 'Income';
                  return ListTile(
                    leading: Icon(
                      isIncome
                          ? Icons.arrow_circle_down
                          : Icons.arrow_circle_up,
                      color: isIncome ? Colors.green : Colors.red,
                    ),
                    title: Text(
                      transaction.description ?? transaction.category,
                    ),
                    subtitle: Text(
                      DateFormat('dd MMM yyyy').format(transaction.date),
                    ),
                    trailing: Text(
                      '${isIncome ? '+' : '-'} ${currencyFormatter.format(transaction.nominal)}',
                      style: TextStyle(
                        color: isIncome ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
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
