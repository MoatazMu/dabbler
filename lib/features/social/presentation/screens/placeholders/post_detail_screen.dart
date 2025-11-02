import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Post detail screen showing full post content, comments, and interactions
class PostDetailScreen extends StatelessWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          IconButton(icon: const Icon(LucideIcons.share), onPressed: () {}),
          IconButton(
            icon: const Icon(LucideIcons.moreHorizontal),
            onPressed: () {},
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Post Content
          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Author Info
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          child: Icon(LucideIcons.user),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'User Name',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '2 hours ago',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Post Content
                    Text(
                      'This is post content for post ID: $postId\n\nLorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),

                    // Post Image (placeholder)
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        LucideIcons.image,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Action Buttons
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.heart),
                          onPressed: () {},
                        ),
                        const Text('12'),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(LucideIcons.messageCircle),
                          onPressed: () {},
                        ),
                        const Text('5'),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(LucideIcons.share),
                          onPressed: () {},
                        ),
                        const Text('3'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Comments Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Comments',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Comments List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: const CircleAvatar(
                    radius: 16,
                    child: Icon(LucideIcons.user, size: 16),
                  ),
                  title: Text('Commenter ${index + 1}'),
                  subtitle: Text(
                    'This is a comment on the post. Comment ${index + 1}',
                  ),
                  trailing: Text(
                    '${index + 1}h',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ),
              ),
              childCount: 5,
            ),
          ),
        ],
      ),

      // Comment Input
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 8,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: Colors.grey[300]!, width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(LucideIcons.send), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
