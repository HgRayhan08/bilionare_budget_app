import 'package:bilionare_budget_app/controller/transaction_controller.dart';
import 'package:bilionare_budget_app/pages/add_transation_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final TransactionController _controller = Get.find();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dompet Pribadi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: RefreshIndicator(
        onRefresh: () => _controller.fetchAllData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total Balance Card
              Center(
                child: Container(
                  width: screenWidth * 0.9,
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Saldo',
                        style: TextStyle(fontSize: 18, color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Obx(
                        () => Text(
                          currencyFormatter.format(
                            _controller.totalBalance.value,
                          ),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Recent Transactions
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                child: Text(
                  '5 Transaksi Terakhir',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Obx(() {
                if (_controller.allTransactions.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('Belum ada transaksi.'),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _controller.allTransactions.length > 5
                      ? 5
                      : _controller.allTransactions.length,
                  itemBuilder: (ctx, index) {
                    final transaction = _controller.allTransactions[index];
                    final isIncome = transaction.type == 'Income';
                    return Dismissible(
                      key: ValueKey(transaction.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        _controller.deleteTransaction(transaction.id!);
                        Get.snackbar(
                          'Dihapus',
                          'Transaksi "${transaction.description ?? transaction.category}" telah dihapus.',
                          snackPosition: SnackPosition.BOTTOM,
                          margin: const EdgeInsets.all(10),
                        );
                      },
                      background: Container(
                        color: Colors.red.shade400,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 5,
                        ),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isIncome
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            child: Icon(
                              isIncome
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
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
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => const AddTransactionPage());
        },
        child: const Icon(Icons.add),
        tooltip: 'Tambah Transaksi',
      ),
    );
  }
}
