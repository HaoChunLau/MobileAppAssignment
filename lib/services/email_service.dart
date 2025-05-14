import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class EmailService {
  // Your email sending provider API key (store this in environment variables in production)
  static const String _apiKey = 'AIzaSyAquwYFe52wind79acgrQZt-dH8tx--2xs';

  // Method to send verification email using Firebase Cloud Functions
  static Future<void> sendVerificationEmail({
    required String email,
    required String code,
    required BuildContext context,
  }) async {
    try {
      // Option 1: If you have Firebase Cloud Functions set up
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'sendVerificationEmail',
      );

      final response = await callable.call({
        'email': email,
        'code': code,
      });

      if (response.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification email sent to $email. Please check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(response.data['error'] ?? 'Failed to send email');
      }

      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send verification email: ${e.toString()}')),
      );
      rethrow;
    }
  }
}