import 'dart:convert';

class TransactionModel {
  int? id;
  final int nominal;
  final String? description;
  final DateTime date;
  final String type; // 'Income' or 'Expense'
  final String category;

  TransactionModel({
    this.id,
    required this.nominal,
    this.description,
    required this.date,
    required this.type,
    required this.category,
  });

  // Konversi dari Map (JSON) ke objek TransactionModel
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      nominal: json['nominal'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      type: json['type'],
      category: json['category'],
    );
  }

  // Konversi dari objek TransactionModel ke Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nominal': nominal,
      'description': description,
      'date': date.toIso8601String(), // Simpan tanggal sebagai string ISO 8601
      'type': type,
      'category': category,
    };
  }
}
