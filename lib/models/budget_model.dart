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
  DurationCategory duration;       //enum
  int? customDays;        //days if custom
  int? durationOverBudget;//counter for over budget days 看user坚持多久
  Status status;          //enum
  bool isRecurring;       //true = repeat, false otherwise
  DateTime? overDate;     //appear only user exceed the date
  DateTime? stoppedDate;     //appear only user stop the budget
  DateTime startDate;     //default is today, user can set (we calc if duration & endDate set)
  DateTime endDate;       //we calc when duration & startDate set
  String userId;

  // Calculation properties
  double get progress => (currentSpent / targetAmount).clamp(0.0, 1.0);
  bool get isOverBudget => currentSpent >= targetAmount;
  bool get isActive => status == Status.active;
  bool get isCompleted => status == Status.completed;
  bool get isFailed => status == Status.failed;

  BudgetModel({
    this.budgetId,
    required this.budgetCategory,
    required this.budgetName,
    required this.targetAmount,
    double? currentSpent,
    this.remark,
    required this.duration,
    this.customDays,
    this.durationOverBudget,
    required this.status,
    required this.isRecurring,
    this.overDate,
    this.stoppedDate,
    required this.startDate,
    required this.endDate,
    required this.userId,
  }) : currentSpent = currentSpent ?? 0.0;  // Default to 0 if not provided

  // Convert model to Map for storing in Firestore
  Map<String, dynamic> toMap() {
    return {
      'budgetCategory': budgetCategory,
      'budgetName': budgetName,
      'targetAmount': targetAmount,
      'remark': remark,
      'duration': duration.name,
      'customDays': customDays,
      'durationOverBudget': durationOverBudget,
      'status': status.name,
      'isRecurring': isRecurring,
      'overDate': overDate != null
          ? Timestamp.fromDate(overDate!)
          : null,
      'stoppedDate': stoppedDate != null
          ? Timestamp.fromDate(stoppedDate!)
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
      budgetCategory: data['budgetCategory'] as String? ?? '',
      budgetName: data['budgetName'] as String? ?? 'Unnamed Budget',
      targetAmount: (data['targetAmount'] ?? 0).toDouble(),
      remark: data['remark'],
      duration: _parseDuration(data['duration'] as String? ?? 'weekly'),
      status: _parseStatus(data['status'] as String? ?? 'active'),
      customDays: _parseCustomDays(data['customDays']),
      durationOverBudget: data['durationOverBudget'] ?? 0,
      isRecurring: data['isRecurring'] as bool? ?? false,
      overDate: data['overDate'] != null
          ? (data['overDate'] as Timestamp).toDate()
          : null,
      stoppedDate: data['stoppedDate'] != null
          ? (data['stoppedDate'] as Timestamp).toDate()
          : null,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
    );
  }

  static DurationCategory _parseDuration(String value) {
    return DurationCategory.values.firstWhere(
          (e) => e.name == value.toLowerCase(),
      orElse: () => DurationCategory.weekly, // Default fallback
    );
  }

  static Status _parseStatus(String value) {
    return Status.values.firstWhere(
          (e) => e.name == value.toLowerCase(),
      orElse: () => Status.active, // Default fallback
    );
  }

  static int? _parseCustomDays(dynamic value) {
    if (value == null) return null;

    if (value is int) {
      return value;
    } else if (value is num) {
      return value.toInt();
    } else if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }

  int get durationInDays {
    switch (duration) {
      case DurationCategory.daily:
        return 1;
      case DurationCategory.weekly:
        return 7;
      case DurationCategory.monthly:
        return DateTime(startDate.year, startDate.month + 1, 0).day;
      case DurationCategory.custom:
        return customDays ?? endDate.difference(startDate).inDays;
    }
  }

  // Update Status
  void updateStatus({DateTime? currentDate, double? spent}) {
    final now = currentDate ?? DateTime.now();

    // If already in a terminal state, don't change
    if (status != Status.active) return;

    if (spent != null){
      // Check for failed conditions
      if (currentSpent >= targetAmount) {
        status = Status.failed;
        overDate ??= now; // Set overDate if not already set
      }
      // Check for COMPLETED status (endDate passed & budget not exceeded)
      else if (now.isAfter(endDate)) {
        status = Status.completed;
      }
    }
  }

  Future<void> updateCurrentSpent(FirebaseFirestore firestore) async {
    final transactions = await firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: budgetCategory)
        .where('isExpense', isEqualTo: true)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    currentSpent = transactions.docs.fold(0.0, (accumulatedTotal, doc) {
      final amount = (doc.data()['amount'] as num).toDouble();
      return accumulatedTotal + amount;
    });

    updateStatus();
  }
}