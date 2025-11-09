import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dabbler/themes/app_theme.dart';
import 'package:dabbler/features/social/services/social_service.dart';
import 'package:dabbler/utils/enums/social_enums.dart';
import 'package:dabbler/features/authentication/presentation/providers/auth_providers.dart';

class AddPostScreen extends ConsumerStatefulWidget {
  const AddPostScreen({super.key});

  @override
  ConsumerState<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends ConsumerState<AddPostScreen> {
  final _textController = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.colors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Create Post',
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colors.onSurface,
          ),
        ),
        actions: [
          // Post button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              onPressed: (_canPost() && !_isPosting) ? _handlePost : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: context.colors.onPrimary,
                disabledBackgroundColor: context.colors.surfaceContainerHighest,
                disabledForegroundColor: context.colors.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: _isPosting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          context.colors.onPrimary,
                        ),
                      ),
                    )
                  : const Text(
                      'Post',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Avatar and Name
                  Row(
                    children: [
                      // User Avatar
                      Consumer(
                        builder: (context, ref, _) {
                          final authService = ref.watch(authServiceProvider);
                          final currentUser = authService.getCurrentUser();
                          final userAvatarUrl =
                              currentUser?.userMetadata?['avatar_url']
                                  as String?;

                          return CircleAvatar(
                            radius: 20,
                            backgroundColor: context.colors.primary.withOpacity(
                              0.2,
                            ),
                            backgroundImage:
                                userAvatarUrl != null &&
                                    userAvatarUrl.isNotEmpty
                                ? NetworkImage(userAvatarUrl)
                                : null,
                            child:
                                userAvatarUrl == null || userAvatarUrl.isEmpty
                                ? Icon(
                                    Icons.person,
                                    size: 20,
                                    color: context.colors.primary,
                                  )
                                : null,
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      // User Name
                      Consumer(
                        builder: (context, ref, _) {
                          final authService = ref.watch(authServiceProvider);
                          final currentUser = authService.getCurrentUser();
                          final userName =
                              currentUser?.userMetadata?['display_name']
                                  as String? ??
                              'User';

                          return Text(
                            userName,
                            style: TextStyle(
                              color: context.colors.onSurface,
                              fontFamily: 'Roboto',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Text Input
                  TextField(
                    controller: _textController,
                    maxLines: null,
                    minLines: 4,
                    style: const TextStyle(
                      color: Color(0xFFEBD7FA),
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.312,
                    ),
                    decoration: InputDecoration(
                      hintText: "What's on your mind?",
                      hintStyle: TextStyle(
                        color: const Color(0xFFEBD7FA).withOpacity(0.70),
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.312,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF301C4D),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(
                          color: const Color(0xFFEBD7FA).withOpacity(0.24),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(
                          color: const Color(0xFFEBD7FA).withOpacity(0.24),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(
                          color: const Color(0xFFEBD7FA).withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 24,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canPost() {
    return _textController.text.trim().isNotEmpty;
  }

  Future<void> _handlePost() async {
    if (!_canPost() || _isPosting) return;

    setState(() => _isPosting = true);

    try {
      final socialService = SocialService();

      // Create the post (text only for MVP)
      await socialService.createPost(
        content: _textController.text.trim(),
        mediaUrls: [], // No media in MVP
        locationName: null, // No location in MVP
        visibility: PostVisibility.public,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                const Text('Post shared successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate back to social feed
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        _showError('Failed to share post: ${e.toString()}');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
