import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app_assignment/services/email_service.dart'; // Import the new email service

class EmailUtils {
  static Future<void> sendVerificationEmail({
    required String email,
    required BuildContext context,
    required Map<String, String> signupData, // Store signup data temporarily
  }) async {
    try {
      // Generate a 6-digit verification code
      final code = (Random().nextInt(900000) + 100000).toString();
      final now = DateTime.now();
      final expiresAt = now.add(Duration(minutes: 10)); // Code expires in 10 minutes

      // Store the code and signup data in Firestore
      await FirebaseFirestore.instance.collection('email_verifications').add({
        'email': email,
        'code': code,
        'createdAt': now,
        'expiresAt': expiresAt,
        'signupData': signupData, // Store signup data
      });

      // Send real email using our EmailService
      await EmailService.sendVerificationEmail(
        email: email,
        code: code,
        context: context,
      );

      // Keep this for development/testing only - remove for production
      // Show the code in a SnackBar (for testing purposes)
      if (email.contains('test.com')) { // Only show codes for test emails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('[DEV MODE] Code for $email: $code'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send verification email: ${e.toString()}')),
      );
      rethrow; // Rethrow to handle in the calling function
    }
  }
}