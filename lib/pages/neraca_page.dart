import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../local_storage/local_storage.dart';

class NeracaPage extends StatefulWidget {
  const NeracaPage({super.key});

  @override
  State<NeracaPage> createState() => _NeracaPageState();
}

class _NeracaPageState extends State<NeracaPage> {
  final LocalStorage _localStorage = LocalStorage();
  final int _currentYear = DateTime.now().year;

  // Daftar bulan dalam bahasa Indonesia
  final List<String> _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  late String _selectedMonth;
  int _totalIncome = 0;
  int _totalExpense = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Atur bulan yang dipilih ke bulan saat ini saat halaman pertama kali dibuka
    _selectedMonth = _months[DateTime.now().month - 1];
    // Ambil data untuk bulan yang dipilih
    _fetchDataForMonth();
  }

  // Fungsi untuk mengambil dan menghitung data dari database
  Future<void> _fetchDataForMonth() async {
    setState(() {
      _isLoading = true;
    });

    final monthIndex = _months.indexOf(_selectedMonth) + 1;

    // Ambil total income dan expense secara bersamaan
    final results = await Future.wait([
      _localStorage.getTotalForMonth(_currentYear, monthIndex, 'Income'),
      _localStorage.getTotalForMonth(_currentYear, monthIndex, 'Expense'),
    ]);

    setState(() {
      _totalIncome = results[0];
      _totalExpense = results[1];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final total = _totalIncome - _totalExpense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Neraca Bulanan'),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dropdown untuk memilih bulan
            DropdownButtonFormField<String>(
              value: _selectedMonth,
              decoration: InputDecoration(
                labelText: 'Pilih Bulan (Tahun $_currentYear)',
                border: const OutlineInputBorder(),
              ),
              items: _months.map((String month) {
                return DropdownMenuItem<String>(
                  value: month,
                  child: Text(month),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedMonth = newValue;
                  });
                  _fetchDataForMonth(); // Ambil data baru saat bulan diganti
                }
              },
            ),
            const SizedBox(height: 24),

            // Container untuk menampilkan hasil
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade100,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        // Baris Pemasukan
                        _buildInfoRow(
                          title: 'Pemasukan',
                          amount: currencyFormatter.format(_totalIncome),
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(height: 12),
                        // Baris Pengeluaran
                        _buildInfoRow(
                          title: 'Pengeluaran',
                          amount: currencyFormatter.format(_totalExpense),
                          color: Colors.red.shade700,
                        ),
                        const Divider(height: 30, thickness: 1),
                        // Baris Total
                        _buildInfoRow(
                          title: 'Total',
                          amount: currencyFormatter.format(total),
                          color: total >= 0
                              ? Colors.blue.shade800
                              : Colors.red.shade800,
                          isBold: true,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget helper untuk membuat baris informasi
  Widget _buildInfoRow({
    required String title,
    required String amount,
    required Color color,
    bool isBold = false,
  }) {
    final style = TextStyle(
      fontSize: isBold ? 18 : 16,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      color: isBold ? color : Colors.black87,
    );
    final amountStyle = TextStyle(
      fontSize: isBold ? 18 : 16,
      fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
      color: color,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: style),
        Text(amount, style: amountStyle),
      ],
    );
  }
}
