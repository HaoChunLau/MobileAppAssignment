import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ChangePasswordScreenState createState() => ChangePasswordScreenState();
}

class ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentPasswordController =
  TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Add listener to newPasswordController to update UI on text change
    _newPasswordController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    // Remove the listener to prevent memory leaks
    _newPasswordController.removeListener(() {});
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Change Password'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 24),
            _buildPasswordForm(),
            SizedBox(height: 32),
            _buildUpdateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.lock_reset,
          size: 48,
          color: Theme.of(context).primaryColor,
        ),
        SizedBox(height: 16),
        Text(
          'Change Your Password',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Create a strong password with a mix of letters, numbers, and symbols',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordForm() {
    return Column(
      children: [
        TextField(
          controller: _currentPasswordController,
          decoration: InputDecoration(
            labelText: 'Current Password',
            prefixIcon: Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _isCurrentPasswordVisible
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          obscureText: !_isCurrentPasswordVisible,
          keyboardType: TextInputType.visiblePassword,
        ),
        SizedBox(height: 16),
        TextField(
          controller: _newPasswordController,
          decoration: InputDecoration(
            labelText: 'New Password',
            prefixIcon: Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                _isNewPasswordVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _isNewPasswordVisible = !_isNewPasswordVisible;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          obscureText: !_isNewPasswordVisible,
          keyboardType: TextInputType.visiblePassword,
        ),
        SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          decoration: InputDecoration(
            labelText: 'Confirm New Password',
            prefixIcon: Icon(Icons.lock_clock),
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          obscureText: !_isConfirmPasswordVisible,
          keyboardType: TextInputType.visiblePassword,
        ),
        SizedBox(height: 16),
        _buildPasswordStrengthIndicator(),
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    // Implement a simple password strength indicator
    // based on the new password value
    String password = _newPasswordController.text;
    double strength = 0;

    if (password.length >= 8) strength += 0.25;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.25;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.25;

    Color indicatorColor;
    String strengthText;

    if (strength <= 0.25) {
      indicatorColor = Colors.red;
      strengthText = 'Weak';
    } else if (strength <= 0.5) {
      indicatorColor = Colors.orange;
      strengthText = 'Medium';
    } else if (strength <= 0.75) {
      indicatorColor = Colors.yellow;
      strengthText = 'Good';
    } else {
      indicatorColor = Colors.green;
      strengthText = 'Strong';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password Strength',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: strength,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        SizedBox(height: 8),
        Text(
          strengthText,
          style: TextStyle(
            color: indicatorColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (password.isNotEmpty && password.length < 8)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Password should be at least 8 characters',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUpdateButton() {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : ElevatedButton(
      onPressed: _handlePasswordChange,
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        'Update Password',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _handlePasswordChange() async {
    // Validate inputs
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields')),
        );
      }
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New passwords do not match')),
        );
      }
      return;
    }

    if (_newPasswordController.text.length < 8) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Password should be at least 8 characters')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get current user
      final User? user = _auth.currentUser;

      if (user == null) {
        throw Exception("User not authenticated");
      }

      // Get credentials with current password for reauthentication
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      // Reauthenticate user
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(_newPasswordController.text);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String errorMessage = 'Failed to update password';

      if (e.code == 'wrong-password') {
        errorMessage = 'The current password you entered is incorrect';
      } else if (e.code == 'weak-password') {
        errorMessage = 'The new password is too weak';
      } else if (e.code == 'requires-recent-login') {
        errorMessage = 'Please log in again before changing your password';
        // You could handle this by signing the user out and redirecting to login
        await _auth.signOut();
        if (mounted) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (route) => false);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}