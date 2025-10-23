import 'package:flutter/material.dart';

// AI Advisory Page Content
class AIAdvisoryPageContent extends StatelessWidget {
  const AIAdvisoryPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AI Advisory',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: Center(
        child: Text(
          'AI Advisory Page',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}


