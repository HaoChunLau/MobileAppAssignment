import 'package:cloud_firestore/cloud_firestore.dart';

enum DurationCategory { daily, weekly, monthly, custom; @override String toString() => name; }
enum Status { active, completed, failed, stopped, deleted; @override String toString() => name; }

class BudgetModel {
  String? budgetId;
  String budgetCategory;
  String budgetName;
  double targetAmount;    //user set
  double currentSpent;    //from expenses
  String? remark;         //can be null
  DurationCategory? duration;       //enum, can be null
  int? customDays;        //days if custom
  int? durationOverBudget;//counter for over budget days 看user坚持多久
  Status status;          //enum
  bool isRecurring;       //true = repeat, false otherwise
  DateTime? overDate;     //appear only user exceed the date
  DateTime startDate;     //default is today, user can set (we calc if duration & endDate set)
  DateTime endDate;       //we calc when duration & startDate set
  String userId;
  
  BudgetModel({
    this.budgetId,
    required this.budgetCategory,
    required this.budgetName,
    required this.targetAmount,
    required this.currentSpent,
    this.remark,
    this.duration,
    this.customDays,
    this.durationOverBudget,
    required this.status,
    required this.isRecurring,
    this.overDate,
    required this.startDate,
    required this.endDate,
    required this.userId,
  });
  
  // Convert model to Map for storing in Firestore
  Map<String, dynamic> toMap() {
    return {
      'budgetCategory': budgetCategory,
      'budgetName': budgetName,
      'targetAmount': targetAmount,
      'currentSpent': currentSpent,
      'remark': remark,
      'duration': duration?.name,
      'customDays': customDays,
      'durationOverBudget': durationOverBudget,
      'status': status.name.toString(),
      'isRecurring': isRecurring,
      'overDate': overDate != null
          ? Timestamp.fromDate(overDate!)
          : null,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'userId': userId,
    };
  }
  
  // Create model from Firestore document
  factory BudgetModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BudgetModel(
      budgetId: doc.id,
      budgetCategory: data['budgetCategory'] ?? '',
      budgetName: data['budgetName'] ?? '',
      targetAmount: (data['targetAmount'] ?? 0).toDouble(),
      currentSpent: (data['currentSpent'] ?? 0).toDouble(),
      remark: data['remark'],
      duration: _stringToDuration(data['duration']),
      status: _stringToStatus(data['status']),
      customDays: data['customDays'],
      durationOverBudget: data['durationOverBudget'] ?? 0,
      isRecurring: data['isRecurring'] ?? false,
      overDate: data['overDate'] != null
          ? (data['overDate'] as Timestamp).toDate()
          : null,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
    );
  }

  static DurationCategory? _stringToDuration(String? value) =>
      value == null ? null : DurationCategory.values.firstWhere(
            (e) => e.name == value,
        orElse: () => DurationCategory.custom,
      );

  static Status _stringToStatus(String? value) =>
      value == null ? Status.active : Status.values.firstWhere(
            (e) => e.name == value,
        orElse: () => Status.active,
      );

}