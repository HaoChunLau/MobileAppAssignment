import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  String? id;
  String title;
  double amount;
  DateTime date;
  String category;
  String? notes;
  String userId;
  bool isExpense; // true for expense, false for income
  
  TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.notes,
    required this.userId,
    required this.isExpense,
  });
  
  // Convert model to Map for storing in Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'category': category,
      'notes': notes,
      'userId': userId,
      'isExpense': isExpense,
    };
  }
  
  // Create model from Firestore document
  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      title: data['title'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      category: data['category'] ?? '',
      notes: data['notes'],
      userId: data['userId'] ?? '',
      isExpense: data['isExpense'] ?? true,
    );
  }
}