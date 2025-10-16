/// Image upload field with drag-and-drop support and advanced features
library;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Upload status for individual images
enum UploadStatus {
  pending,
  uploading,
  completed,
  failed,
  cancelled,
}

/// Image data with upload information
class ImageUploadData {
  final String id;
  final File? file;
  final Uint8List? bytes;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final String? url;
  final UploadStatus status;
  final double progress;
  final String? error;
  final Map<String, dynamic>? metadata;
  
  const ImageUploadData({
    required this.id,
    this.file,
    this.bytes,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.url,
    this.status = UploadStatus.pending,
    this.progress = 0.0,
    this.error,
    this.metadata,
  });
  
  ImageUploadData copyWith({
    String? id,
    File? file,
    Uint8List? bytes,
    String? fileName,
    int? fileSize,
    String? mimeType,
    String? url,
    UploadStatus? status,
    double? progress,
    String? error,
    Map<String, dynamic>? metadata,
  }) {
    return ImageUploadData(
      id: id ?? this.id,
      file: file ?? this.file,
      bytes: bytes ?? this.bytes,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      url: url ?? this.url,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      metadata: metadata ?? this.metadata,
    );
  }
  
  String get formattedSize {
    if (fileSize == null) return 'Unknown size';
    
    final size = fileSize!;
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
  
  bool get isImage => mimeType?.startsWith('image/') ?? false;
  bool get isUploading => status == UploadStatus.uploading;
  bool get hasError => status == UploadStatus.failed;
  bool get isCompleted => status == UploadStatus.completed;
}

/// Compression configuration
class CompressionConfig {
  final int maxWidth;
  final int maxHeight;
  final int quality; // 0-100
  final bool maintainAspectRatio;
  final String outputFormat; // 'jpeg', 'png', 'webp'
  
  const CompressionConfig({
    this.maxWidth = 1920,
    this.maxHeight = 1080,
    this.quality = 80,
    this.maintainAspectRatio = true,
    this.outputFormat = 'jpeg',
  });
  
  static const CompressionConfig thumbnail = CompressionConfig(
    maxWidth: 300,
    maxHeight: 300,
    quality: 70,
    outputFormat: 'jpeg',
  );
  
  static const CompressionConfig medium = CompressionConfig(
    maxWidth: 800,
    maxHeight: 600,
    quality: 80,
    outputFormat: 'jpeg',
  );
  
  static const CompressionConfig high = CompressionConfig(
    maxWidth: 1920,
    maxHeight: 1080,
    quality: 90,
    outputFormat: 'jpeg',
  );
}

/// Upload validation configuration
class UploadValidation {
  final List<String> allowedFormats;
  final int maxFileSize; // in bytes
  final int maxImageCount;
  final int minImageCount;
  final Size? minImageSize;
  final Size? maxImageSize;
  
  const UploadValidation({
    this.allowedFormats = const ['jpeg', 'jpg', 'png', 'gif', 'webp'],
    this.maxFileSize = 10 * 1024 * 1024, // 10MB
    this.maxImageCount = 10,
    this.minImageCount = 0,
    this.minImageSize,
    this.maxImageSize,
  });
  
  String? validateFile(String fileName, int fileSize, String? mimeType) {
    // Check file size
    if (fileSize > maxFileSize) {
      final maxSizeMB = maxFileSize / (1024 * 1024);
      return 'File size must be less than ${maxSizeMB.toStringAsFixed(1)}MB';
    }
    
    // Check format
    final extension = fileName.toLowerCase().split('.').last;
    if (!allowedFormats.contains(extension)) {
      return 'Format not supported. Allowed: ${allowedFormats.join(', ')}';
    }
    
    return null;
  }
}

/// Image upload field with comprehensive features
class ImageUploadField extends StatefulWidget {
  final List<ImageUploadData> images;
  final ValueChanged<List<ImageUploadData>>? onImagesChanged;
  final Future<String> Function(ImageUploadData)? onUpload;
  final VoidCallback? onImageTap;
  final Function(ImageUploadData)? onImageRemove;
  final Function(List<ImageUploadData>)? onImagesReordered;
  final String? label;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final bool multiple;
  final bool reorderable;
  final bool enableDragDrop;
  final UploadValidation validation;
  final CompressionConfig? compressionConfig;
  final Widget? placeholder;
  final Widget? uploadingWidget;
  final Widget? errorWidget;
  final EdgeInsets padding;
  final double imageSize;
  final int gridCrossAxisCount;
  final double gridSpacing;
  final TextStyle? labelStyle;
  final bool showProgress;
  final bool showRetryButton;
  final Duration animationDuration;
  final bool enableHapticFeedback;
  final String uploadButtonText;
  final String dragDropText;
  final IconData? uploadIcon;
  
  const ImageUploadField({
    super.key,
    required this.images,
    this.onImagesChanged,
    this.onUpload,
    this.onImageTap,
    this.onImageRemove,
    this.onImagesReordered,
    this.label,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.multiple = true,
    this.reorderable = true,
    this.enableDragDrop = true,
    this.validation = const UploadValidation(),
    this.compressionConfig,
    this.placeholder,
    this.uploadingWidget,
    this.errorWidget,
    this.padding = const EdgeInsets.all(16),
    this.imageSize = 100.0,
    this.gridCrossAxisCount = 3,
    this.gridSpacing = 8.0,
    this.labelStyle,
    this.showProgress = true,
    this.showRetryButton = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.enableHapticFeedback = true,
    this.uploadButtonText = 'Add Images',
    this.dragDropText = 'Drag & drop images here or tap to select',
    this.uploadIcon = Icons.add_photo_alternate,
  });
  
  @override
  State<ImageUploadField> createState() => _ImageUploadFieldState();
}

class _ImageUploadFieldState extends State<ImageUploadField>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _dragController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _dragAnimation;
  
  bool _isDragOver = false;
  String? _validationError;
  List<ImageUploadData> _images = [];
  
  @override
  void initState() {
    super.initState();
    _images = List.from(widget.images);
    _setupAnimations();
  }
  
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _dragController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _dragAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _dragController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void didUpdateWidget(ImageUploadField oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.images != oldWidget.images) {
      _images = List.from(widget.images);
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _dragController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: widget.labelStyle ?? 
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 8),
          ],
          
          _buildUploadArea(),
          
          if (_images.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildImageGrid(),
          ],
          
          if (_validationError != null) ...[
            const SizedBox(height: 8),
            _buildErrorMessage(),
          ],
          
          if (widget.helperText != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.helperText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
          
          if (widget.errorText != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildUploadArea() {
    final canAddMore = _images.length < widget.validation.maxImageCount;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _dragAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _dragAnimation.value * _scaleAnimation.value,
          child: GestureDetector(
            onTap: widget.enabled && canAddMore ? _pickImages : null,
            child: DragTarget<List<File>>(
              onWillAcceptWithDetails: (details) => widget.enabled && widget.enableDragDrop && canAddMore,
              onAcceptWithDetails: (details) => _handleDroppedFiles(details.data),
              onMove: (_) => _handleDragEnter(),
              onLeave: (_) => _handleDragExit(),
              builder: (context, candidateData, rejectedData) {
                return Container(
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _isDragOver 
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300]!,
                      width: _isDragOver ? 2 : 1,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _isDragOver 
                        ? Theme.of(context).primaryColor.withOpacity(0.05)
                        : Colors.grey[50],
                  ),
                  child: _buildUploadContent(canAddMore),
                );
              },
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildUploadContent(bool canAddMore) {
    if (!canAddMore) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 32,
              color: Colors.green,
            ),
            const SizedBox(height: 8),
            Text(
              'Maximum ${widget.validation.maxImageCount} images reached',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.green[700],
              ),
            ),
          ],
        ),
      );
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.uploadIcon,
            size: 32,
            color: _isDragOver 
                ? Theme.of(context).primaryColor
                : Colors.grey[600],
          ),
          const SizedBox(height: 8),
          
          Text(
            _isDragOver 
                ? 'Drop images here'
                : (widget.enableDragDrop 
                    ? widget.dragDropText
                    : widget.uploadButtonText),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _isDragOver 
                  ? Theme.of(context).primaryColor
                  : Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          
          if (_images.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${_images.length}/${widget.validation.maxImageCount} images',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildImageGrid() {
    if (widget.reorderable) {
      return _buildReorderableGrid();
    } else {
      return _buildStaticGrid();
    }
  }
  
  Widget _buildStaticGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.gridCrossAxisCount,
        crossAxisSpacing: widget.gridSpacing,
        mainAxisSpacing: widget.gridSpacing,
        childAspectRatio: 1.0,
      ),
      itemCount: _images.length,
      itemBuilder: (context, index) => _buildImageItem(_images[index], index),
    );
  }
  
  Widget _buildReorderableGrid() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _images.length,
      onReorder: _reorderImages,
      itemBuilder: (context, index) {
        return _buildImageItem(_images[index], index, key: ValueKey(_images[index].id));
      },
    );
  }
  
  Widget _buildImageItem(ImageUploadData imageData, int index, {Key? key}) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          // Image preview
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: _buildImagePreview(imageData),
          ),
          
          // Status overlay
          if (imageData.isUploading || imageData.hasError)
            _buildStatusOverlay(imageData),
          
          // Remove button
          if (widget.enabled)
            Positioned(
              top: 4,
              right: 4,
              child: _buildRemoveButton(imageData),
            ),
          
          // Reorder handle
          if (widget.reorderable && widget.enabled)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.drag_handle,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildImagePreview(ImageUploadData imageData) {
    Widget imageWidget;
    
    if (imageData.file != null) {
      imageWidget = Image.file(
        imageData.file!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (imageData.bytes != null) {
      imageWidget = Image.memory(
        imageData.bytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (imageData.url != null) {
      imageWidget = Image.network(
        imageData.url!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildErrorPreview(),
      );
    } else {
      imageWidget = _buildErrorPreview();
    }
    
    return GestureDetector(
      onTap: widget.onImageTap,
      child: imageWidget,
    );
  }
  
  Widget _buildErrorPreview() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.broken_image,
          size: 32,
          color: Colors.grey,
        ),
      ),
    );
  }
  
  Widget _buildStatusOverlay(ImageUploadData imageData) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (imageData.isUploading) ...[
                CircularProgressIndicator(
                  value: widget.showProgress ? imageData.progress : null,
                  strokeWidth: 2,
                  backgroundColor: Colors.white30,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(imageData.progress * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else if (imageData.hasError) ...[
                const Icon(
                  Icons.error,
                  color: Colors.red,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  imageData.error ?? 'Upload failed',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                if (widget.showRetryButton) ...[
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _retryUpload(imageData),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(60, 24),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRemoveButton(ImageUploadData imageData) {
    return GestureDetector(
      onTap: () => _removeImage(imageData),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.close,
          size: 16,
          color: Colors.white,
        ),
      ),
    );
  }
  
  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_outlined,
            size: 16,
            color: Colors.red[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _validationError!,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _handleDragEnter() {
    setState(() {
      _isDragOver = true;
    });
    _dragController.forward();
  }
  
  void _handleDragExit() {
    setState(() {
      _isDragOver = false;
    });
    _dragController.reverse();
  }
  
  void _handleDroppedFiles(List<File> files) {
    _handleDragExit();
    _processFiles(files);
  }
  
  Future<void> _pickImages() async {
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    
    try {
      // This would use file_picker or image_picker package in real implementation
      // For now, simulate file selection
      /*
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: widget.multiple,
        allowCompression: widget.compressionConfig != null,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final files = result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();
        
        _processFiles(files);
      }
      */
      
      // Simulate file selection for demo
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
      
    } catch (e) {
      setState(() {
        _validationError = 'Failed to select images: ${e.toString()}';
      });
    }
  }
  
  void _processFiles(List<File> files) {
    final remainingSlots = widget.validation.maxImageCount - _images.length;
    final filesToProcess = files.take(remainingSlots).toList();
    
    for (final file in filesToProcess) {
      _validateAndAddImage(file);
    }
  }
  
  Future<void> _validateAndAddImage(File file) async {
    try {
      final fileName = file.path.split('/').last;
      final fileSize = await file.length();
      
      // Validate file
      final validationError = widget.validation.validateFile(
        fileName,
        fileSize,
        null, // Would get MIME type in real implementation
      );
      
      if (validationError != null) {
        setState(() {
          _validationError = validationError;
        });
        return;
      }
      
      // Create image data
      final imageData = ImageUploadData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        file: file,
        fileName: fileName,
        fileSize: fileSize,
        status: UploadStatus.pending,
      );
      
      setState(() {
        _images.add(imageData);
        _validationError = null;
      });
      
      // Start upload if callback provided
      if (widget.onUpload != null) {
        _startUpload(imageData);
      }
      
      widget.onImagesChanged?.call(_images);
      
    } catch (e) {
      setState(() {
        _validationError = 'Failed to process image: ${e.toString()}';
      });
    }
  }
  
  Future<void> _startUpload(ImageUploadData imageData) async {
    final index = _images.indexWhere((img) => img.id == imageData.id);
    if (index == -1) return;
    
    // Update status to uploading
    setState(() {
      _images[index] = imageData.copyWith(status: UploadStatus.uploading);
    });
    
    try {
      // Simulate upload progress
      for (double progress = 0.0; progress <= 1.0; progress += 0.1) {
        await Future.delayed(const Duration(milliseconds: 100));
        
        final currentIndex = _images.indexWhere((img) => img.id == imageData.id);
        if (currentIndex == -1) break; // Image was removed
        
        setState(() {
          _images[currentIndex] = _images[currentIndex].copyWith(progress: progress);
        });
      }
      
      // Call upload callback
      final url = await widget.onUpload!(imageData);
      
      final currentIndex = _images.indexWhere((img) => img.id == imageData.id);
      if (currentIndex != -1) {
        setState(() {
          _images[currentIndex] = _images[currentIndex].copyWith(
            status: UploadStatus.completed,
            url: url,
            progress: 1.0,
          );
        });
      }
      
    } catch (e) {
      final currentIndex = _images.indexWhere((img) => img.id == imageData.id);
      if (currentIndex != -1) {
        setState(() {
          _images[currentIndex] = _images[currentIndex].copyWith(
            status: UploadStatus.failed,
            error: e.toString(),
          );
        });
      }
    }
    
    widget.onImagesChanged?.call(_images);
  }
  
  void _removeImage(ImageUploadData imageData) {
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    
    setState(() {
      _images.removeWhere((img) => img.id == imageData.id);
      _validationError = null;
    });
    
    widget.onImageRemove?.call(imageData);
    widget.onImagesChanged?.call(_images);
  }
  
  void _retryUpload(ImageUploadData imageData) {
    if (widget.onUpload != null) {
      _startUpload(imageData.copyWith(
        status: UploadStatus.pending,
        progress: 0.0,
        error: null,
      ));
    }
  }
  
  void _reorderImages(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    
    setState(() {
      final item = _images.removeAt(oldIndex);
      _images.insert(newIndex, item);
    });
    
    widget.onImagesReordered?.call(_images);
    widget.onImagesChanged?.call(_images);
  }
}

/// Extension methods for easy ImageUploadField creation
extension ImageUploadFieldExtensions on ImageUploadField {
  /// Create a simple single image upload
  static ImageUploadField single({
    required List<ImageUploadData> images,
    required ValueChanged<List<ImageUploadData>> onChanged,
    String? label,
    Future<String> Function(ImageUploadData)? onUpload,
  }) {
    return ImageUploadField(
      images: images,
      onImagesChanged: onChanged,
      onUpload: onUpload,
      label: label,
      multiple: false,
      validation: const UploadValidation(maxImageCount: 1),
      gridCrossAxisCount: 1,
    );
  }
  
  /// Create a multiple image upload with gallery layout
  static ImageUploadField gallery({
    required List<ImageUploadData> images,
    required ValueChanged<List<ImageUploadData>> onChanged,
    String? label,
    int maxImages = 10,
    Future<String> Function(ImageUploadData)? onUpload,
  }) {
    return ImageUploadField(
      images: images,
      onImagesChanged: onChanged,
      onUpload: onUpload,
      label: label,
      multiple: true,
      reorderable: true,
      validation: UploadValidation(maxImageCount: maxImages),
      gridCrossAxisCount: 3,
      compressionConfig: CompressionConfig.medium,
    );
  }
  
  /// Create an avatar upload field
  static ImageUploadField avatar({
    required List<ImageUploadData> images,
    required ValueChanged<List<ImageUploadData>> onChanged,
    Future<String> Function(ImageUploadData)? onUpload,
  }) {
    return ImageUploadField(
      images: images,
      onImagesChanged: onChanged,
      onUpload: onUpload,
      label: 'Profile Picture',
      multiple: false,
      reorderable: false,
      validation: const UploadValidation(
        maxImageCount: 1,
        maxFileSize: 5 * 1024 * 1024, // 5MB
      ),
      compressionConfig: CompressionConfig.thumbnail,
      imageSize: 120,
      gridCrossAxisCount: 1,
    );
  }
}

/// Predefined upload configurations
class ImageUploadPresets {
  /// Profile picture upload
  static ImageUploadField profilePicture({
    required List<ImageUploadData> images,
    required ValueChanged<List<ImageUploadData>> onChanged,
    Future<String> Function(ImageUploadData)? onUpload,
  }) {
    return ImageUploadField(
      images: images,
      onImagesChanged: onChanged,
      onUpload: onUpload,
      label: 'Profile Picture',
      helperText: 'Upload a clear photo of yourself',
      multiple: false,
      validation: const UploadValidation(
        maxImageCount: 1,
        maxFileSize: 5 * 1024 * 1024,
        allowedFormats: ['jpeg', 'jpg', 'png'],
      ),
      compressionConfig: const CompressionConfig(
        maxWidth: 400,
        maxHeight: 400,
        quality: 85,
      ),
      uploadButtonText: 'Add Profile Picture',
      uploadIcon: Icons.account_circle,
    );
  }
  
  /// Sports activity photos
  static ImageUploadField activityPhotos({
    required List<ImageUploadData> images,
    required ValueChanged<List<ImageUploadData>> onChanged,
    Future<String> Function(ImageUploadData)? onUpload,
  }) {
    return ImageUploadField(
      images: images,
      onImagesChanged: onChanged,
      onUpload: onUpload,
      label: 'Activity Photos',
      helperText: 'Share photos from your sports activities',
      multiple: true,
      reorderable: true,
      validation: const UploadValidation(
        maxImageCount: 8,
        maxFileSize: 10 * 1024 * 1024,
      ),
      compressionConfig: CompressionConfig.medium,
      uploadButtonText: 'Add Photos',
      uploadIcon: Icons.photo_library,
    );
  }
  
  /// Facility/venue images
  static ImageUploadField facilityImages({
    required List<ImageUploadData> images,
    required ValueChanged<List<ImageUploadData>> onChanged,
    Future<String> Function(ImageUploadData)? onUpload,
  }) {
    return ImageUploadField(
      images: images,
      onImagesChanged: onChanged,
      onUpload: onUpload,
      label: 'Facility Images',
      helperText: 'Upload photos of courts, fields, or facilities',
      multiple: true,
      reorderable: true,
      validation: const UploadValidation(
        maxImageCount: 12,
        maxFileSize: 15 * 1024 * 1024,
      ),
      compressionConfig: CompressionConfig.high,
      gridCrossAxisCount: 2,
      uploadButtonText: 'Add Facility Photos',
      uploadIcon: Icons.location_on,
    );
  }
}
