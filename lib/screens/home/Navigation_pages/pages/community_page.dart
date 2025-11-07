import 'package:flutter/material.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final List<Map<String, dynamic>> posts = [
    {
      'name': 'Adewale',
      'role': 'Farmer',
      'timeAgo': '2 hrs ago',
      'title': 'My maize leaves are turning yellow, what could be wrong?',
      'description':
          'I recently noticed that some of my maize leaves are turning yellow. Could it be a nutrient deficiency?',
      'tags': ['Crops', 'Diseases'],
      'imagePath': 'assets/images/tomato.jpeg',
      'comments': 12,
      'likes': 25,
    },
    {
      'name': 'John',
      'role': 'Farmer',
      'timeAgo': '5 hrs ago',
      'title': 'Great success with new tomato variety',
      'description':
          'I planted a new tomato variety this season and the yield has been excellent.',
      'tags': ['Crops', 'Market Prices'],
      'imagePath': 'assets/images/tomato.jpeg',
      'comments': 15,
      'likes': 30,
    },
  ];

  // Function to open the create post dialog
  void _openCreatePostModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final titleController = TextEditingController();
        final descriptionController = TextEditingController();

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Post',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Post title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    if (titleController.text.isNotEmpty &&
                        descriptionController.text.isNotEmpty) {
                      setState(() {
                        posts.insert(0, {
                          'name': 'You',
                          'role': 'Farmer',
                          'timeAgo': 'Just now',
                          'title': titleController.text,
                          'description': descriptionController.text,
                          'tags': ['General'],
                          'imagePath': 'assets/images/tomato.jpeg',
                          'comments': 0,
                          'likes': 0,
                        });
                      });
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.send, color: Colors.white),
                  label: const Text('Post',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // ======= Search Bar =======
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search posts, topics or farmers...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            // ======= Posts List =======
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return Column(
                    children: [
                      PostCard(
                        name: post['name'],
                        role: post['role'],
                        timeAgo: post['timeAgo'],
                        title: post['title'],
                        description: post['description'],
                        tags: List<String>.from(post['tags']),
                        imagePath: post['imagePath'],
                        comments: post['comments'],
                        likes: post['likes'],
                      ),
                      const SizedBox(height: 10),
                    ],
                  );
                },
              ),
            ),
          ],
        ),

        // ======= Floating Add Post Button =======
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            backgroundColor: Colors.green[700],
            onPressed: () => _openCreatePostModal(context),
            child: const Icon(Icons.add, color: Colors.white),
          ),
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
                CircleAvatar(
                  backgroundImage: AssetImage(imagePath),
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
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12)),
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
