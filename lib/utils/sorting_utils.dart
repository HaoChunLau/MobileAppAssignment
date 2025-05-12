// lib/utils/sorting_utils.dart
import 'package:flutter/material.dart';
import 'package:mobile_app_assignment/utils/category_utils.dart';
import 'package:mobile_app_assignment/models/budget_model.dart';
import 'package:mobile_app_assignment/models/savings_goal_model.dart';

enum SortCategory {
  name,
  amount,
  date,
  category,
  progress,
  remainDays,
}

enum SortDirection {
  ascending,
  descending,
}

class SortingOptions {
  final SortCategory category;
  final SortDirection direction;

  const SortingOptions({
    this.category = SortCategory.name,
    this.direction = SortDirection.ascending,
  });

  SortingOptions copyWith({
    SortCategory? category,
    SortDirection? direction,
  }) {
    return SortingOptions(
      category: category ?? this.category,
      direction: direction ?? this.direction,
    );
  }
}

class SortingUtils {
  static String getSortCategoryName(SortCategory category) {
    switch (category) {
      case SortCategory.name:
        return 'Name';
      case SortCategory.amount:
        return 'Amount';
      case SortCategory.date:
        return 'Date';
      case SortCategory.category:
        return 'Category';
      case SortCategory.progress:
        return 'Progress';
      case SortCategory.remainDays:
        return 'Remaining Days';
    }
  }

  static IconData getSortCategoryIcon(SortCategory category) {
    switch (category) {
      case SortCategory.name:
        return Icons.sort_by_alpha;
      case SortCategory.amount:
        return Icons.attach_money;
      case SortCategory.date:
        return Icons.date_range;
      case SortCategory.category:
        return Icons.category;
      case SortCategory.progress:
        return Icons.trending_up;
      case SortCategory.remainDays:
        return Icons.timer_sharp;
    }
  }

  static List<BudgetModel> sortBudgets({
    required List<BudgetModel> budgets,
    required SortingOptions options,
    required Map<String, double> spentPerCategory,
    DateTime? currentDate,
  }) {
    final directionMultiplier = options.direction == SortDirection.ascending ? 1 : -1;
    final today = currentDate ?? DateTime.now();

    return List<BudgetModel>.from(budgets)..sort((a, b) {
      switch (options.category) {
        case SortCategory.name:
          return a.budgetName.compareTo(b.budgetName) * directionMultiplier;
        case SortCategory.amount:
          return a.targetAmount.compareTo(b.targetAmount) * directionMultiplier;
        case SortCategory.date:
          return a.startDate.compareTo(b.startDate) * directionMultiplier;
        case SortCategory.category:
        // Sort by predefined category order
          final indexA = CategoryUtils.expenseCategories.indexOf(a.budgetCategory);
          final indexB = CategoryUtils.expenseCategories.indexOf(b.budgetCategory);
          if (indexA == -1 || indexB == -1) {
            return (indexA == -1 ? 1 : -1) * directionMultiplier;
          }
          return indexA.compareTo(indexB) * directionMultiplier;
        case SortCategory.progress:
          final spentA = spentPerCategory[a.budgetCategory] ?? 0;
          final spentB = spentPerCategory[b.budgetCategory] ?? 0;
          final progressA = a.targetAmount > 0 ? spentA / a.targetAmount : 0;
          final progressB = b.targetAmount > 0 ? spentB / b.targetAmount : 0;
          return progressA.compareTo(progressB) * directionMultiplier;
        case SortCategory.remainDays:
          final remainingDaysA = a.endDate.difference(today).inDays;
          final remainingDaysB = b.endDate.difference(today).inDays;
          return remainingDaysA.compareTo(remainingDaysB) * directionMultiplier;
      }
    });
  }

  static List<SavingsGoalModel> sortSavings({
    required List<SavingsGoalModel> savings,
    required SortingOptions options,
    DateTime? currentDate,
  }) {
    final directionMultiplier = options.direction == SortDirection.ascending ? 1 : -1;
    final today = currentDate ?? DateTime.now();

    return List<SavingsGoalModel>.from(savings)..sort((a, b) {
      switch (options.category) {
        case SortCategory.name:
          return a.title.compareTo(b.title) * directionMultiplier;
        case SortCategory.amount:
          return a.currentSaved.compareTo(b.currentSaved) * directionMultiplier;
        case SortCategory.date:
          return a.startDate.compareTo(b.startDate) * directionMultiplier;
        case SortCategory.category:
        // Sort by predefined category order
          final indexA = SavingCategoryUtils.categories.indexOf(a.goalCategory);
          final indexB = SavingCategoryUtils.categories.indexOf(b.goalCategory);
          if (indexA == -1 || indexB == -1) {
            return (indexA == -1 ? 1 : -1) * directionMultiplier;
          }
          return indexA.compareTo(indexB) * directionMultiplier;
        case SortCategory.progress:
          final savedA = a.currentSaved;
          final savedB = b.currentSaved;
          final progressA = a.targetAmount > 0 ? savedA / a.targetAmount : 0;
          final progressB = b.targetAmount > 0 ? savedB / b.targetAmount : 0;
          return progressA.compareTo(progressB) * directionMultiplier;
        case SortCategory.remainDays:
          final remainingDaysA = a.targetDate.difference(today).inDays;
          final remainingDaysB = b.targetDate.difference(today).inDays;
          return remainingDaysA.compareTo(remainingDaysB) * directionMultiplier;
      }
    });
  }
}