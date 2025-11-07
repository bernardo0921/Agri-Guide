import 'package:flutter/material.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: const [
        PostCard(
          name: 'Adewale',
          role: 'Farmer',
          timeAgo: '2 hrs ago',
          title: 'My maize leaves are turning yellow, what could be wrong?',
          description:
              'I recently noticed that some of my maize leaves are turning yellow. Could it be a nutrient deficiency?',
          tags: ['Crops', 'Diseases'],
          imagePath: 'assets/image.jpeg',
          comments: 12,
          likes: 25,
        ),
        SizedBox(height: 10),
        PostCard(
          name: 'John',
          role: 'Farmer',
          timeAgo: '5 hrs ago',
          title: 'Great success with new tomato variety',
          description:
              'I planted a new tomato variety this season and the yield has been excellent.',
          tags: ['Crops', 'Market Prices'],
          imagePath: 'assets/image.jpeg',
          comments: 15,
          likes: 30,
        ),
      ],
    );
  }
}

class PostCard extends StatelessWidget {
  final String name;
  final String role;
  final String timeAgo;
  final String title;
  final String description;
  final List<String> tags;
  final String imagePath;
  final int comments;
  final int likes;

  const PostCard({
    super.key,
    required this.name,
    required this.role,
    required this.timeAgo,
    required this.title,
    required this.description,
    required this.tags,
    required this.imagePath,
    required this.comments,
    required this.likes,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile info
            Row(
              children: [
                const CircleAvatar(
                  backgroundImage: AssetImage('assets/profile.jpg'),
                  radius: 20,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('$role · $timeAgo',
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Post title and description
            Text(title,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(description,
                style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            const SizedBox(height: 8),

            // Post image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(imagePath, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),

            // Tags
            Wrap(
              spacing: 8,
              children: tags
                  .map((tag) => Chip(
                        label: Text(tag,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black)),
                        backgroundColor: Colors.grey[200],
                      ))
                  .toList(),
            ),

            // Likes and comments
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.comment_outlined, size: 16),
                const SizedBox(width: 4),
                Text('$comments'),
                const SizedBox(width: 12),
                const Icon(Icons.favorite_border, size: 16),
                const SizedBox(width: 4),
                Text('$likes'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
