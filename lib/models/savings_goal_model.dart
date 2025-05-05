import 'package:cloud_firestore/cloud_firestore.dart';

enum DurationCategory { daily, weekly, monthly, custom }
enum Status { active, completed, failed, stopped, deleted }
enum PriorityLevel { low, medium, high }

class SavingsGoalModel {
  String? savingGoalId;
  String title;
  String goalCategory;
  String? remark;         //can be null
  DurationCategory? duration;     //enum, can be null
  int? customDays;              //days if custom
  int? achieveDuration;     //counter for achieve days
  Status status;
  PriorityLevel priority;
  bool isRecurring;
  String? savingName;
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
    this.duration,
    this.customDays,
    this.achieveDuration,
    required this.status,
    required this.priority,
    required this.isRecurring,
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
      'category': goalCategory,
      'remark': remark,
      'duration': duration,
      'customDays': customDays,
      'achieveDuration': achieveDuration,
      'status': status.name,
      'priority': priority,
      'isRecurring': isRecurring,
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
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SavingsGoalModel(
      savingGoalId: doc.id,
      title: data['title'] ?? '',
      goalCategory: data['goalCategory'] ?? '',
      remark: data['remark'] ?? '',
      duration: data['duration'] != null
          ? DurationCategory.values.firstWhere(
              (e) => e.name == data['duration'],
          orElse: () => DurationCategory.custom)
          : null,
      customDays: data['customDays'],
      achieveDuration: data['achieveDuration'],
      status: data['status'] != null
          ? Status.values.firstWhere(
            (e) => e.name == data['status'],
        orElse: () => Status.active,
      )
          : Status.active,
      priority: data['priority'] != null
          ? PriorityLevel.values.firstWhere(
            (e) => e.name == data['priority'],
        orElse: () => PriorityLevel.medium,
      )
          : PriorityLevel.medium,
      isRecurring: data['isRecurring'] ?? false,
      targetAmount: (data['targetAmount'] ?? 0).toDouble(),
      currentSaved: (data['currentSaved'] ?? 0).toDouble(),
      startDate: (data['startDate'] as Timestamp).toDate(),
      targetDate: (data['targetDate'] as Timestamp).toDate(),
      achieveDate: data['achieveDate'] != null
          ? (data['achieveDate'] as Timestamp).toDate()
          : null,
      userId: data['userId'] ?? '',
    );
  }
}