import 'package:bilionare_budget_app/controller/transaction_controller.dart';
import 'package:bilionare_budget_app/pages/create_categori_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategoryPage extends StatelessWidget {
  CategoryPage({super.key});

  final TransactionController _controller = Get.find();

  // Dialog konfirmasi penghapusan
  Future<bool?> _showConfirmationDialog(BuildContext context, String category) {
    return Get.defaultDialog<bool>(
      title: "Konfirmasi Hapus",
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      middleText:
          "Apakah Anda yakin ingin menghapus kategori '$category'?\n\n(Transaksi yang sudah ada tidak akan terhapus)",
      barrierDismissible: false,
      radius: 15,
      cancel: TextButton(
        onPressed: () => Get.back(result: false),
        child: const Text("Batal"),
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        onPressed: () => Get.back(result: true),
        child: const Text("Oke"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kategori'),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      ),
      body: Obx(() {
        if (_controller.categories.isEmpty) {
          return const Center(
            child: Text('Tidak ada kategori. Tambahkan satu!'),
          );
        }
        return ListView.builder(
          itemCount: _controller.categories.length,
          itemBuilder: (context, index) {
            final category = _controller.categories[index];
            return Dismissible(
              key: ValueKey(category),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) async {
                return await _showConfirmationDialog(context, category);
              },
              onDismissed: (direction) {
                _controller.removeCategory(category);
                Get.snackbar(
                  'Dihapus',
                  'Kategori "$category" telah dihapus.',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              background: Container(
                color: Colors.red.shade400,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.label_outline),
                  title: Text(category),
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        heroTag: 'createCategory',
        onPressed: () {
          Get.to(() => const CreateCategoryPage());
        },
        tooltip: 'Tambah Kategori',
        child: const Icon(Icons.add),
      ),
    );
  }
}
