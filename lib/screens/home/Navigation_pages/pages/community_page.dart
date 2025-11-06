import 'package:flutter/material.dart';

class CommunityPageContent extends StatelessWidget {
  const CommunityPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold and AppBar removed. Returning content directly.
    return Center(
      child: Text(
        'Community Page',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}