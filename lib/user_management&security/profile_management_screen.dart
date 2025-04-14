import 'package:flutter/material.dart';

class ProfileManagementScreen extends StatefulWidget {
  const ProfileManagementScreen({super.key});

  @override
  ProfileManagementScreenState createState() => ProfileManagementScreenState();
}

class ProfileManagementScreenState extends State<ProfileManagementScreen> {
  // Mock user data - in a real app, you'd load this from a database or user service
  String _name = 'Ali Bin Abu';
  String _email = 'ali.abu@example.com';
  String _phoneNumber = '+60 12-345-6789';
  String _currency = 'MYR (RM)';
  
  // Controllers for text editing
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  // Edit mode state
  bool _isEditing = false;
  
  @override
  void initState() {
    super.initState();
    // Initialize controllers with current values
    _nameController.text = _name;
    _emailController.text = _email;
    _phoneController.text = _phoneNumber;
  }
  
  @override
  void dispose() {
    // Clean up controllers
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Management'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                // Save the changes
                _saveChanges();
              }
              // Toggle edit mode
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            SizedBox(height: 24),
            _buildPersonalInfoSection(),
            SizedBox(height: 24),
            _buildPreferencesSection(),
            SizedBox(height: 24),
            _buildDataSection(),
            SizedBox(height: 24),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Icon(
              Icons.person,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(height: 12),
          Text(
            _name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            _email,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: OutlinedButton.icon(
                icon: Icon(Icons.photo_camera),
                label: Text('Change Photo'),
                onPressed: () {
                  // Implement photo change functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Photo change feature not implemented yet')),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Personal Information'),
        SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildInfoField(
                  label: 'Name',
                  value: _name,
                  controller: _nameController,
                  isEditing: _isEditing,
                  icon: Icons.person,
                ),
                Divider(height: 24),
                _buildInfoField(
                  label: 'Email',
                  value: _email,
                  controller: _emailController,
                  isEditing: _isEditing,
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                Divider(height: 24),
                _buildInfoField(
                  label: 'Phone Number',
                  value: _phoneNumber,
                  controller: _phoneController,
                  isEditing: _isEditing,
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Preferences'),
        SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.attach_money),
                title: Text('Currency'),
                subtitle: Text(_currency),
                trailing: _isEditing ? Icon(Icons.chevron_right) : null,
                onTap: _isEditing ? () => _showCurrencyPicker() : null,
              ),
              ListTile(
                leading: Icon(Icons.notifications),
                title: Text('Notification Settings'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  // Navigate to notification settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Notification settings not implemented yet')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Data Management'),
        SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.download),
                title: Text('Export Account Data'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(context, '/export');
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text(
                  'Delete Account',
                  style: TextStyle(color: Colors.red),
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.red),
                onTap: () => _showDeleteAccountDialog(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton(
      onPressed: () {
        // Implement logout functionality
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      },
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50),
        backgroundColor: Colors.red,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.logout),
          SizedBox(width: 8),
          Text(
            'Log Out',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required String value,
    required TextEditingController controller,
    required bool isEditing,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.grey[600]),
        SizedBox(width: 16),
        Expanded(
          child: isEditing
              ? TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: label,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: keyboardType,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _saveChanges() {
    setState(() {
      _name = _nameController.text;
      _email = _emailController.text;
      _phoneNumber = _phoneController.text;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile updated successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showCurrencyPicker() {
    final currencies = [
      'MYR (RM)',
      'USD (\$)',
      'EUR (€)',
      'GBP (£)',
      'JPY (¥)',
      'SGD (S\$)',
    ];
    
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Select Currency'),
        children: currencies.map((currency) {
          return SimpleDialogOption(
            onPressed: () {
              setState(() {
                _currency = currency;
              });
              Navigator.pop(context);
            },
            child: Text(currency),
          );
        }).toList(),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account'),
        content: Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement account deletion
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Delete Account'),
          ),
        ],
      ),
    );
  }
}