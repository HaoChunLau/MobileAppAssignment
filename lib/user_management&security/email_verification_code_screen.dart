import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailVerificationInstructionsScreen extends StatefulWidget {
  final String email;
  final String name;
  final String phoneNumber;
  final Function onVerificationComplete;

  const EmailVerificationInstructionsScreen({
    super.key,
    required this.email,
    required this.name,
    required this.phoneNumber,
    required this.onVerificationComplete,
  });

  @override
  State<EmailVerificationInstructionsScreen> createState() =>
      _EmailVerificationInstructionsScreenState();
}

class _EmailVerificationInstructionsScreenState
    extends State<EmailVerificationInstructionsScreen> {
  // Firebase Authentication instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State variables
  late Timer _timer;
  bool _isEmailVerified = false;
  double _opacity = 0.0; // For fade-in animation
  bool _isLoading = true; // To show a loading state initially
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Start fade-in animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _opacity = 1.0;
      });
    });

    // Initial verification check with a slight delay to ensure email is sent
    Future.delayed(const Duration(seconds: 2), () {
      _checkEmailVerified();
      setState(() {
        _isLoading = false; // Stop initial loading after first check
      });
    });

    // Set up periodic verification checks
    _timer = Timer.periodic(
      const Duration(seconds: 5),
          (_) {
        print('Checking email verification...');
        _checkEmailVerified();
      },
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    try {
      // Ensure there's a current user
      if (_auth.currentUser == null) {
        print('No current user found');
        setState(() {
          _errorMessage = 'No user logged in. Please try again.';
        });
        return;
      }
      await _auth.currentUser?.reload();
      final user = _auth.currentUser;

      if (user?.emailVerified ?? false) {
        setState(() {
          _isEmailVerified = true;
        });

        _timer.cancel();

        // Call the onVerificationComplete callback to save user data
        await widget.onVerificationComplete();

        // Navigate to home screen after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        });
      } else {
        print('Email not verified yet for ${user?.email}');
      }
    } catch (e) {
      print('Error checking verification: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error checking verification: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking verification: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleCancel() async {
    try {
      // Get current user
      final User? user = _auth.currentUser;

      if (user != null) {
        // Delete the user account
        await user.delete();
      }

      // Sign out
      await _auth.signOut();

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration canceled.'),
          backgroundColor: Colors.blue,
        ),
      );

      // Navigate back to login
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (!mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error canceling registration: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );

      // Sign out anyways
      await _auth.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: AnimatedOpacity(
            opacity: _opacity,
            duration: const Duration(milliseconds: 500),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: Card(
                elevation: 8.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _isLoading
                          ? const CircularProgressIndicator()
                          : _buildStatusIndicator(),

                      const SizedBox(height: 24),

                      // Title text
                      _buildTitleText(),

                      const SizedBox(height: 16),
                      _errorMessage != null
                          ? Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      )
                          : _buildMessageText(),

                      // Conditional cancel button
                      if (!_isEmailVerified) ...[
                        const SizedBox(height: 24),
                        _buildCancelButton(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // UI Components

  Widget _buildStatusIndicator() {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Icon(
      _isEmailVerified ? Icons.check_circle : Icons.email,
      size: 80,
      color: _isEmailVerified
          ? Colors.green
          : isDarkMode
          ? Colors.white
          : Theme.of(context).primaryColor,
    );
  }

  Widget _buildTitleText() {
    return Text(
      _isEmailVerified ? 'Email Verified!' : 'Verify Your Email',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.headlineSmall?.color,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessageText() {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Text(
      _isEmailVerified
          ? 'Your email has been verified successfully. Redirecting to login screen...'
          : 'We sent a verification link to ${widget.email}. Please check your inbox or spam folder and click the link to verify your email.',
      style: TextStyle(
        fontSize: 16,
        color: _isEmailVerified
            ? Colors.green
            : isDarkMode
            ? Colors.grey[500]
            : Theme.of(context).primaryColor,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildCancelButton() {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return TextButton(
      onPressed: _handleCancel,
      child: Text(
        'Cancel and Return to Login',
        style: TextStyle(
          fontSize: 16,
          color: isDarkMode
              ? Colors.deepPurpleAccent
              : Theme.of(context).primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}