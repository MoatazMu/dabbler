import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/profile_sharing_service.dart';

/// Comprehensive profile sharing widget with multiple sharing options
class ProfileSharingWidget extends ConsumerWidget {
  final String userId;
  final String userName;
  final String? userBio;
  final String? profileImageUrl;
  final List<String>? sports;
  final bool showQRCode;
  final bool showSocialShare;

  const ProfileSharingWidget({
    super.key,
    required this.userId,
    required this.userName,
    this.userBio,
    this.profileImageUrl,
    this.sports,
    this.showQRCode = true,
    this.showSocialShare = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Title
          Text(
            'Share Profile',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // User info
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: profileImageUrl != null 
                    ? NetworkImage(profileImageUrl!)
                    : null,
                child: profileImageUrl == null 
                    ? Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?')
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (userBio != null)
                      Text(
                        userBio!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Quick sharing options
          _buildQuickShareOptions(context),
          
          const SizedBox(height: 16),
          
          // QR Code section
          if (showQRCode) ...[
            _buildQRCodeSection(context),
            const SizedBox(height: 16),
          ],
          
          // Social media sharing
          if (showSocialShare) ...[
            _buildSocialMediaSection(context),
            const SizedBox(height: 16),
          ],
          
          // Close button
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickShareOptions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildShareOption(
            context,
            icon: Icons.copy,
            label: 'Copy Link',
            onTap: () => ProfileSharingService.copyProfileLink(
              context: context,
              userId: userId,
              userName: userName,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildShareOption(
            context,
            icon: Icons.share,
            label: 'Share',
            onTap: () => ProfileSharingService.shareProfile(
              userId: userId,
              userName: userName,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShareOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QR Code',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => ProfileSharingService.showQRCodeDialog(
            context: context,
            userId: userId,
            userName: userName,
          ),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.qr_code,
                    size: 24,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Tap to view QR code for easy sharing'),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialMediaSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share to Social Media',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSocialPlatformButton(
              context,
              platform: SocialPlatform.twitter,
            ),
            _buildSocialPlatformButton(
              context,
              platform: SocialPlatform.facebook,
            ),
            _buildSocialPlatformButton(
              context,
              platform: SocialPlatform.whatsapp,
            ),
            _buildSocialPlatformButton(
              context,
              platform: SocialPlatform.instagram,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialPlatformButton(
    BuildContext context, {
    required SocialPlatform platform,
  }) {
    return InkWell(
      onTap: () => ProfileSharingService.shareToSocialMedia(
        userId: userId,
        userName: userName,
        platform: platform,
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              platform.icon,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              platform.displayName[0].toUpperCase(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Show profile sharing bottom sheet
Future<void> showProfileSharingSheet({
  required BuildContext context,
  required String userId,
  required String userName,
  String? userBio,
  String? profileImageUrl,
  List<String>? sports,
  bool showQRCode = true,
  bool showSocialShare = true,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ProfileSharingWidget(
      userId: userId,
      userName: userName,
      userBio: userBio,
      profileImageUrl: profileImageUrl,
      sports: sports,
      showQRCode: showQRCode,
      showSocialShare: showSocialShare,
    ),
  );
}

/// Floating Action Button for profile sharing
class ProfileShareFAB extends StatelessWidget {
  final String userId;
  final String userName;
  final String? userBio;
  final String? profileImageUrl;
  final List<String>? sports;

  const ProfileShareFAB({
    super.key,
    required this.userId,
    required this.userName,
    this.userBio,
    this.profileImageUrl,
    this.sports,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => showProfileSharingSheet(
        context: context,
        userId: userId,
        userName: userName,
        userBio: userBio,
        profileImageUrl: profileImageUrl,
        sports: sports,
      ),
      child: const Icon(Icons.share),
    );
  }
}

/// App bar action for profile sharing
class ProfileShareAction extends StatelessWidget {
  final String userId;
  final String userName;
  final String? userBio;
  final String? profileImageUrl;
  final List<String>? sports;

  const ProfileShareAction({
    super.key,
    required this.userId,
    required this.userName,
    this.userBio,
    this.profileImageUrl,
    this.sports,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => showProfileSharingSheet(
        context: context,
        userId: userId,
        userName: userName,
        userBio: userBio,
        profileImageUrl: profileImageUrl,
        sports: sports,
      ),
      icon: const Icon(Icons.share),
      tooltip: 'Share Profile',
    );
  }
}
