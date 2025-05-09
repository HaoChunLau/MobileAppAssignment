// Create this in a new file: lib/utils/category_utils.dart
import 'package:flutter/material.dart';

class CategoryUtils {
  static final List<String> categories = [
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
  
  static IconData getCategoryIcon(String category) {
    switch (category) {
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
      default:
        return Icons.attach_money;
    }
  }

  static Color getCategoryColor(String category) {
    switch (category) {
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
      default:
        return Colors.grey;
    }
  }

  static const Map<String, String> categoryPrefixes = {
    'Food': 'BFID',
    'Transportation': 'BTID',
    'Entertainment': 'BEID',
    'Utilities': 'BUID',
    'Housing': 'BHID',
    'Healthcare': 'BHCID',
    'Shopping': 'BSID',
    'Education': 'BEDID',
    'Personal': 'BPID',
    'Other': 'BOID',
  };

  static String getCategoryPrefix(String category) {
    return categoryPrefixes[category] ?? 'BGEN'; // Default prefix
  }
}