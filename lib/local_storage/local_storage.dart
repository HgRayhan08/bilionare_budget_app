import 'package:bilionare_budget_app/model/transaction_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalStorage {
  static final LocalStorage _instance = LocalStorage._internal();
  factory LocalStorage() => _instance;
  LocalStorage._internal();

  static const String _categoriesKey = 'transaction_categories';
  static Database? _database;
  final String _tableName = 'transactions';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'finance.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nominal INTEGER NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL
      )
    ''');
  }

  // --- LOGIC BARU: Menjumlahkan total untuk KATEGORI SPESIFIK dalam satu bulan ---
  Future<int> getCategoryTotalForMonth(
    int year,
    int month,
    String category,
    String type,
  ) async {
    final db = await database;
    final DateTime startDate = DateTime(year, month, 1);
    final DateTime endDate = DateTime(year, month + 1, 1);

    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT SUM(nominal) as total FROM $_tableName WHERE type = ? AND category = ? AND date >= ? AND date < ?',
      [type, category, startDate.toIso8601String(), endDate.toIso8601String()],
    );

    return (result.first['total'] as int?) ?? 0;
  }

  // --- LOGIC BARU: Menghitung saldo (income - expense) hingga tanggal tertentu ---
  Future<int> getBalanceUpToDate(DateTime endDate) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT type, SUM(nominal) as total FROM $_tableName WHERE date < ? GROUP BY type',
      [endDate.toIso8601String()],
    );

    int income = 0;
    int expense = 0;

    for (var row in result) {
      if (row['type'] == 'Income') {
        income = (row['total'] as int?) ?? 0;
      } else if (row['type'] == 'Expense') {
        expense = (row['total'] as int?) ?? 0;
      }
    }

    return income - expense;
  }

  Future<List<TransactionModel>> getTransactionsByType(String type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return TransactionModel.fromJson(maps[i]);
    });
  }

  Future<List<TransactionModel>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return TransactionModel.fromJson(maps[i]);
    });
  }

  // --- Metode yang sudah ada (tidak berubah) ---
  Future<int> getTotalForMonth(int year, int month, String type) async {
    final db = await database;
    final DateTime startDate = DateTime(year, month, 1);
    final DateTime endDate = DateTime(year, month + 1, 1);
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT SUM(nominal) as total FROM $_tableName WHERE type = ? AND date >= ? AND date < ?',
      [type, startDate.toIso8601String(), endDate.toIso8601String()],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> createTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.insert(_tableName, transaction.toJson());
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'date DESC',
    );
    return List.generate(
      maps.length,
      (i) => TransactionModel.fromJson(maps[i]),
    );
  }

  Future<List<String>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_categoriesKey)) {
      return prefs.getStringList(_categoriesKey) ?? [];
    } else {
      final defaultCategories = [
        'Makan',
        'Belanja',
        'Jalan-jalan',
        'Gaji',
        'Warisan',
        'Lain-lain',
      ];
      await _saveCategories(defaultCategories);
      return defaultCategories;
    }
  }

  Future<void> _saveCategories(List<String> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_categoriesKey, categories);
  }

  Future<bool> createCategory(String newCategory) async {
    if (newCategory.trim().isEmpty) return false;
    List<String> currentCategories = await getCategories();
    if (currentCategories.any(
      (c) => c.toLowerCase() == newCategory.toLowerCase(),
    ))
      return false;
    currentCategories.add(newCategory.trim());
    await _saveCategories(currentCategories);
    return true;
  }

  Future<void> deleteCategory(String categoryToDelete) async {
    List<String> currentCategories = await getCategories();
    currentCategories.remove(categoryToDelete);
    await _saveCategories(currentCategories);
  }

  Future<List<String>> updateCategoryOrder(String selectedCategory) async {
    List<String> currentCategories = await getCategories();
    currentCategories.remove(selectedCategory);
    currentCategories.insert(0, selectedCategory);
    await _saveCategories(currentCategories);
    return currentCategories;
  }
}
