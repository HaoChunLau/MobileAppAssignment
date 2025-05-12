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

      // Option 2: Direct API integration (alternative if you prefer not using Cloud Functions)
      // Uncomment below and comment out Option 1 code above if you want to use this approach
      /*
      // Example using SendGrid API
      final url = Uri.parse('https://api.sendgrid.com/v3/mail/send');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'personalizations': [
            {
              'to': [{'email': email}],
              'subject': 'Your Clarity Finance Verification Code',
            }
          ],
          'from': {'email': 'noreply@clarityfinance.com'},
          'content': [
            {
              'type': 'text/html',
              'value': '''
                <h1>Email Verification</h1>
                <p>Thank you for signing up with Clarity Finance!</p>
                <p>Your verification code is: <strong>$code</strong></p>
                <p>This code will expire in 10 minutes.</p>
              '''
            }
          ]
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification email sent to $email. Please check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to send email: ${response.body}');
      }
      */
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send verification email: ${e.toString()}')),
      );
      rethrow;
    }
  }
}