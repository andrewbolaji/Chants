import 'package:flutter/material.dart';

class ContentPolicyScreen extends StatelessWidget {
  const ContentPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Content Policy')),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Content Policy',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'The full content policy will appear here before submissions '
              'go live. It covers what is and is not allowed on Chants.',
            ),
            SizedBox(height: 16),
            Text(
              'In short: no hate speech, no threats, no tragedy chanting, '
              'nothing that targets people for who they are. '
              'The detailed rules are coming soon.',
            ),
          ],
        ),
      ),
    );
  }
}
