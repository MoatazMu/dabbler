/// Advanced image picker widget with crop, preview, and quality selection
library;
import 'dart:io';
import 'package:flutter/material.dart';

/// Image source options
enum ImageSource {
  camera,
  gallery,
}

/// Image quality presets
enum ImageQuality {
  low(30, 'Low (30%)'),
  medium(50, 'Medium (50%)'),
  high(70, 'High (70%)'),
  maximum(95, 'Maximum (95%)');
  
  const ImageQuality(this.value, this.label);
  final int value;
  final String label;
}

/// Aspect ratio presets for cropping
enum AspectRatioPreset {
  square(1.0, '1:1'),
  portrait(3.0/4.0, '3:4'),
  landscape(4.0/3.0, '4:3'),
  wide(16.0/9.0, '16:9');
  
  const AspectRatioPreset(this.ratio, this.label);
  final double ratio;
  final String label;
}

/// Result of image picker operation
class ImagePickerResult {
  final File? imageFile;
  final String? error;
  final bool wasCancelled;
  final Map<String, dynamic>? metadata;
  
  const ImagePickerResult({
    this.imageFile,
    this.error,
    this.wasCancelled = false,
    this.metadata,
  });
  
  bool get hasImage => imageFile != null;
  bool get hasError => error != null;
}

/// Advanced image picker widget with comprehensive features
class ImagePickerWidget extends StatefulWidget {
  final VoidCallback? onImageSelected;
  final Function(ImagePickerResult)? onResult;
  final bool enableCropping;
  final AspectRatioPreset? aspectRatio;
  final bool lockAspectRatio;
  final ImageQuality defaultQuality;
  final bool showQualitySelector;
  final int maxWidth;
  final int maxHeight;
  final String? title;
  final String? subtitle;
  final bool showPreview;
  final bool allowRemove;
  final File? currentImage;
  final Widget? customPreview;
  
  const ImagePickerWidget({
    super.key,
    this.onImageSelected,
    this.onResult,
    this.enableCropping = true,
    this.aspectRatio,
    this.lockAspectRatio = false,
    this.defaultQuality = ImageQuality.high,
    this.showQualitySelector = true,
    this.maxWidth = 1080,
    this.maxHeight = 1080,
    this.title = 'Select Image',
    this.subtitle,
    this.showPreview = true,
    this.allowRemove = true,
    this.currentImage,
    this.customPreview,
  });
  
  /// Show image picker as modal bottom sheet
  static Future<ImagePickerResult?> show(
    BuildContext context, {
    bool enableCropping = true,
    AspectRatioPreset? aspectRatio,
    bool lockAspectRatio = false,
    ImageQuality defaultQuality = ImageQuality.high,
    bool showQualitySelector = true,
    String? title = 'Select Image',
    String? subtitle,
    bool allowRemove = true,
    File? currentImage,
  }) async {
    return await showModalBottomSheet<ImagePickerResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ImagePickerWidget(
        enableCropping: enableCropping,
        aspectRatio: aspectRatio,
        lockAspectRatio: lockAspectRatio,
        defaultQuality: defaultQuality,
        showQualitySelector: showQualitySelector,
        title: title,
        subtitle: subtitle,
        allowRemove: allowRemove,
        currentImage: currentImage,
        onResult: (result) => Navigator.of(context).pop(result),
      ),
    );
  }
  
  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget>
    with TickerProviderStateMixin {
  File? _selectedImage;
  File? _processedImage;
  bool _isProcessing = false;
  double _processingProgress = 0.0;
  String? _errorMessage;
  ImageQuality _selectedQuality = ImageQuality.high;
  AspectRatioPreset? _selectedAspectRatio;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _selectedImage = widget.currentImage;
    _selectedQuality = widget.defaultQuality;
    _selectedAspectRatio = widget.aspectRatio;
    
    _setupAnimations();
  }
  
  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _slideController.forward();
    _fadeController.forward();
  }
  
  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            if (_selectedImage != null && widget.showPreview) ...[
              const Divider(height: 1),
              _buildPreviewSection(),
            ],
            if (_selectedImage == null) ...[
              const Divider(height: 1),
              _buildSourceSelection(),
            ],
            if (_selectedImage != null) ...[
              const Divider(height: 1),
              _buildOptionsSection(),
            ],
            if (_isProcessing) _buildProcessingIndicator(),
            if (_errorMessage != null) _buildErrorSection(),
            _buildActionButtons(),
          ],
        ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          
          // Title
          Text(
            widget.title ?? 'Select Image',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          if (widget.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.subtitle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildPreviewSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          
          Center(
            child: widget.customPreview ?? _buildDefaultPreview(),
          ),
          
          const SizedBox(height: 12),
          _buildImageInfo(),
        ],
      ),
    );
  }
  
  Widget _buildDefaultPreview() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          _processedImage ?? _selectedImage!,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
  
  Widget _buildImageInfo() {
    final image = _processedImage ?? _selectedImage!;
    
    return FutureBuilder<Map<String, dynamic>>(
      future: _getImageInfo(image),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 20);
        }
        
        final info = snapshot.data!;
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Size',
                  info['fileSize'] ?? 'Unknown',
                  Icons.storage,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoItem(
                  'Dimensions',
                  info['dimensions'] ?? 'Unknown',
                  Icons.photo_size_select_large,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoItem(
                  'Format',
                  info['format'] ?? 'Unknown',
                  Icons.image,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSourceSelection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Source',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildSourceButton(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSourceButton(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOptionsSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Options',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          
          if (widget.showQualitySelector) _buildQualitySelector(),
          if (widget.showQualitySelector) const SizedBox(height: 16),
          
          if (widget.enableCropping && !widget.lockAspectRatio)
            _buildAspectRatioSelector(),
          if (widget.enableCropping && !widget.lockAspectRatio)
            const SizedBox(height: 16),
          
          _buildActionRow(),
        ],
      ),
    );
  }
  
  Widget _buildQualitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quality'),
        const SizedBox(height: 8),
        
        Wrap(
          spacing: 8,
          children: ImageQuality.values.map((quality) {
            final isSelected = _selectedQuality == quality;
            
            return FilterChip(
              label: Text(quality.label),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedQuality = quality;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildAspectRatioSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Aspect Ratio'),
        const SizedBox(height: 8),
        
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('Free'),
              selected: _selectedAspectRatio == null,
              onSelected: (selected) {
                setState(() {
                  _selectedAspectRatio = null;
                });
              },
            ),
            ...AspectRatioPreset.values.map((ratio) {
              final isSelected = _selectedAspectRatio == ratio;
              
              return FilterChip(
                label: Text(ratio.label),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedAspectRatio = selected ? ratio : null;
                  });
                },
              );
            }),
          ],
        ),
      ],
    );
  }
  
  Widget _buildActionRow() {
    return Row(
      children: [
        if (widget.enableCropping)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _cropImage,
              icon: const Icon(Icons.crop),
              label: const Text('Crop'),
            ),
          ),
        
        if (widget.enableCropping) const SizedBox(width: 12),
        
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery, replace: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Replace'),
          ),
        ),
        
        if (widget.allowRemove) const SizedBox(width: 12),
        if (widget.allowRemove)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _removeImage,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildProcessingIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(
                'Processing image...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          
          if (_processingProgress > 0) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(value: _processingProgress),
            const SizedBox(height: 4),
            Text(
              '${(_processingProgress * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildErrorSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _errorMessage = null),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _cancel,
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _selectedImage != null && !_isProcessing ? _confirm : null,
              child: const Text('Confirm'),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _pickImage(ImageSource source, {bool replace = false}) async {
    try {
      setState(() {
        _errorMessage = null;
        _isProcessing = true;
        _processingProgress = 0.1;
      });
      
      // Simulate image picker - replace with actual implementation
      await Future.delayed(const Duration(milliseconds: 500));
      
      // This would use image_picker package in real implementation
      /*
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source == ImageSource.camera 
            ? ImageSourcePicker.camera 
            : ImageSourcePicker.gallery,
        maxWidth: widget.maxWidth.toDouble(),
        maxHeight: widget.maxHeight.toDouble(),
        imageQuality: _selectedQuality.value,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _processingProgress = 0.7;
        });
        
        // Process image if needed
        await _processImage();
      }
      */
      
      // Simulate success for demo
      setState(() {
        _processingProgress = 1.0;
      });
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      setState(() {
        _isProcessing = false;
        _processingProgress = 0.0;
      });
      
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _processingProgress = 0.0;
        _errorMessage = 'Failed to pick image: ${e.toString()}';
      });
    }
  }
  
  Future<void> _cropImage() async {
    if (_selectedImage == null) return;
    
    try {
      setState(() {
        _isProcessing = true;
        _processingProgress = 0.2;
      });
      
      // This would use image_cropper package in real implementation
      /*
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: _selectedImage!.path,
        aspectRatio: _selectedAspectRatio != null
            ? CropAspectRatio(
                ratioX: _selectedAspectRatio!.ratio,
                ratioY: 1,
              )
            : null,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: widget.lockAspectRatio,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: widget.lockAspectRatio,
          ),
        ],
      );
      
      if (croppedFile != null) {
        setState(() {
          _processedImage = File(croppedFile.path);
          _processingProgress = 0.8;
        });
      }
      */
      
      // Simulate cropping
      await Future.delayed(const Duration(milliseconds: 1000));
      
      setState(() {
        _isProcessing = false;
        _processingProgress = 0.0;
      });
      
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _processingProgress = 0.0;
        _errorMessage = 'Failed to crop image: ${e.toString()}';
      });
    }
  }
  
  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _processedImage = null;
      _errorMessage = null;
    });
  }
  
  void _cancel() {
    final result = const ImagePickerResult(wasCancelled: true);
    widget.onResult?.call(result);
  }
  
  void _confirm() {
    final finalImage = _processedImage ?? _selectedImage;
    
    if (finalImage != null) {
      final result = ImagePickerResult(
        imageFile: finalImage,
        metadata: {
          'quality': _selectedQuality.value,
          'aspectRatio': _selectedAspectRatio?.label,
          'wasProcessed': _processedImage != null,
        },
      );
      
      widget.onImageSelected?.call();
      widget.onResult?.call(result);
    }
  }
  
  Future<Map<String, dynamic>> _getImageInfo(File imageFile) async {
    try {
      final stat = await imageFile.stat();
      final size = stat.size;
      
      // This would use image package to get dimensions
      /*
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      return {
        'fileSize': _formatFileSize(size),
        'dimensions': image != null ? '${image.width}x${image.height}' : 'Unknown',
        'format': path.extension(imageFile.path).toUpperCase(),
      };
      */
      
      // Placeholder info
      return {
        'fileSize': _formatFileSize(size),
        'dimensions': '1080x1080',
        'format': 'JPG',
      };
    } catch (e) {
      return {
        'fileSize': 'Unknown',
        'dimensions': 'Unknown',
        'format': 'Unknown',
      };
    }
  }
  
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
