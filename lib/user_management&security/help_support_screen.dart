import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // For animations

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFAQSection(context),
            const SizedBox(height: 20),
            _buildContactSupport(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequently Asked Questions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge!.color,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            title: const Text('How do I set a budget?'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'To set a budget, go to the Budget tab, tap "Add Budget," and enter your monthly pocket money limit. You can categorize expenses like food, entertainment, etc.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            title: const Text('How do I track my expenses?'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Navigate to the Transactions tab, tap "Add Expense," and input details like amount, category, and date. Your expenses will be tracked automatically.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactSupport(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Support',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge!.color,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.email, color: Colors.blue),
                title: const Text('Email Support'),
                subtitle: const Text('support@clarityfinance.com'),
                onTap: () {
                  _launchEmailApp(context);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _launchEmailApp(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@clarityfinance.com',
      queryParameters: {
        'subject': 'Clarity Finance Support Request',
        'body': 'Please describe your issue here...',
      },
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No email app found to handle the request')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open email: ${e.toString()}')),
      );
    }
  }

}