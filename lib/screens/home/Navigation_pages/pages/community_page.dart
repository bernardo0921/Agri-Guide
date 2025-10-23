import 'package:flutter/material.dart';

class CommunityPageContent extends StatelessWidget {
  const CommunityPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Community',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: Center(
        child: Text(
          'Community Page',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
