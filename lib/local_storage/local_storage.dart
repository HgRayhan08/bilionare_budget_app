import 'package:bilionare_budget_app/model/transaction_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalStorage {
  static final LocalStorage _instance = LocalStorage._internal();
  factory LocalStorage() => _instance;
  LocalStorage._internal();

  static const String _categoriesKey = 'transaction_categories';

  // --- Logika Database SQLite (Tidak Berubah) ---
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
    return List.generate(maps.length, (i) {
      return TransactionModel.fromJson(maps[i]);
    });
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

  // --- Logika Kategori SharedPreferences (DIPERBARUI) ---

  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  Future<void> _saveCategories(List<String> categories) async {
    final prefs = await _getPrefs();
    await prefs.setStringList(_categoriesKey, categories);
  }

  Future<List<String>> getCategories() async {
    final prefs = await _getPrefs();
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

  /// LOGIC BARU: Membuat kategori baru
  Future<bool> createCategory(String newCategory) async {
    if (newCategory.trim().isEmpty) return false;

    List<String> currentCategories = await getCategories();
    // Cek duplikat (tidak case-sensitive)
    if (currentCategories.any(
      (c) => c.toLowerCase() == newCategory.toLowerCase(),
    )) {
      return false; // Kategori sudah ada
    }

    currentCategories.add(newCategory.trim());
    await _saveCategories(currentCategories);
    return true;
  }

  /// LOGIC BARU: Menghapus kategori
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
