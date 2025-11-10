import 'package:flutter/material.dart';

// LMS Page Content
class LMSPageContent extends StatelessWidget {
  const LMSPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold and AppBar removed. Returning content directly.
    return Center(
      child: Text(
        'LMS Page',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}