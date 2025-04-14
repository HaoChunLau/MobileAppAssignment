import 'package:flutter/material.dart';

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
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
          color: Theme.of(context).primaryColor,
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
                _isPasswordVisible 
                    ? Icons.visibility_off 
                    : Icons.visibility,
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
              style: TextStyle(color: Colors.grey[800]),
              children: [
                TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
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
    return ElevatedButton(
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
            Navigator.pop(context); // Go back to login screen
          },
          child: Text('Login'),
        ),
      ],
    );
  }

  void _handleSignUp() {
    // Validate inputs
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    // For demonstration, just navigate to home screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Account created successfully')),
    );
    
    Navigator.pushReplacementNamed(context, '/');
  }
}