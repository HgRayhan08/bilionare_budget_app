import 'package:bilionare_budget_app/model/transaction_model.dart';
import 'package:get/get.dart';
import '../local_storage/local_storage.dart';

class TransactionController extends GetxController {
  final LocalStorage _localStorage = LocalStorage();

  var allTransactions = <TransactionModel>[].obs;
  var incomeTransactions = <TransactionModel>[].obs;
  var expenseTransactions = <TransactionModel>[].obs;
  var totalBalance = 0.obs;
  var dailyTransactions = <TransactionModel>[].obs;
  var weeklyTransactions = <TransactionModel>[].obs;
  var monthlyTransactions = <TransactionModel>[].obs;
  var categories = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllData();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    categories.value = await _localStorage.getCategories();
  }

  Future<void> updateCategoryOrder(String category) async {
    final updatedCategories = await _localStorage.updateCategoryOrder(category);
    categories.value = updatedCategories;
  }

  /// METHOD BARU: Menambah kategori baru
  Future<bool> addCategory(String newCategory) async {
    bool success = await _localStorage.createCategory(newCategory);
    if (success) {
      await fetchCategories(); // Refresh list kategori
    }
    return success;
  }

  /// METHOD BARU: Menghapus kategori
  Future<void> removeCategory(String category) async {
    await _localStorage.deleteCategory(category);
    await fetchCategories(); // Refresh list kategori
  }

  Future<bool> addTransaction(TransactionModel transaction) async {
    try {
      await _localStorage.createTransaction(transaction);
      await updateCategoryOrder(transaction.category);
      await fetchAllData();
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      allTransactions.removeWhere((t) => t.id == id);
      await _localStorage.deleteTransaction(id);
      await fetchAllData();
    } catch (e) {
      print(e);
    }
  }

  // --- Method lainnya tidak berubah ---
  Future<void> fetchAllData() async {
    allTransactions.value = await _localStorage.getAllTransactions();
    incomeTransactions.value = await _localStorage.getTransactionsByType(
      'Income',
    );
    expenseTransactions.value = await _localStorage.getTransactionsByType(
      'Expense',
    );
    _calculateTotalBalance();
    fetchChartData();
  }

  void _calculateTotalBalance() {
    int income = incomeTransactions.fold(0, (sum, item) => sum + item.nominal);
    int expense = expenseTransactions.fold(
      0,
      (sum, item) => sum + item.nominal,
    );
    totalBalance.value = income - expense;
  }

  void fetchChartData() async {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));
    dailyTransactions.value = await _localStorage.getTransactionsByDateRange(
      startOfDay,
      endOfDay,
    );
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    startOfWeek = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));
    weeklyTransactions.value = await _localStorage.getTransactionsByDateRange(
      startOfWeek,
      endOfWeek,
    );
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    DateTime endOfMonth = DateTime(
      now.year,
      now.month + 1,
      0,
    ).add(const Duration(days: 1));
    monthlyTransactions.value = await _localStorage.getTransactionsByDateRange(
      startOfMonth,
      endOfMonth,
    );
  }
}
