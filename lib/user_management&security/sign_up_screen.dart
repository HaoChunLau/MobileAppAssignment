import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app_assignment/models/user_model.dart';
import 'package:mobile_app_assignment/user_management&security/email_verification_code_screen.dart';

class SignUpScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  const SignUpScreen({super.key, required this.onThemeChanged});

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeToTerms = false;
  bool _isLoading = false;
  double _passwordStrength = 0.0;

  void _updatePasswordStrength(String password) {
    double strength = 0.0;
    if (password.length >= 8) strength += 0.25;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.25;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.25;
    setState(() {
      _passwordStrength = strength;
    });
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_validateInputs()) return;
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the terms')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final signInMethods =
          await _auth.fetchSignInMethodsForEmail(_emailController.text.trim());
      if (signInMethods.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'This email is already registered. Please use a different email or log in.')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await userCredential.user!.sendEmailVerification();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Account created! Please check your email for verification link.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EmailVerificationInstructionsScreen(
            email: _emailController.text.trim(),
            name: _nameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            onVerificationComplete: _onVerificationComplete,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onVerificationComplete() async {
    try {
      final User? user = _auth.currentUser;

      if (user != null) {
        final UserModel userModel = UserModel(
          id: user.uid,
          email: user.email ?? _emailController.text.trim(),
          name: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          currency: 'MYR (RM)',
          createdAt: DateTime.now(),
          emailVerified: true,
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());
      }
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  bool _validateInputs() {
    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter your full name');
      return false;
    }

    if (_emailController.text.trim().isEmpty ||
        !EmailValidator.validate(_emailController.text.trim())) {
      _showError('Please enter a valid email address');
      return false;
    }

    final phoneRegex = RegExp(r'^(\+?60|0)[0-9]{8,11}$');
    if (_phoneController.text.isNotEmpty &&
        !phoneRegex.hasMatch(_phoneController.text.trim())) {
      _showError('Please enter a valid Malaysian phone number');
      return false;
    }

    if (_passwordController.text.length < 8) {
      _showError('Password must be at least 8 characters');
      return false;
    }

    if (_passwordStrength != 1.0) {
      _showError(
          'Password must be at least 8 characters long, contain an uppercase letter, a number, and a special character');
      return false;
    }

    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              SizedBox(height: 24),
              _buildSignUpForm(),
              SizedBox(height: 16),
              _buildTermsAgreement(),
              SizedBox(height: 24),
              _buildSignUpButton(),
              SizedBox(height: 16),
              _buildLoginSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(
          Icons.account_circle,
          size: 64,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Theme.of(context).primaryColor,
        ),
        SizedBox(height: 16),
        Text(
          'Join Clarity Finance',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Create an account to start managing your finances',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSignUpForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        SizedBox(height: 16),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          obscureText: !_isPasswordVisible,
          onChanged: (value) => _updatePasswordStrength(value),
          keyboardType: TextInputType.visiblePassword,
        ),
        SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
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
    double strength = _passwordStrength;
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
        if (_passwordController.text.isNotEmpty &&
            _passwordController.text.length < 8)
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

  Widget _buildTermsAgreement() {
    return Row(
      children: [
        Checkbox(
          value: _agreeToTerms,
          onChanged: (value) {
            setState(() {
              _agreeToTerms = value ?? false;
            });
          },
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Theme.of(context).primaryColor,
              ),
              children: [
                TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.purple
                        : Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.purple
                        : Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpButton() {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : ElevatedButton(
            onPressed: _agreeToTerms ? _handleSignUp : null,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Create Account',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
  }

  Widget _buildLoginSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Already have an account?'),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Login'),
        ),
      ],
    );
  }
}