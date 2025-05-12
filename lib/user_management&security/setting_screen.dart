import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;

  const SettingsScreen({super.key, required this.onThemeChanged});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize _isDarkMode based on the current theme mode
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appearance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            _buildThemeToggle(),
            SizedBox(height: 20),
            Text(
              'Account',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            _buildAccountSettings(),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle() {
    return Card(
      elevation: 2,
      child: SwitchListTile(
        title: Text('Dark Mode'),
        subtitle: Text('Enable dark theme for better night-time viewing.'),
        value: _isDarkMode,
        onChanged: (value) {
          setState(() {
            _isDarkMode = value;
          });
          // Notify the parent widget about the theme change
          widget.onThemeChanged(value);
        },
      ),
    );
  }

  Widget _buildAccountSettings() {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Profile Management'),
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: Icon(Icons.lock),
            title: Text('Change Password'),
            onTap: () {
              Navigator.pushNamed(context, '/change_password');
            },
          ),
          ListTile(
            leading: Icon(Icons.help),
            title: Text('Help & Support'),
            onTap: () {
              Navigator.pushNamed(context, '/help_support');
            },
          ),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('About'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Clarity Finance',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025 THREE SMALL',
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text('A personal finance management app created for BAIT2073 Mobile Application Development.'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}