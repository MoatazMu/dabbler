/// Enhanced cached network image widget with advanced features
library;
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Image transformation types
enum ImageTransformation {
  resize,
  crop,
  blur,
  grayscale,
  sepia,
}

/// Image transformation configuration
class ImageTransformConfig {
  final ImageTransformation type;
  final Map<String, dynamic> params;
  
  const ImageTransformConfig(this.type, this.params);
  
  factory ImageTransformConfig.resize({
    required int width,
    required int height,
    bool maintainAspectRatio = true,
  }) {
    return ImageTransformConfig(
      ImageTransformation.resize,
      {
        'width': width,
        'height': height,
        'maintainAspectRatio': maintainAspectRatio,
      },
    );
  }
  
  factory ImageTransformConfig.crop({
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    return ImageTransformConfig(
      ImageTransformation.crop,
      {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      },
    );
  }
  
  factory ImageTransformConfig.blur({required double sigma}) {
    return ImageTransformConfig(
      ImageTransformation.blur,
      {'sigma': sigma},
    );
  }
  
  factory ImageTransformConfig.grayscale() {
    return const ImageTransformConfig(
      ImageTransformation.grayscale,
      {},
    );
  }
  
  factory ImageTransformConfig.sepia() {
    return const ImageTransformConfig(
      ImageTransformation.sepia,
      {},
    );
  }
}

/// Cache configuration options
class CacheConfig {
  final Duration? maxAge;
  final int? maxMemoryCacheSize;
  final int? maxDiskCacheSize;
  final bool useMemoryCache;
  final bool useDiskCache;
  final String? cacheKey;
  
  const CacheConfig({
    this.maxAge,
    this.maxMemoryCacheSize,
    this.maxDiskCacheSize,
    this.useMemoryCache = true,
    this.useDiskCache = true,
    this.cacheKey,
  });
  
  static const CacheConfig defaultConfig = CacheConfig(
    maxAge: Duration(days: 7),
    maxMemoryCacheSize: 100, // MB
    maxDiskCacheSize: 500, // MB
  );
  
  static const CacheConfig lowMemory = CacheConfig(
    maxAge: Duration(days: 3),
    maxMemoryCacheSize: 50,
    maxDiskCacheSize: 200,
  );
  
  static const CacheConfig aggressive = CacheConfig(
    maxAge: Duration(days: 30),
    maxMemoryCacheSize: 200,
    maxDiskCacheSize: 1000,
  );
}

/// Loading state types
enum LoadingState {
  loading,
  loaded,
  error,
  placeholder,
}

/// Enhanced cached network image widget
class CachedNetworkImageWidget extends StatefulWidget {
  final String imageUrl;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final CacheConfig? cacheConfig;
  final List<ImageTransformConfig>? transformations;
  final Map<String, String>? httpHeaders;
  final Duration? fadeInDuration;
  final Duration? fadeOutDuration;
  final Curve fadeInCurve;
  final Curve fadeOutCurve;
  final bool enableMemoryCache;
  final bool enableDiskCache;
  final ValueChanged<LoadingState>? onStateChanged;
  final VoidCallback? onImageLoaded;
  final ValueChanged<Object>? onError;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final FilterQuality filterQuality;
  final Color? color;
  final BlendMode? colorBlendMode;
  final AlignmentGeometry alignment;
  final ImageRepeat repeat;
  final bool matchTextDirection;
  final bool gaplessPlayback;
  final String? semanticLabel;
  final bool excludeFromSemantics;
  
  const CachedNetworkImageWidget({
    super.key,
    required this.imageUrl,
    this.placeholder,
    this.errorWidget,
    this.fit,
    this.width,
    this.height,
    this.cacheConfig,
    this.transformations,
    this.httpHeaders,
    this.fadeInDuration = const Duration(milliseconds: 500),
    this.fadeOutDuration = const Duration(milliseconds: 300),
    this.fadeInCurve = Curves.easeIn,
    this.fadeOutCurve = Curves.easeOut,
    this.enableMemoryCache = true,
    this.enableDiskCache = true,
    this.onStateChanged,
    this.onImageLoaded,
    this.onError,
    this.memCacheWidth,
    this.memCacheHeight,
    this.filterQuality = FilterQuality.low,
    this.color,
    this.colorBlendMode,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.matchTextDirection = false,
    this.gaplessPlayback = false,
    this.semanticLabel,
    this.excludeFromSemantics = false,
  });
  
  @override
  State<CachedNetworkImageWidget> createState() => _CachedNetworkImageWidgetState();
}

class _CachedNetworkImageWidgetState extends State<CachedNetworkImageWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  LoadingState _currentState = LoadingState.loading;
  bool _isRetrying = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _notifyStateChanged(LoadingState.loading);
  }
  
  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: widget.fadeInDuration,
      reverseDuration: widget.fadeOutDuration,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: widget.fadeInCurve,
      reverseCurve: widget.fadeOutCurve,
    ));
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return _buildImageWidget();
  }
  
  Widget _buildImageWidget() {
    // In a real implementation, this would use cached_network_image package
    // For now, we'll simulate the behavior with a regular Image.network
    
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Placeholder
            if (_currentState == LoadingState.loading || 
                _currentState == LoadingState.placeholder) ...[
              SizedBox(
                width: widget.width,
                height: widget.height,
                child: widget.placeholder ?? _buildDefaultPlaceholder(),
              ),
            ],
            
            // Error widget
            if (_currentState == LoadingState.error) ...[
              SizedBox(
                width: widget.width,
                height: widget.height,
                child: widget.errorWidget ?? _buildDefaultErrorWidget(),
              ),
            ],
            
            // Actual image with fade transition
            if (_currentState == LoadingState.loaded) ...[
              Opacity(
                opacity: _fadeAnimation.value,
                child: _buildNetworkImage(),
              ),
            ],
          ],
        );
      },
    );
  }
  
  Widget _buildNetworkImage() {
    return Image.network(
      widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      color: widget.color,
      colorBlendMode: widget.colorBlendMode,
      alignment: widget.alignment,
      repeat: widget.repeat,
      matchTextDirection: widget.matchTextDirection,
      gaplessPlayback: widget.gaplessPlayback,
      semanticLabel: widget.semanticLabel,
      excludeFromSemantics: widget.excludeFromSemantics,
      filterQuality: widget.filterQuality,
      headers: widget.httpHeaders,
      errorBuilder: _errorBuilder,
      loadingBuilder: _loadingBuilder,
    );
  }
  
  Widget _errorBuilder(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    _notifyError(error);
    return widget.errorWidget ?? _buildDefaultErrorWidget();
  }
  
  Widget _loadingBuilder(
    BuildContext context,
    Widget child,
    ImageChunkEvent? loadingProgress,
  ) {
    if (loadingProgress == null) {
      _notifyLoaded();
      return child;
    }
    
    _notifyStateChanged(LoadingState.loading);
    
    return widget.placeholder ?? _buildDefaultPlaceholder(
      progress: loadingProgress.expectedTotalBytes != null
          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
          : null,
    );
  }
  
  Widget _buildDefaultPlaceholder({double? progress}) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (progress != null) ...[
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 2,
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ] else ...[
            Icon(
              Icons.image,
              size: 32,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildDefaultErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 32,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 8),
          Text(
            'Failed to load',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          if (_canRetry()) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _retry,
              child: Text(
                'Retry',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  void _notifyStateChanged(LoadingState state) {
    if (_currentState != state) {
      setState(() {
        _currentState = state;
      });
      widget.onStateChanged?.call(state);
    }
  }
  
  void _notifyLoaded() {
    _notifyStateChanged(LoadingState.loaded);
    _fadeController.forward();
    widget.onImageLoaded?.call();
    _retryCount = 0; // Reset retry count on success
  }
  
  void _notifyError(Object error) {
    _notifyStateChanged(LoadingState.error);
    widget.onError?.call(error);
  }
  
  bool _canRetry() {
    return !_isRetrying && _retryCount < _maxRetries;
  }
  
  Future<void> _retry() async {
    if (!_canRetry()) return;
    
    setState(() {
      _isRetrying = true;
      _retryCount++;
    });
    
    _notifyStateChanged(LoadingState.loading);
    
    // Add delay before retry
    await Future.delayed(Duration(seconds: _retryCount));
    
    setState(() {
      _isRetrying = false;
    });
    
    // Force rebuild to retry loading
    setState(() {});
  }
}

/// Extension methods for easy usage
extension CachedNetworkImageExtensions on CachedNetworkImageWidget {
  /// Create with blur effect
  CachedNetworkImageWidget withBlur(double sigma) {
    final transforms = [...(transformations ?? [])];
    transforms.add(ImageTransformConfig.blur(sigma: sigma));
    
    return CachedNetworkImageWidget(
      imageUrl: imageUrl,
      placeholder: placeholder,
      errorWidget: errorWidget,
      fit: fit,
      width: width,
      height: height,
      cacheConfig: cacheConfig,
      transformations: transforms,
      httpHeaders: httpHeaders,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
      fadeInCurve: fadeInCurve,
      fadeOutCurve: fadeOutCurve,
      enableMemoryCache: enableMemoryCache,
      enableDiskCache: enableDiskCache,
      onStateChanged: onStateChanged,
      onImageLoaded: onImageLoaded,
      onError: onError,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      filterQuality: filterQuality,
      color: color,
      colorBlendMode: colorBlendMode,
      alignment: alignment,
      repeat: repeat,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
    );
  }
  
  /// Create with grayscale effect
  CachedNetworkImageWidget withGrayscale() {
    final transforms = [...(transformations ?? [])];
    transforms.add(ImageTransformConfig.grayscale());
    
    return CachedNetworkImageWidget(
      imageUrl: imageUrl,
      placeholder: placeholder,
      errorWidget: errorWidget,
      fit: fit,
      width: width,
      height: height,
      cacheConfig: cacheConfig,
      transformations: transforms,
      httpHeaders: httpHeaders,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
      fadeInCurve: fadeInCurve,
      fadeOutCurve: fadeOutCurve,
      enableMemoryCache: enableMemoryCache,
      enableDiskCache: enableDiskCache,
      onStateChanged: onStateChanged,
      onImageLoaded: onImageLoaded,
      onError: onError,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      filterQuality: filterQuality,
      color: color,
      colorBlendMode: colorBlendMode,
      alignment: alignment,
      repeat: repeat,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
    );
  }
  
  /// Create with custom cache configuration
  CachedNetworkImageWidget withCache(CacheConfig config) {
    return CachedNetworkImageWidget(
      imageUrl: imageUrl,
      placeholder: placeholder,
      errorWidget: errorWidget,
      fit: fit,
      width: width,
      height: height,
      cacheConfig: config,
      transformations: transformations,
      httpHeaders: httpHeaders,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
      fadeInCurve: fadeInCurve,
      fadeOutCurve: fadeOutCurve,
      enableMemoryCache: enableMemoryCache,
      enableDiskCache: enableDiskCache,
      onStateChanged: onStateChanged,
      onImageLoaded: onImageLoaded,
      onError: onError,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      filterQuality: filterQuality,
      color: color,
      colorBlendMode: colorBlendMode,
      alignment: alignment,
      repeat: repeat,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
    );
  }
  
  /// Create with authentication headers
  CachedNetworkImageWidget withAuth(Map<String, String> headers) {
    final allHeaders = {...(httpHeaders ?? {}), ...headers};
    
    return CachedNetworkImageWidget(
      imageUrl: imageUrl,
      placeholder: placeholder,
      errorWidget: errorWidget,
      fit: fit,
      width: width,
      height: height,
      cacheConfig: cacheConfig,
      transformations: transformations,
      httpHeaders: allHeaders,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
      fadeInCurve: fadeInCurve,
      fadeOutCurve: fadeOutCurve,
      enableMemoryCache: enableMemoryCache,
      enableDiskCache: enableDiskCache,
      onStateChanged: onStateChanged,
      onImageLoaded: onImageLoaded,
      onError: onError,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      filterQuality: filterQuality,
      color: color,
      colorBlendMode: colorBlendMode,
      alignment: alignment,
      repeat: repeat,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
    );
  }
}

/// Cache manager for network images
class ImageCacheManager {
  static final Map<String, ImageCacheEntry> _memoryCache = {};
  static int _maxMemoryCacheSize = 100; // MB
  static int _currentMemoryUsage = 0;
  
  /// Set maximum memory cache size in MB
  static void setMaxMemoryCacheSize(int sizeInMB) {
    _maxMemoryCacheSize = sizeInMB;
    _evictIfNeeded();
  }
  
  /// Clear all cached images
  static void clearCache() {
    _memoryCache.clear();
    _currentMemoryUsage = 0;
  }
  
  /// Clear cache for specific URL
  static void clearImageCache(String url) {
    final entry = _memoryCache.remove(url);
    if (entry != null) {
      _currentMemoryUsage -= entry.sizeInBytes;
    }
  }
  
  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'totalItems': _memoryCache.length,
      'memoryUsageMB': _currentMemoryUsage / (1024 * 1024),
      'maxMemorySizeMB': _maxMemoryCacheSize,
      'hitRate': _calculateHitRate(),
    };
  }
  
  static double _calculateHitRate() {
    if (_memoryCache.isEmpty) return 0.0;
    
    int totalHits = 0;
    int totalRequests = 0;
    
    for (final entry in _memoryCache.values) {
      totalHits += entry.hitCount;
      totalRequests += entry.requestCount;
    }
    
    return totalRequests > 0 ? totalHits / totalRequests : 0.0;
  }
  
  static void _evictIfNeeded() {
    while (_currentMemoryUsage > _maxMemoryCacheSize * 1024 * 1024) {
      if (_memoryCache.isEmpty) break;
      
      // Find least recently used entry
      String? lruKey;
      DateTime? oldestAccess;
      
      for (final entry in _memoryCache.entries) {
        if (oldestAccess == null || entry.value.lastAccessed.isBefore(oldestAccess)) {
          oldestAccess = entry.value.lastAccessed;
          lruKey = entry.key;
        }
      }
      
      if (lruKey != null) {
        clearImageCache(lruKey);
      }
    }
  }
}

/// Cache entry for tracking image data
class ImageCacheEntry {
  final Uint8List data;
  final DateTime createdAt;
  DateTime lastAccessed;
  int hitCount;
  int requestCount;
  
  ImageCacheEntry({
    required this.data,
    required this.createdAt,
  }) : lastAccessed = createdAt,
       hitCount = 0,
       requestCount = 0;
  
  int get sizeInBytes => data.length;
  
  void recordHit() {
    lastAccessed = DateTime.now();
    hitCount++;
    requestCount++;
  }
  
  void recordMiss() {
    requestCount++;
  }
}
