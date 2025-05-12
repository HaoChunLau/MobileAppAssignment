import 'package:cloud_firestore/cloud_firestore.dart';

enum DurationCategory { daily, weekly, monthly, custom }
enum Status { active, completed, failed, stopped, deleted }

class SavingsGoalModel {
  String? savingGoalId;
  String title;
  String goalCategory;
  String? remark;         //can be null
  DurationCategory duration;     //enum
  int? customDay;              //days if custom
  int? achieveDuration;     //counter for achieve days
  Status status;
  double targetAmount;
  double currentSaved;
  DateTime startDate;
  DateTime targetDate;
  DateTime? achieveDate;
  String userId;

  SavingsGoalModel({
    this.savingGoalId,
    required this.title,
    required this.goalCategory,
    this.remark,
    required this.duration,
    this.customDay,
    this.achieveDuration,
    required this.status,
    required this.targetAmount,
    required this.currentSaved,
    required this.startDate,
    required this.targetDate,
    this.achieveDate,
    required this.userId,
  });

  // Convert model to Map for storing in Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'goalCategory': goalCategory,
      'remark': remark,
      'duration': duration.name,
      'customDay': customDay,
      'achieveDuration': achieveDuration,
      'status': status.name,
      'targetAmount': targetAmount,
      'currentSaved': currentSaved,
      'startDate': Timestamp.fromDate(startDate),
      'targetDate': Timestamp.fromDate(targetDate),
      'achieveDate': achieveDate != null
          ? Timestamp.fromDate(achieveDate!)
          : null,
      'userId': userId,
    };
  }

  // Create model from Firestore document
  factory SavingsGoalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {}; // Safe null handling

    return SavingsGoalModel(
      savingGoalId: doc.id,
      title: data['title']?.toString() ?? '', // Safe string conversion
      goalCategory: data['goalCategory'] as String? ?? '', // Default value
      remark: data['remark']?.toString(), // Nullable field
      duration: _parseDuration(data['duration']?.toString() ?? 'weekly'),
      customDay: _parseCustomDays(data['customDay']),
      achieveDuration: data['achieveDuration'] as int?,
      status: _parseStatus(data['status']?.toString() ?? 'active'),
      targetAmount: (data['targetAmount'] as num?)?.toDouble() ?? 0.0,
      currentSaved: (data['currentSaved'] as num?)?.toDouble() ?? 0.0,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      targetDate: (data['targetDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(Duration(days: 30)),
      achieveDate: (data['achieveDate'] as Timestamp?)?.toDate(),
      userId: data['userId']?.toString() ?? '',
    );
  }

  //=======================
  //    HELPER METHOD
  //=======================
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
        return customDay ?? targetDate.difference(startDate).inDays;
    }
  }
}

class SavingsContribution {
  final String id;
  final String goalId; // Reference to the goal
  final double amount;
  final DateTime date;
  final String note;
  final String type; // 'deposit' or 'withdrawal'

  SavingsContribution({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.date,
    required this.note,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goalId': goalId,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'note': note,
      'type': type,
    };
  }

  factory SavingsContribution.fromMap(Map<String, dynamic> map) {
    return SavingsContribution(
      id: map['id'],
      goalId: map['goalId'],
      amount: (map['amount'] as num).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      note: map['note'] ?? '',
      type: map['type'],
    );
  }
}
