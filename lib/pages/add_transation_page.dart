import 'package:bilionare_budget_app/controller/transaction_controller.dart';
import 'package:bilionare_budget_app/model/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final TransactionController _transactionController = Get.find();
  final _formKey = GlobalKey<FormState>();

  final _nominalController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'Expense';
  String? _selectedCategory; // Ubah menjadi nullable

  @override
  void initState() {
    super.initState();
    // Atur kategori awal dari controller setelah frame pertama selesai dibangun
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_transactionController.categories.isNotEmpty) {
        setState(() {
          _selectedCategory = _transactionController.categories.first;
        });
      }
    });
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    ).then((pickedDate) {
      if (pickedDate == null) return;
      setState(() => _selectedDate = pickedDate);
    });
  }

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        // Tampilkan pesan jika kategori belum dipilih
        Get.snackbar(
          'Gagal',
          'Silakan pilih kategori terlebih dahulu.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
        );
        return;
      }

      final enteredNominal = int.tryParse(_nominalController.text);
      if (enteredNominal == null || enteredNominal <= 0) return;

      final newTransaction = TransactionModel(
        nominal: enteredNominal,
        description: _descriptionController.text,
        date: _selectedDate,
        type: _selectedType,
        category: _selectedCategory!,
      );

      // Controller sekarang akan menangani penyimpanan dan pengurutan kategori
      bool success = await _transactionController.addTransaction(
        newTransaction,
      );

      if (success) {
        Get.back();
        Get.snackbar(
          'Sukses',
          'Transaksi berhasil ditambahkan!',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          margin: const EdgeInsets.all(10),
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );
      } else {
        Get.snackbar(
          'Gagal',
          'Terjadi kesalahan saat menyimpan transaksi.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
          margin: const EdgeInsets.all(10),
          icon: const Icon(Icons.error, color: Colors.white),
        );
      }
    }
  }

  @override
  void dispose() {
    _nominalController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Transaksi'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Widget Tanggal, Nominal, Deskripsi, Tipe (Tidak Berubah)
                // ... (Kode dari file sebelumnya) ...
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'Tanggal: ${DateFormat('dd MMMM yyyy').format(_selectedDate)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: _presentDatePicker,
                        child: const Text('Pilih Tanggal'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nominalController,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Uang (Nominal)',
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Jumlah uang tidak boleh kosong';
                    if (int.tryParse(value) == null)
                      return 'Masukkan angka yang valid';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (Opsional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tipe Transaksi',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Expense', 'Income'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) =>
                      setState(() => _selectedType = newValue!),
                ),
                const SizedBox(height: 16),

                // Dropdown Kategori (DIPERBARUI)
                Obx(() {
                  // Jika _selectedCategory masih null dan daftar kategori dari controller sudah terisi,
                  // atur nilai defaultnya ke item pertama.
                  if (_selectedCategory == null &&
                      _transactionController.categories.isNotEmpty) {
                    _selectedCategory = _transactionController.categories.first;
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Kategori Transaksi',
                      border: OutlineInputBorder(),
                    ),
                    hint: _transactionController.categories.isEmpty
                        ? const Text("Memuat...")
                        : null,
                    items: _transactionController.categories.map((
                      String category,
                    ) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedCategory = newValue!;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Kategori harus dipilih' : null,
                  );
                }),
                const SizedBox(height: 30),

                ElevatedButton.icon(
                  onPressed: _submitData,
                  icon: const Icon(Icons.save),
                  label: const Text('Simpan Transaksi'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
