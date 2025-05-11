import 'package:flutter/material.dart';

class CategoryUtils {
  // Expense categories
  static const List<String> expenseCategories = [
    'Food',
    'Transportation',
    'Entertainment',
    'Utilities',
    'Housing',
    'Healthcare',
    'Shopping',
    'Education',
    'Personal',
    'Other',
  ];

  // Income categories
  static const List<String> incomeCategories = [
    'Salary',
    'Freelance',
    'Investment',
    'Gift',
    'Bonus',
    'Refund',
    'Dividend',
    'Other',
  ];

  // Combined categories for validation or general use
  static List<String> get allCategories => [...expenseCategories, ...incomeCategories];

  static IconData getCategoryIcon(String category) {
    switch (category) {
      // Expense category icons
      case 'Food':
        return Icons.restaurant;
      case 'Transportation':
        return Icons.directions_car;
      case 'Entertainment':
        return Icons.movie;
      case 'Utilities':
        return Icons.lightbulb;
      case 'Housing':
        return Icons.home;
      case 'Healthcare':
        return Icons.medical_services;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Education':
        return Icons.school;
      case 'Personal':
        return Icons.person;
      // Income category icons
      case 'Salary':
        return Icons.account_balance;
      case 'Freelance':
        return Icons.work;
      case 'Investment':
        return Icons.trending_up;
      case 'Gift':
        return Icons.card_giftcard;
      case 'Bonus':
        return Icons.star;
      case 'Refund':
        return Icons.replay;
      case 'Dividend':
        return Icons.attach_money;
      // Default for 'Other' or unrecognized categories
      default:
        return Icons.attach_money;
    }
  }

  static Color getCategoryColor(String category) {
    switch (category) {
      // Expense category colors
      case 'Food':
        return Colors.orange;
      case 'Transportation':
        return Colors.blue;
      case 'Entertainment':
        return Colors.purple;
      case 'Utilities':
        return Colors.green;
      case 'Housing':
        return Colors.brown;
      case 'Healthcare':
        return Colors.red;
      case 'Shopping':
        return Colors.pink;
      case 'Education':
        return Colors.teal;
      case 'Personal':
        return Colors.indigo;
      // Income category colors
      case 'Salary':
        return Colors.green;
      case 'Freelance':
        return Colors.blue;
      case 'Investment':
        return Colors.purple;
      case 'Gift':
        return Colors.pink;
      case 'Bonus':
        return Colors.amber;
      case 'Refund':
        return Colors.teal;
      case 'Dividend':
        return Colors.teal;
      // Default for 'Other' or unrecognized categories
      default:
        return Colors.grey;
    }
  }

  static const Map<String, String> categoryPrefixes = {
    // Expense prefixes
    'Food': 'BFID',
    'Transportation': 'BTID',
    'Entertainment': 'BEID',
    'Utilities': 'BUID',
    'Housing': 'BHID',
    'Healthcare': 'BHCID',
    'Shopping': 'BSID',
    'Education': 'BEDID',
    'Personal': 'BPID',
    // Income prefixes
    'Salary': 'IFID',
    'Freelance': 'IFRID',
    'Investment': 'IINID',
    'Gift': 'IGID',
    'Bonus': 'IBID',
    'Refund': 'IRFID',
    'Dividend': 'IDVID',
    'Other': 'IOID',
  };

  static String getCategoryPrefix(String category) {
    return categoryPrefixes[category] ?? 'BGEN'; // Default prefix
  }
}

class SavingCategoryUtils {
  static final List<String> categories = [
    'Emergency Fund',
    'Retirement',
    'Travel',
    'Home Down Payment',
    'Car Purchase',
    'Education',
    'Debt Repayment',
    'Investments',
    'Wedding',
    'Big Purchase',
    'Other',
  ];

  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Emergency Fund':
        return Icons.emergency;
      case 'Retirement':
        return Icons.account_balance;
      case 'Travel':
        return Icons.flight;
      case 'Home Down Payment':
        return Icons.home_work;
      case 'Car Purchase':
        return Icons.directions_car;
      case 'Education':
        return Icons.school;
      case 'Debt Repayment':
        return Icons.money_off;
      case 'Investments':
        return Icons.trending_up;
      case 'Wedding':
        return Icons.favorite;
      case 'Big Purchase':
        return Icons.shopping_bag;
      default:
        return Icons.savings;
    }
  }

  static Color getCategoryColor(String category) {
    switch (category) {
      case 'Emergency Fund':
        return Colors.red;
      case 'Retirement':
        return Colors.blueGrey;
      case 'Travel':
        return Colors.blue;
      case 'Home Down Payment':
        return Colors.brown;
      case 'Car Purchase':
        return Colors.orange;
      case 'Education':
        return Colors.teal;
      case 'Debt Repayment':
        return Colors.green;
      case 'Investments':
        return Colors.purple;
      case 'Wedding':
        return Colors.pink;
      case 'Big Purchase':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  static const Map<String, String> categoryPrefixes = {
    'Emergency Fund': 'SGEF',
    'Retirement': 'SGRT',
    'Travel': 'SGTR',
    'Home Down Payment': 'SGHD',
    'Car Purchase': 'SGCP',
    'Education': 'SGED',
    'Debt Repayment': 'SGDR',
    'Investments': 'SGIN',
    'Wedding': 'SGWD',
    'Big Purchase': 'SGBP',
    'Other': 'SGOT',
  };

  static String getCategoryPrefix(String category) {
    return categoryPrefixes[category] ?? 'SGDF'; // Default savings goal prefix
  }
}