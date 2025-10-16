/// Enhanced profile image widget with comprehensive features
library;
import 'package:flutter/material.dart';

/// Profile image widget with full-screen view, status indicators, and customization
class ProfileImage extends StatefulWidget {
  final String? imageUrl;
  final String? heroTag;
  final double size;
  final bool showOnlineStatus;
  final bool isOnline;
  final bool showBadge;
  final Widget? badge;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final BoxBorder? border;
  final List<BoxShadow>? shadows;
  final bool enableFullScreen;
  final String? fallbackName;
  final bool showShimmer;
  final Color? backgroundColor;
  final bool enableHeroAnimation;
  
  const ProfileImage({
    super.key,
    this.imageUrl,
    this.heroTag,
    this.size = 80.0,
    this.showOnlineStatus = false,
    this.isOnline = false,
    this.showBadge = false,
    this.badge,
    this.onTap,
    this.padding,
    this.border,
    this.shadows,
    this.enableFullScreen = true,
    this.fallbackName,
    this.showShimmer = true,
    this.backgroundColor,
    this.enableHeroAnimation = true,
  });
  
  @override
  State<ProfileImage> createState() => _ProfileImageState();
}

class _ProfileImageState extends State<ProfileImage> 
    with SingleTickerProviderStateMixin {
  bool _imageError = false;
  bool _isLoading = false;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;
  
  @override
  void initState() {
    super.initState();
    _setupShimmerAnimation();
  }
  
  void _setupShimmerAnimation() {
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _shimmerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.showShimmer) {
      _shimmerController.repeat(reverse: true);
    }
  }
  
  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding,
      child: Stack(
        children: [
          _buildMainImage(),
          if (widget.showOnlineStatus) _buildOnlineStatusIndicator(),
          if (widget.showBadge && widget.badge != null) _buildBadgeOverlay(),
        ],
      ),
    );
  }
  
  Widget _buildMainImage() {
    final heroTag = widget.heroTag ?? 'profile_image_${widget.imageUrl ?? 'default'}';
    
    Widget imageWidget = GestureDetector(
      onTap: widget.onTap ?? (widget.enableFullScreen ? _openFullScreen : null),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.backgroundColor ?? Colors.grey[200],
          border: widget.border,
          boxShadow: widget.shadows ?? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.size / 2),
          child: _buildImageContent(),
        ),
      ),
    );
    
    if (widget.enableHeroAnimation) {
      return Hero(
        tag: heroTag,
        child: imageWidget,
      );
    }
    
    return imageWidget;
  }
  
  Widget _buildImageContent() {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty || _imageError) {
      return _buildPlaceholder();
    }
    
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_isLoading && widget.showShimmer) _buildShimmerEffect(),
        Image.network(
          widget.imageUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              setState(() {
                _isLoading = false;
                _shimmerController.stop();
              });
              return child;
            }
            
            if (!_isLoading) {
              setState(() {
                _isLoading = true;
              });
              if (widget.showShimmer) {
                _shimmerController.repeat(reverse: true);
              }
            }
            
            return _buildLoadingIndicator(loadingProgress);
          },
          errorBuilder: (context, error, stackTrace) {
            setState(() {
              _imageError = true;
              _isLoading = false;
              _shimmerController.stop();
            });
            return _buildErrorWidget();
          },
        ),
      ],
    );
  }
  
  Widget _buildPlaceholder() {
    if (widget.fallbackName != null && widget.fallbackName!.isNotEmpty) {
      return _buildInitialsAvatar();
    }
    
    return Container(
      color: Colors.grey[300],
      child: Icon(
        Icons.person,
        size: widget.size * 0.6,
        color: Colors.grey[600],
      ),
    );
  }
  
  Widget _buildInitialsAvatar() {
    final initials = _getInitials(widget.fallbackName!);
    final backgroundColor = _generateColorFromName(widget.fallbackName!);
    
    return Container(
      color: backgroundColor,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.size * 0.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
  
  Widget _buildShimmerEffect() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
              stops: [
                _shimmerAnimation.value - 0.3,
                _shimmerAnimation.value,
                _shimmerAnimation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildLoadingIndicator(ImageChunkEvent loadingProgress) {
    final progress = loadingProgress.expectedTotalBytes != null
        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
        : null;
    
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: progress != null
            ? CircularProgressIndicator(
                value: progress,
                strokeWidth: 2,
                backgroundColor: Colors.grey[300],
              )
            : const CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
  
  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: widget.size * 0.3,
            color: Colors.grey[600],
          ),
          SizedBox(height: widget.size * 0.05),
          GestureDetector(
            onTap: _retryImageLoad,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: widget.size * 0.1,
                vertical: widget.size * 0.05,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(widget.size * 0.05),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.size * 0.12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOnlineStatusIndicator() {
    return Positioned(
      right: widget.size * 0.05,
      bottom: widget.size * 0.05,
      child: Container(
        width: widget.size * 0.25,
        height: widget.size * 0.25,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isOnline ? Colors.green : Colors.grey,
          border: Border.all(
            color: Colors.white,
            width: widget.size * 0.02,
          ),
        ),
        child: widget.isOnline
            ? Icon(
                Icons.circle,
                size: widget.size * 0.15,
                color: Colors.green,
              )
            : null,
      ),
    );
  }
  
  Widget _buildBadgeOverlay() {
    return Positioned(
      right: 0,
      top: 0,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: widget.badge!,
      ),
    );
  }
  
  void _retryImageLoad() {
    setState(() {
      _imageError = false;
      _isLoading = true;
    });
  }
  
  void _openFullScreen() {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) return;
    
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.8),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullScreenImageViewer(
            imageUrl: widget.imageUrl!,
            heroTag: widget.heroTag ?? 'profile_image_${widget.imageUrl}',
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
  
  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0].isNotEmpty ? words[0][0].toUpperCase() : '';
    } else if (words.length >= 2) {
      return '${words[0][0].toUpperCase()}${words[1][0].toUpperCase()}';
    }
    return '';
  }
  
  Color _generateColorFromName(String name) {
    final colors = [
      const Color(0xFF2196F3), // Blue
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF9800), // Orange
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFF44336), // Red
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFF795548), // Brown
      const Color(0xFF607D8B), // Blue Grey
    ];
    
    int hash = name.hashCode;
    return colors[hash.abs() % colors.length];
  }
}

/// Full screen image viewer with hero animation
class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String heroTag;
  
  const _FullScreenImageViewer({
    required this.imageUrl,
    required this.heroTag,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: Hero(
            tag: heroTag,
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      
                      return Container(
                        width: 200,
                        height: 200,
                        color: Colors.grey[800],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 200,
                        height: 200,
                        color: Colors.grey[800],
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 48,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Extension methods for ProfileImage presets
extension ProfileImagePresets on ProfileImage {
  /// Small profile image (40px)
  static ProfileImage small({
    String? imageUrl,
    String? heroTag,
    String? fallbackName,
    bool showOnlineStatus = false,
    bool isOnline = false,
    VoidCallback? onTap,
  }) {
    return ProfileImage(
      imageUrl: imageUrl,
      heroTag: heroTag,
      size: 40.0,
      fallbackName: fallbackName,
      showOnlineStatus: showOnlineStatus,
      isOnline: isOnline,
      onTap: onTap,
      shadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }
  
  /// Medium profile image (60px)
  static ProfileImage medium({
    String? imageUrl,
    String? heroTag,
    String? fallbackName,
    bool showOnlineStatus = false,
    bool isOnline = false,
    Widget? badge,
    VoidCallback? onTap,
  }) {
    return ProfileImage(
      imageUrl: imageUrl,
      heroTag: heroTag,
      size: 60.0,
      fallbackName: fallbackName,
      showOnlineStatus: showOnlineStatus,
      isOnline: isOnline,
      showBadge: badge != null,
      badge: badge,
      onTap: onTap,
    );
  }
  
  /// Large profile image (100px)
  static ProfileImage large({
    String? imageUrl,
    String? heroTag,
    String? fallbackName,
    bool showOnlineStatus = true,
    bool isOnline = false,
    Widget? badge,
    VoidCallback? onTap,
    BoxBorder? border,
  }) {
    return ProfileImage(
      imageUrl: imageUrl,
      heroTag: heroTag,
      size: 100.0,
      fallbackName: fallbackName,
      showOnlineStatus: showOnlineStatus,
      isOnline: isOnline,
      showBadge: badge != null,
      badge: badge,
      onTap: onTap,
      border: border ?? Border.all(
        color: Colors.white,
        width: 3,
      ),
    );
  }
  
  /// Extra large profile image (150px)
  static ProfileImage xlarge({
    String? imageUrl,
    String? heroTag,
    String? fallbackName,
    bool showOnlineStatus = true,
    bool isOnline = false,
    Widget? badge,
    VoidCallback? onTap,
  }) {
    return ProfileImage(
      imageUrl: imageUrl,
      heroTag: heroTag,
      size: 150.0,
      fallbackName: fallbackName,
      showOnlineStatus: showOnlineStatus,
      isOnline: isOnline,
      showBadge: badge != null,
      badge: badge,
      onTap: onTap,
      border: Border.all(
        color: Colors.white,
        width: 4,
      ),
      shadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
