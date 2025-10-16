import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Friends screen showing friend lists and management
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search),
            onPressed: () {
              // TODO: Search friends
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.userPlus),
            onPressed: () {
              // TODO: Add friend
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Friends'),
            Tab(text: 'Requests'),
            Tab(text: 'Suggestions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // All Friends Tab
          _buildFriendsList(),
          
          // Friend Requests Tab
          _buildFriendRequests(),
          
          // Friend Suggestions Tab
          _buildFriendSuggestions(),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 20,
      itemBuilder: (context, index) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey[200],
            child: Icon(
              LucideIcons.user,
              color: Colors.grey[600],
            ),
          ),
          title: Text('Friend ${index + 1}'),
          subtitle: Text('${100 + index} mutual friends'),
          trailing: PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(LucideIcons.user),
                    SizedBox(width: 8),
                    Text('View Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'message',
                child: Row(
                  children: [
                    Icon(LucideIcons.messageCircle),
                    SizedBox(width: 8),
                    Text('Send Message'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'unfriend',
                child: Row(
                  children: [
                    Icon(LucideIcons.userMinus, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Unfriend', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              // TODO: Handle friend actions
            },
          ),
          onTap: () {
            // TODO: View friend profile
          },
        ),
      ),
    );
  }

  Widget _buildFriendRequests() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey[200],
                child: Icon(
                  LucideIcons.user,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${10 + index} mutual friends',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: Accept friend request
                            },
                            child: const Text('Accept'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // TODO: Decline friend request
                            },
                            child: const Text('Decline'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendSuggestions() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey[200],
                child: Icon(
                  LucideIcons.user,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suggested User ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${5 + index} mutual friends',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Send friend request
                            },
                            icon: const Icon(LucideIcons.userPlus, size: 16),
                            label: const Text('Add Friend'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            // TODO: Remove suggestion
                          },
                          icon: const Icon(LucideIcons.x, size: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
