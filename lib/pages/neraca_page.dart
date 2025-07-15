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
  bool _isLoading = true;

  // State untuk data neraca
  int _totalIncome = 0;
  int _totalExpense = 0;
  int _previousMonthAssets = 0;
  List<String> _allCategories = [];
  Map<String, int> _incomeByCategory = {};
  Map<String, int> _expenseByCategory = {};

  @override
  void initState() {
    super.initState();
    _selectedMonth = _months[DateTime.now().month - 1];
    _fetchDataForMonth();
  }

  Future<void> _fetchDataForMonth() async {
    setState(() => _isLoading = true);

    final monthIndex = _months.indexOf(_selectedMonth) + 1;
    final startDateOfMonth = DateTime(_currentYear, monthIndex, 1);

    // 1. Ambil Aset dari bulan sebelumnya
    final prevAssets = await _localStorage.getBalanceUpToDate(startDateOfMonth);

    // 2. Ambil semua kategori dari SharedPreferences
    final categories = await _localStorage.getCategories();

    // 3. Ambil rincian pemasukan dan pengeluaran untuk setiap kategori
    Map<String, int> incomeMap = {};
    Map<String, int> expenseMap = {};
    for (String category in categories) {
      final results = await Future.wait([
        _localStorage.getCategoryTotalForMonth(
          _currentYear,
          monthIndex,
          category,
          'Income',
        ),
        _localStorage.getCategoryTotalForMonth(
          _currentYear,
          monthIndex,
          category,
          'Expense',
        ),
      ]);
      incomeMap[category] = results[0];
      expenseMap[category] = results[1];
    }

    // 4. Hitung total keseluruhan
    final totalIncome = incomeMap.values.fold(0, (sum, item) => sum + item);
    // ✅ FIX: Logika perhitungan total pengeluaran diperbaiki.
    final totalExpense = expenseMap.values.fold(0, (sum, item) => sum + item);

    // 5. Update state untuk me-render UI
    setState(() {
      _previousMonthAssets = prevAssets;
      _allCategories = categories;
      _incomeByCategory = incomeMap;
      _expenseByCategory = expenseMap;
      _totalIncome = totalIncome;
      _totalExpense = totalExpense;
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
    // Total ini adalah surplus/defisit bulan ini, belum termasuk aset bulan lalu
    final currentMonthTotal = _totalIncome - _totalExpense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Neraca Bulanan'),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Dropdown Bulan
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
                    setState(() => _selectedMonth = newValue);
                    _fetchDataForMonth();
                  }
                },
              ),
              const SizedBox(height: 24),

              // Container Ringkasan
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
                child: Column(
                  children: [
                    _buildInfoRow(
                      title: 'Pemasukan',
                      amount: currencyFormatter.format(_totalIncome),
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      title: 'Pengeluaran',
                      amount: currencyFormatter.format(_totalExpense),
                      color: Colors.red.shade700,
                    ),
                    const Divider(height: 30, thickness: 1),
                    _buildInfoRow(
                      title: 'Surplus/Defisit',
                      amount: currencyFormatter.format(currentMonthTotal),
                      color: currentMonthTotal >= 0
                          ? Colors.blue.shade800
                          : Colors.red.shade800,
                      isBold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tabel Rincian
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildDetailsTable(currencyFormatter, currentMonthTotal),
            ],
          ),
        ),
      ),
    );
  }

  // Widget untuk Tabel Rincian
  Widget _buildDetailsTable(NumberFormat formatter, int total) {
    return Table(
      border: TableBorder.all(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      columnWidths: const {
        0: FlexColumnWidth(2.5),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
      },
      children: [
        // Header Tabel
        _buildHeaderRow(),
        // ✅ FIX: Baris yang duplikat dan salah telah dihapus.
        // Hanya baris ini yang digunakan untuk menampilkan aset bulan lalu.
        _buildTableRow('Assets', null, total, formatter),
        _buildTableRow(
          'Aset Bulan Lalu',
          _previousMonthAssets, // Masuk di kolom Debit
          null, // Kosong di kolom Kredit
          formatter,
          isAsset: true,
        ),
        // Baris per Kategori
        ..._allCategories.map((category) {
          return _buildTableRow(
            category,
            _incomeByCategory[category] ?? 0,
            _expenseByCategory[category] ?? 0,
            formatter,
          );
        }).toList(),
        // Baris Total
        _buildTableRow(
          'Total ',
          _totalIncome,
          total + _totalExpense,
          formatter,
          isTotal: true,
        ),
      ],
    );
  }

  // Helper untuk Header Tabel
  TableRow _buildHeaderRow() {
    return TableRow(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      children: ['Kategori', 'Debit', 'Kredit']
          .map(
            (title) => Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          )
          .toList(),
    );
  }

  // Helper untuk Baris Data Tabel
  TableRow _buildTableRow(
    String title,
    int? income, // Direpresentasikan sebagai Debit
    int? expense, // Direpresentasikan sebagai Kredit
    NumberFormat formatter, {
    bool isTotal = false,
    bool isAsset = false,
  }) {
    final style = TextStyle(
      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
    );
    return TableRow(
      decoration: BoxDecoration(
        color: isTotal ? Colors.blue.shade50 : Colors.white,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(title, style: style),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            (income ?? 0) == 0 && !isAsset
                ? '-'
                : formatter.format(income ?? 0),
            textAlign: TextAlign.right,
            style: style.copyWith(color: Colors.green.shade800),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            (expense ?? 0) == 0 ? '-' : formatter.format(expense ?? 0),
            textAlign: TextAlign.right,
            style: style.copyWith(color: Colors.red.shade800),
          ),
        ),
      ],
    );
  }

  // Helper untuk Baris Info di Container Atas
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
