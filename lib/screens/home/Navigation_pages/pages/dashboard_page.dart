import 'package:flutter/material.dart';

// Dashboard Page Content
class DashboardPageContent extends StatelessWidget {
  const DashboardPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: Text(
            'Dashboard',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              'Dashboard Page',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ],
    );
  }
}

