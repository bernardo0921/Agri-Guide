import 'package:flutter/material.dart';
import '../../../../../models/post.dart';
import '../../../../../services/community_api_service.dart';
import '../../../../../widgets/post_card.dart';
import '../../../../../widgets/create_post_modal.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _postKeys = {};
  List<Post> _posts = [];
  List<Post> _filteredPosts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts({int? scrollToPostId}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final posts = await CommunityApiService.getPosts();
      setState(() {
        _posts = posts;
        _filteredPosts = posts;
        _isLoading = false;

        // Generate keys for each post
        _postKeys.clear();
        for (var post in posts) {
          _postKeys[post.id] = GlobalKey();
        }
      });

      // Scroll to the specific post after the widget tree is built and images have loaded
      if (scrollToPostId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Delay to allow images to start loading and establish proper heights
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _scrollToPost(scrollToPostId);
            }
          });
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  void _scrollToPost(int postId) {
    final key = _postKeys[postId];
    if (key != null && key.currentContext != null) {
      try {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.1, // Position post near the top of the screen
        );
      } catch (e) {
        // If scrolling fails, try again after a short delay
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && key.currentContext != null) {
            Scrollable.ensureVisible(
              key.currentContext!,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              alignment: 0.1,
            );
          }
        });
      }
    }
  }

  void _filterPosts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPosts = _posts;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredPosts = _posts.where((post) {
          return post.content.toLowerCase().contains(lowerQuery) ||
              post.authorName.toLowerCase().contains(lowerQuery) ||
              post.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
        }).toList();
      }
    });
  }

  Future<void> _toggleLike(Post post) async {
    try {
      await CommunityApiService.toggleLike(post.id);
      // Reload posts and scroll back to the liked post
      await _loadPosts(scrollToPostId: post.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update like: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  Future<void> _deletePost(Post post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await CommunityApiService.deletePost(post.id);
        await _loadPosts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete post: $e'),
              backgroundColor: Colors.red[700],
            ),
          );
        }
      }
    }
  }

  void _openCreatePostModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreatePostModal(
        onPostCreated: (Post newPost) {
          _loadPosts();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _buildErrorState()
                  : _filteredPosts.isEmpty
                  ? _buildEmptyState()
                  : _buildPostsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green[700],
        onPressed: _openCreatePostModal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Post',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterPosts,
        decoration: InputDecoration(
          hintText: 'Search posts, topics or farmers...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: Colors.green[700]),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _filterPosts('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPostsList() {
    return RefreshIndicator(
      onRefresh: () => _loadPosts(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 80, // Extra padding at bottom to clear the FAB
        ),
        itemCount: _filteredPosts.length,
        itemBuilder: (context, index) {
          final post = _filteredPosts[index];
          return Container(
            key: _postKeys[post.id],
            child: PostCard(
              post: post,
              onLike: () => _toggleLike(post),
              onDelete: () => _deletePost(post),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No posts found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Failed to load posts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _loadPosts(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
