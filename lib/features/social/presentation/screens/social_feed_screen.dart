import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../../utils/constants/route_constants.dart';

/// Main social feed screen
class SocialFeedScreen extends ConsumerStatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  ConsumerState<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends ConsumerState<SocialFeedScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Social'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              context.push(RoutePaths.socialSearch);
            },
            icon: const Icon(LucideIcons.search),
          ),
          IconButton(
            onPressed: () {
              context.push(RoutePaths.socialNotifications);
            },
            icon: const Icon(LucideIcons.bell),
          ),
          IconButton(
            onPressed: () {
              context.push(RoutePaths.socialCreatePost);
            },
            icon: const Icon(LucideIcons.plus),
          ),
        ],
      ),
      body: const CustomScrollView(
        slivers: [
          // Social widgets will be implemented here
          SliverToBoxAdapter(child: SizedBox(height: 16)),
          // Stories/highlights section
          SliverToBoxAdapter(child: _StoriesSection()),
          SliverToBoxAdapter(child: SizedBox(height: 16)),
          // Quick actions (friend suggestions, etc.)
          SliverToBoxAdapter(child: _QuickActionsSection()),
          SliverToBoxAdapter(child: SizedBox(height: 16)),
          // Posts feed
          SliverToBoxAdapter(child: _PostsFeedSection()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(RoutePaths.socialCreatePost);
        },
        child: const Icon(LucideIcons.plus),
      ),
    );
  }
}

class _StoriesSection extends StatelessWidget {
  const _StoriesSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Center(
        child: Text(
          'Stories section - To be implemented',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Center(
        child: Text(
          'Friend suggestions and quick actions - To be implemented',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}

class _PostsFeedSection extends StatelessWidget {
  const _PostsFeedSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Center(
        child: Text(
          'Posts feed - To be implemented',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
