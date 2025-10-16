/// Advanced avatar widget with initials, shapes, and animations
library;
import 'package:flutter/material.dart';

/// Avatar size presets
enum AvatarSize {
  small(32.0),
  medium(48.0),
  large(64.0),
  xlarge(96.0),
  custom(0.0);
  
  const AvatarSize(this.size);
  final double size;
}

/// Avatar shape options
enum AvatarShape {
  circle,
  roundedSquare,
  square,
}

/// Gradient type options for avatar backgrounds
enum GradientType {
  linear,
  radial,
  none,
}

/// Avatar widget that generates initials-based avatars with customizable styling
class AvatarWidget extends StatefulWidget {
  final String? imageUrl;
  final String name;
  final String? userId;
  final AvatarSize avatarSize;
  final double? customSize;
  final AvatarShape shape;
  final Color? backgroundColor;
  final List<Color>? gradientColors;
  final GradientType gradientType;
  final TextStyle? textStyle;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;
  final double? borderWidth;
  final List<BoxShadow>? shadows;
  final bool enableAnimation;
  final Duration animationDuration;
  final Widget? placeholder;
  final bool showShimmer;
  
  const AvatarWidget({
    super.key,
    this.imageUrl,
    required this.name,
    this.userId,
    this.avatarSize = AvatarSize.medium,
    this.customSize,
    this.shape = AvatarShape.circle,
    this.backgroundColor,
    this.gradientColors,
    this.gradientType = GradientType.linear,
    this.textStyle,
    this.onTap,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth,
    this.shadows,
    this.enableAnimation = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.placeholder,
    this.showShimmer = true,
  });
  
  @override
  State<AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<AvatarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _showImage = false;
  bool _imageError = false;
  
  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _checkImageAvailability();
  }
  
  void _setupAnimation() {
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }
  
  void _checkImageAvailability() {
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      setState(() {
        _showImage = true;
      });
    }
  }
  
  @override
  void didUpdateWidget(AvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.imageUrl != widget.imageUrl) {
      _checkImageAvailability();
      if (widget.enableAnimation) {
        _animationController.forward();
      }
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  double get _size {
    return widget.customSize ?? widget.avatarSize.size;
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: _size,
        height: _size,
        decoration: _buildContainerDecoration(),
        child: ClipPath(
          clipper: _getClipper(),
          child: widget.enableAnimation
              ? AnimatedSwitcher(
                  duration: widget.animationDuration,
                  child: _buildContent(),
                )
              : _buildContent(),
        ),
      ),
    );
  }
  
  BoxDecoration _buildContainerDecoration() {
    return BoxDecoration(
      border: widget.showBorder
          ? Border.all(
              color: widget.borderColor ?? Colors.white,
              width: widget.borderWidth ?? 2.0,
            )
          : null,
      borderRadius: _getBorderRadius(),
      boxShadow: widget.shadows ?? [
        if (widget.showBorder)
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
      ],
    );
  }
  
  BorderRadius? _getBorderRadius() {
    switch (widget.shape) {
      case AvatarShape.circle:
        return BorderRadius.circular(_size / 2);
      case AvatarShape.roundedSquare:
        return BorderRadius.circular(_size * 0.15);
      case AvatarShape.square:
        return BorderRadius.zero;
    }
  }
  
  CustomClipper<Path>? _getClipper() {
    switch (widget.shape) {
      case AvatarShape.circle:
        return _CircleClipper();
      case AvatarShape.roundedSquare:
        return _RoundedSquareClipper(_size * 0.15);
      case AvatarShape.square:
        return null;
    }
  }
  
  Widget _buildContent() {
    if (_showImage && !_imageError && widget.imageUrl != null) {
      return _buildImageContent();
    }
    
    return _buildInitialsContent();
  }
  
  Widget _buildImageContent() {
    return Image.network(
      widget.imageUrl!,
      fit: BoxFit.cover,
      width: _size,
      height: _size,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          if (widget.enableAnimation) {
            _animationController.forward();
          }
          return FadeTransition(
            opacity: _fadeAnimation,
            child: child,
          );
        }
        
        return widget.showShimmer
            ? _buildShimmerPlaceholder()
            : _buildLoadingPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _imageError = true;
            _showImage = false;
          });
        });
        
        return _buildInitialsContent();
      },
    );
  }
  
  Widget _buildInitialsContent() {
    final initials = _getInitials();
    final backgroundColor = _getBackgroundColor();
    
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: widget.gradientType == GradientType.none ? backgroundColor : null,
        gradient: _buildGradient(backgroundColor),
      ),
      child: Center(
        child: Text(
          initials,
          style: _getTextStyle(),
        ),
      ),
    );
  }
  
  Widget _buildShimmerPlaceholder() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey[300]!,
            Colors.grey[100]!,
            Colors.grey[300]!,
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
  
  Widget _buildLoadingPlaceholder() {
    return Container(
      width: _size,
      height: _size,
      color: Colors.grey[200],
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: _size * 0.05,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }
  
  String _getInitials() {
    if (widget.name.isEmpty) return '?';
    
    final words = widget.name.trim().split(' ').where((word) => word.isNotEmpty);
    
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      final word = words.first;
      return word.length == 1 ? word.toUpperCase() : word.substring(0, 2).toUpperCase();
    }
    
    // Take first letter of first two words
    return words.take(2).map((word) => word[0].toUpperCase()).join('');
  }
  
  Color _getBackgroundColor() {
    if (widget.backgroundColor != null) {
      return widget.backgroundColor!;
    }
    
    // Generate consistent color based on name or userId
    final seed = widget.userId ?? widget.name;
    return _generateColorFromSeed(seed);
  }
  
  Color _generateColorFromSeed(String seed) {
    // Material Design color palette
    final colors = [
      const Color(0xFF1976D2), // Blue
      const Color(0xFF388E3C), // Green
      const Color(0xFFE64A19), // Deep Orange
      const Color(0xFF7B1FA2), // Purple
      const Color(0xFFD32F2F), // Red
      const Color(0xFF0097A7), // Cyan
      const Color(0xFF5D4037), // Brown
      const Color(0xFF455A64), // Blue Grey
      const Color(0xFF00796B), // Teal
      const Color(0xFF689F38), // Light Green
      const Color(0xFFAF52DE), // System Purple
      const Color(0xFFFF6F00), // Orange
      const Color(0xFF8BC34A), // Light Green Alt
      const Color(0xFF3F51B5), // Indigo
      const Color(0xFF795548), // Brown Alt
      const Color(0xFF607D8B), // Blue Grey Alt
    ];
    
    // Create hash from seed
    int hash = seed.hashCode;
    if (hash < 0) hash = -hash;
    
    return colors[hash % colors.length];
  }
  
  Gradient? _buildGradient(Color baseColor) {
    if (widget.gradientType == GradientType.none) return null;
    
    List<Color> colors;
    
    if (widget.gradientColors != null) {
      colors = widget.gradientColors!;
    } else {
      // Create gradient variants of base color
      colors = [
        baseColor,
        _lightenColor(baseColor, 0.2),
        baseColor,
      ];
    }
    
    switch (widget.gradientType) {
      case GradientType.linear:
        return LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case GradientType.radial:
        return RadialGradient(
          colors: colors,
          center: Alignment.center,
          radius: 0.8,
        );
      case GradientType.none:
        return null;
    }
  }
  
  Color _lightenColor(Color color, double amount) {
    return Color.lerp(color, Colors.white, amount) ?? color;
  }
  
  TextStyle _getTextStyle() {
    if (widget.textStyle != null) return widget.textStyle!;
    
    final fontSize = _calculateFontSize();
    
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      letterSpacing: 0.5,
    );
  }
  
  double _calculateFontSize() {
    // Dynamic font size based on avatar size
    final baseFontSize = _size * 0.35;
    
    // Adjust based on initials length
    final initials = _getInitials();
    if (initials.length > 2) {
      return baseFontSize * 0.8;
    }
    if (initials.length == 1) {
      return baseFontSize * 1.2;
    }
    
    return baseFontSize;
  }
}

/// Custom clipper for circular avatars
class _CircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.addOval(Rect.fromLTWH(0, 0, size.width, size.height));
    return path;
  }
  
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Custom clipper for rounded square avatars
class _RoundedSquareClipper extends CustomClipper<Path> {
  final double borderRadius;
  
  _RoundedSquareClipper(this.borderRadius);
  
  @override
  Path getClip(Size size) {
    final path = Path();
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ),
    );
    return path;
  }
  
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return oldClipper is! _RoundedSquareClipper ||
        oldClipper.borderRadius != borderRadius;
  }
}

/// Extension methods for AvatarWidget presets
extension AvatarWidgetPresets on AvatarWidget {
  /// Small avatar with minimal styling
  static AvatarWidget small({
    String? imageUrl,
    required String name,
    String? userId,
    AvatarShape shape = AvatarShape.circle,
    VoidCallback? onTap,
  }) {
    return AvatarWidget(
      imageUrl: imageUrl,
      name: name,
      userId: userId,
      avatarSize: AvatarSize.small,
      shape: shape,
      onTap: onTap,
      enableAnimation: false,
      showShimmer: false,
    );
  }
  
  /// Medium avatar with standard styling
  static AvatarWidget medium({
    String? imageUrl,
    required String name,
    String? userId,
    AvatarShape shape = AvatarShape.circle,
    bool showBorder = false,
    VoidCallback? onTap,
  }) {
    return AvatarWidget(
      imageUrl: imageUrl,
      name: name,
      userId: userId,
      avatarSize: AvatarSize.medium,
      shape: shape,
      showBorder: showBorder,
      onTap: onTap,
    );
  }
  
  /// Large avatar with enhanced styling
  static AvatarWidget large({
    String? imageUrl,
    required String name,
    String? userId,
    AvatarShape shape = AvatarShape.circle,
    bool showBorder = true,
    GradientType gradientType = GradientType.linear,
    VoidCallback? onTap,
  }) {
    return AvatarWidget(
      imageUrl: imageUrl,
      name: name,
      userId: userId,
      avatarSize: AvatarSize.large,
      shape: shape,
      showBorder: showBorder,
      gradientType: gradientType,
      onTap: onTap,
      shadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
  
  /// Extra large avatar with premium styling
  static AvatarWidget xlarge({
    String? imageUrl,
    required String name,
    String? userId,
    AvatarShape shape = AvatarShape.circle,
    GradientType gradientType = GradientType.radial,
    VoidCallback? onTap,
  }) {
    return AvatarWidget(
      imageUrl: imageUrl,
      name: name,
      userId: userId,
      avatarSize: AvatarSize.xlarge,
      shape: shape,
      showBorder: true,
      borderWidth: 3.0,
      gradientType: gradientType,
      onTap: onTap,
      shadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
  
  /// Notification avatar (small with badge support)
  static Widget notification({
    String? imageUrl,
    required String name,
    String? userId,
    int? badgeCount,
    Color badgeColor = Colors.red,
  }) {
    return Stack(
      children: [
        AvatarWidgetPresets.small(
          imageUrl: imageUrl,
          name: name,
          userId: userId,
        ),
        if (badgeCount != null && badgeCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                badgeCount > 99 ? '99+' : badgeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
  
  /// Group avatar with multiple overlapping avatars
  static Widget group({
    required List<String> names,
    List<String>? imageUrls,
    List<String>? userIds,
    AvatarSize size = AvatarSize.medium,
    int maxVisible = 3,
  }) {
    final visibleCount = names.length > maxVisible ? maxVisible - 1 : names.length;
    final remainingCount = names.length - visibleCount;
    final avatarSize = size.size * 0.8; // Slightly smaller for overlap
    
    return SizedBox(
      width: avatarSize + (visibleCount - 1) * (avatarSize * 0.3),
      height: avatarSize,
      child: Stack(
        children: [
          // Individual avatars
          for (int i = 0; i < visibleCount; i++)
            Positioned(
              left: i * (avatarSize * 0.3),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: AvatarWidget(
                  imageUrl: imageUrls?.elementAtOrNull(i),
                  name: names[i],
                  userId: userIds?.elementAtOrNull(i),
                  customSize: avatarSize,
                  enableAnimation: false,
                ),
              ),
            ),
          
          // Remaining count indicator
          if (remainingCount > 0)
            Positioned(
              left: visibleCount * (avatarSize * 0.3),
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[600],
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '+$remainingCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: avatarSize * 0.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
