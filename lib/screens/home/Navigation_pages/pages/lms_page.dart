import 'package:flutter/material.dart';

// LMS Page Content
class LMSPageContent extends StatelessWidget {
  const LMSPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Learning Management',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: Center(
        child: Text(
          'LMS Page',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}