/// Full screen photo viewer with editing capabilities
library;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Photo editing action
enum PhotoEditAction {
  crop,
  rotate,
  filter,
  brightness,
  contrast,
  saturation,
}

/// Photo filter type
enum PhotoFilter {
  none,
  vintage,
  blackWhite,
  sepia,
  cool,
  warm,
  dramatic,
  vibrant,
}

/// Photo data for the dialog
class PhotoData {
  final String id;
  final File? file;
  final Uint8List? bytes;
  final String? url;
  final String? title;
  final String? description;
  final DateTime? dateTaken;
  final bool isEditable;
  final bool isDeletable;
  final Map<String, dynamic> metadata;
  
  const PhotoData({
    required this.id,
    this.file,
    this.bytes,
    this.url,
    this.title,
    this.description,
    this.dateTaken,
    this.isEditable = true,
    this.isDeletable = true,
    this.metadata = const {},
  });
  
  bool get hasImage => file != null || bytes != null || url != null;
  
  PhotoData copyWith({
    String? id,
    File? file,
    Uint8List? bytes,
    String? url,
    String? title,
    String? description,
    DateTime? dateTaken,
    bool? isEditable,
    bool? isDeletable,
    Map<String, dynamic>? metadata,
  }) {
    return PhotoData(
      id: id ?? this.id,
      file: file ?? this.file,
      bytes: bytes ?? this.bytes,
      url: url ?? this.url,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTaken: dateTaken ?? this.dateTaken,
      isEditable: isEditable ?? this.isEditable,
      isDeletable: isDeletable ?? this.isDeletable,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Photo edit configuration
class PhotoEditConfig {
  final double brightness;
  final double contrast;
  final double saturation;
  final PhotoFilter filter;
  final double rotation; // in radians
  final Rect? cropRect;
  
  const PhotoEditConfig({
    this.brightness = 0.0, // -1.0 to 1.0
    this.contrast = 0.0, // -1.0 to 1.0
    this.saturation = 0.0, // -1.0 to 1.0
    this.filter = PhotoFilter.none,
    this.rotation = 0.0,
    this.cropRect,
  });
  
  PhotoEditConfig copyWith({
    double? brightness,
    double? contrast,
    double? saturation,
    PhotoFilter? filter,
    double? rotation,
    Rect? cropRect,
  }) {
    return PhotoEditConfig(
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      filter: filter ?? this.filter,
      rotation: rotation ?? this.rotation,
      cropRect: cropRect ?? this.cropRect,
    );
  }
  
  bool get hasChanges => 
      brightness != 0.0 ||
      contrast != 0.0 ||
      saturation != 0.0 ||
      filter != PhotoFilter.none ||
      rotation != 0.0 ||
      cropRect != null;
}

/// Full screen photo dialog
class ProfilePhotoDialog extends StatefulWidget {
  final PhotoData photo;
  final bool enableEditing;
  final bool enableSharing;
  final bool enableDeletion;
  final Function(PhotoData, PhotoEditConfig)? onSave;
  final Function(PhotoData)? onShare;
  final Function(PhotoData)? onDelete;
  final VoidCallback? onClose;
  final List<PhotoFilter> availableFilters;
  final Duration animationDuration;
  final bool enableHapticFeedback;
  
  const ProfilePhotoDialog({
    super.key,
    required this.photo,
    this.enableEditing = true,
    this.enableSharing = true,
    this.enableDeletion = true,
    this.onSave,
    this.onShare,
    this.onDelete,
    this.onClose,
    this.availableFilters = const [
      PhotoFilter.none,
      PhotoFilter.vintage,
      PhotoFilter.blackWhite,
      PhotoFilter.sepia,
      PhotoFilter.cool,
      PhotoFilter.warm,
      PhotoFilter.dramatic,
      PhotoFilter.vibrant,
    ],
    this.animationDuration = const Duration(milliseconds: 300),
    this.enableHapticFeedback = true,
  });
  
  static Future<T?> show<T>({
    required BuildContext context,
    required PhotoData photo,
    bool enableEditing = true,
    bool enableSharing = true,
    bool enableDeletion = true,
    Function(PhotoData, PhotoEditConfig)? onSave,
    Function(PhotoData)? onShare,
    Function(PhotoData)? onDelete,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (context) => ProfilePhotoDialog(
        photo: photo,
        enableEditing: enableEditing,
        enableSharing: enableSharing,
        enableDeletion: enableDeletion,
        onSave: onSave,
        onShare: onShare,
        onDelete: onDelete,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }
  
  @override
  State<ProfilePhotoDialog> createState() => _ProfilePhotoDialogState();
}

class _ProfilePhotoDialogState extends State<ProfilePhotoDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _editPanelController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _editPanelAnimation;
  
  final TransformationController _transformationController = TransformationController();
  
  PhotoEditConfig _editConfig = const PhotoEditConfig();
  bool _isEditMode = false;
  bool _isProcessing = false;
  PhotoEditAction? _activeEditAction;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startEntranceAnimation();
  }
  
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _editPanelController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _editPanelAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _editPanelController,
      curve: Curves.easeOutCubic,
    ));
  }
  
  void _startEntranceAnimation() {
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _editPanelController.dispose();
    _transformationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Dialog.fullscreen(
              backgroundColor: Colors.black,
              child: _buildDialogContent(),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildDialogContent() {
    return Stack(
      children: [
        // Photo viewer
        _buildPhotoViewer(),
        
        // Top bar
        _buildTopBar(),
        
        // Bottom bar
        if (!_isEditMode)
          _buildBottomBar(),
        
        // Edit panel
        if (_isEditMode)
          _buildEditPanel(),
        
        // Loading overlay
        if (_isProcessing)
          _buildLoadingOverlay(),
      ],
    );
  }
  
  Widget _buildPhotoViewer() {
    return Center(
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.5,
        maxScale: 5.0,
        child: _buildPhotoWidget(),
      ),
    );
  }
  
  Widget _buildPhotoWidget() {
    Widget imageWidget;
    
    if (widget.photo.file != null) {
      imageWidget = Image.file(
        widget.photo.file!,
        fit: BoxFit.contain,
      );
    } else if (widget.photo.bytes != null) {
      imageWidget = Image.memory(
        widget.photo.bytes!,
        fit: BoxFit.contain,
      );
    } else if (widget.photo.url != null) {
      imageWidget = Image.network(
        widget.photo.url!,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    } else {
      imageWidget = _buildErrorWidget();
    }
    
    // Apply edit effects
    return _applyPhotoEffects(imageWidget);
  }
  
  Widget _applyPhotoEffects(Widget imageWidget) {
    Widget effectsWidget = imageWidget;
    
    // Apply rotation
    if (_editConfig.rotation != 0.0) {
      effectsWidget = Transform.rotate(
        angle: _editConfig.rotation,
        child: effectsWidget,
      );
    }
    
    // Apply color filters
    if (_editConfig.hasChanges) {
      effectsWidget = ColorFiltered(
        colorFilter: _getColorFilter(),
        child: effectsWidget,
      );
    }
    
    return effectsWidget;
  }
  
  ColorFilter _getColorFilter() {
    // This is a simplified implementation
    // In a real app, you'd use more sophisticated image processing
    
    switch (_editConfig.filter) {
      case PhotoFilter.blackWhite:
        return const ColorFilter.mode(Colors.grey, BlendMode.saturation);
      case PhotoFilter.sepia:
        return ColorFilter.mode(Colors.brown.withOpacity(0.3), BlendMode.overlay);
      case PhotoFilter.cool:
        return ColorFilter.mode(Colors.blue.withOpacity(0.2), BlendMode.overlay);
      case PhotoFilter.warm:
        return ColorFilter.mode(Colors.orange.withOpacity(0.2), BlendMode.overlay);
      case PhotoFilter.dramatic:
        return const ColorFilter.mode(Colors.black, BlendMode.multiply);
      case PhotoFilter.vibrant:
        return ColorFilter.mode(Colors.purple.withOpacity(0.1), BlendMode.overlay);
      case PhotoFilter.vintage:
        return ColorFilter.mode(Colors.amber.withOpacity(0.3), BlendMode.overlay);
      default:
        return const ColorFilter.mode(Colors.transparent, BlendMode.multiply);
    }
  }
  
  Widget _buildErrorWidget() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 8),
          Text(
            'Image not available',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // Close button
            IconButton(
              onPressed: _handleClose,
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 28,
              ),
            ),
            
            const Spacer(),
            
            // Photo info
            if (widget.photo.title != null) ...[
              Expanded(
                child: Column(
                  children: [
                    Text(
                      widget.photo.title!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    if (widget.photo.dateTaken != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(widget.photo.dateTaken!),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            const Spacer(),
            
            // More options
            IconButton(
              onPressed: _showMoreOptions,
              icon: const Icon(
                Icons.more_vert,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Edit button
            if (widget.enableEditing && widget.photo.isEditable)
              _buildActionButton(
                icon: Icons.edit,
                label: 'Edit',
                onTap: _enterEditMode,
              ),
            
            // Share button
            if (widget.enableSharing)
              _buildActionButton(
                icon: Icons.share,
                label: 'Share',
                onTap: _handleShare,
              ),
            
            // Delete button
            if (widget.enableDeletion && widget.photo.isDeletable)
              _buildActionButton(
                icon: Icons.delete,
                label: 'Delete',
                onTap: _handleDelete,
                color: Colors.red,
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final buttonColor = color ?? Colors.white;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: buttonColor.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: buttonColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: buttonColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEditPanel() {
    return AnimatedBuilder(
      animation: _editPanelAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: _editPanelAnimation,
          child: Container(
            height: 300,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Edit panel header
                _buildEditPanelHeader(),
                
                // Edit options
                Expanded(
                  child: _buildEditOptions(),
                ),
                
                // Edit panel footer
                _buildEditPanelFooter(),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildEditPanelHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: _exitEditMode,
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(width: 8),
          const Text(
            'Edit Photo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const Spacer(),
          
          if (_editConfig.hasChanges)
            TextButton(
              onPressed: _resetEdits,
              child: const Text(
                'Reset',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildEditOptions() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Edit action buttons
          _buildEditActionButtons(),
          
          const SizedBox(height: 16),
          
          // Active edit controls
          if (_activeEditAction != null)
            _buildActiveEditControls(),
        ],
      ),
    );
  }
  
  Widget _buildEditActionButtons() {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildEditActionButton(
            action: PhotoEditAction.filter,
            icon: Icons.filter,
            label: 'Filters',
          ),
          _buildEditActionButton(
            action: PhotoEditAction.brightness,
            icon: Icons.brightness_6,
            label: 'Brightness',
          ),
          _buildEditActionButton(
            action: PhotoEditAction.contrast,
            icon: Icons.contrast,
            label: 'Contrast',
          ),
          _buildEditActionButton(
            action: PhotoEditAction.saturation,
            icon: Icons.palette,
            label: 'Saturation',
          ),
          _buildEditActionButton(
            action: PhotoEditAction.rotate,
            icon: Icons.rotate_right,
            label: 'Rotate',
          ),
          _buildEditActionButton(
            action: PhotoEditAction.crop,
            icon: Icons.crop,
            label: 'Crop',
          ),
        ],
      ),
    );
  }
  
  Widget _buildEditActionButton({
    required PhotoEditAction action,
    required IconData icon,
    required String label,
  }) {
    final isActive = _activeEditAction == action;
    
    return GestureDetector(
      onTap: () => _setActiveEditAction(action),
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isActive 
              ? Theme.of(context).primaryColor 
              : Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActiveEditControls() {
    switch (_activeEditAction!) {
      case PhotoEditAction.filter:
        return _buildFilterControls();
      case PhotoEditAction.brightness:
        return _buildSliderControl(
          label: 'Brightness',
          value: _editConfig.brightness,
          onChanged: (value) => _updateEditConfig(brightness: value),
        );
      case PhotoEditAction.contrast:
        return _buildSliderControl(
          label: 'Contrast',
          value: _editConfig.contrast,
          onChanged: (value) => _updateEditConfig(contrast: value),
        );
      case PhotoEditAction.saturation:
        return _buildSliderControl(
          label: 'Saturation',
          value: _editConfig.saturation,
          onChanged: (value) => _updateEditConfig(saturation: value),
        );
      case PhotoEditAction.rotate:
        return _buildRotateControls();
      case PhotoEditAction.crop:
        return _buildCropControls();
    }
  }
  
  Widget _buildFilterControls() {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: widget.availableFilters.map((filter) {
          return _buildFilterPreview(filter);
        }).toList(),
      ),
    );
  }
  
  Widget _buildFilterPreview(PhotoFilter filter) {
    final isSelected = _editConfig.filter == filter;
    
    return GestureDetector(
      onTap: () => _updateEditConfig(filter: filter),
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).primaryColor 
                : Colors.grey[600]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            // Filter preview thumbnail
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
                child: Center(
                  child: Text(
                    _getFilterName(filter),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            
            Container(
              padding: const EdgeInsets.all(4),
              child: Text(
                _getFilterName(filter),
                style: TextStyle(
                  color: isSelected 
                      ? Theme.of(context).primaryColor 
                      : Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSliderControl({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                '-',
                style: TextStyle(color: Colors.white70),
              ),
              
              Expanded(
                child: Slider(
                  value: value,
                  min: -1.0,
                  max: 1.0,
                  divisions: 100,
                  onChanged: onChanged,
                  activeColor: Theme.of(context).primaryColor,
                  inactiveColor: Colors.grey[600],
                ),
              ),
              
              const Text(
                '+',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          
          Text(
            '${(value * 100).round()}%',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRotateControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildRotateButton(
            icon: Icons.rotate_left,
            label: 'Left',
            onTap: () => _rotatePhoto(-90),
          ),
          _buildRotateButton(
            icon: Icons.rotate_right,
            label: 'Right',
            onTap: () => _rotatePhoto(90),
          ),
          _buildRotateButton(
            icon: Icons.flip,
            label: 'Flip',
            onTap: () => _rotatePhoto(180),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRotateButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCropControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const Text(
            'Crop',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 16),
          Text(
            'Pinch and drag to adjust crop area',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildEditPanelFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: _exitEditMode,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.white30),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _editConfig.hasChanges ? _savePhoto : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Save',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Processing image...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getFilterName(PhotoFilter filter) {
    switch (filter) {
      case PhotoFilter.none:
        return 'Original';
      case PhotoFilter.vintage:
        return 'Vintage';
      case PhotoFilter.blackWhite:
        return 'B&W';
      case PhotoFilter.sepia:
        return 'Sepia';
      case PhotoFilter.cool:
        return 'Cool';
      case PhotoFilter.warm:
        return 'Warm';
      case PhotoFilter.dramatic:
        return 'Dramatic';
      case PhotoFilter.vibrant:
        return 'Vibrant';
    }
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
  void _handleClose() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    
    _animationController.reverse().then((_) {
      widget.onClose?.call();
    });
  }
  
  void _handleShare() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    
    widget.onShare?.call(widget.photo);
  }
  
  void _handleDelete() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.mediumImpact();
    }
    
    _showDeleteConfirmation();
  }
  
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text(
          'Are you sure you want to delete this photo? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete?.call(widget.photo);
              _handleClose();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info, color: Colors.white),
              title: const Text(
                'Photo Info',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _showPhotoInfo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.download, color: Colors.white),
              title: const Text(
                'Download',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _downloadPhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.orange),
              title: const Text(
                'Report',
                style: TextStyle(color: Colors.orange),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _reportPhoto();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showPhotoInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Photo Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.photo.title != null) ...[
              Text('Title: ${widget.photo.title}'),
              const SizedBox(height: 8),
            ],
            if (widget.photo.dateTaken != null) ...[
              Text('Date: ${_formatDate(widget.photo.dateTaken!)}'),
              const SizedBox(height: 8),
            ],
            if (widget.photo.description != null) ...[
              Text('Description: ${widget.photo.description}'),
              const SizedBox(height: 8),
            ],
            if (widget.photo.metadata.isNotEmpty) ...[
              const Text('Metadata:'),
              ...widget.photo.metadata.entries.map((entry) {
                return Text('${entry.key}: ${entry.value}');
              }),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _downloadPhoto() {
    // Implement photo download
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo download started')),
    );
  }
  
  void _reportPhoto() {
    // Implement photo reporting
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo reported')),
    );
  }
  
  void _enterEditMode() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    
    setState(() {
      _isEditMode = true;
    });
    
    _editPanelController.forward();
  }
  
  void _exitEditMode() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    
    _editPanelController.reverse().then((_) {
      setState(() {
        _isEditMode = false;
        _activeEditAction = null;
      });
    });
  }
  
  void _setActiveEditAction(PhotoEditAction action) {
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    
    setState(() {
      _activeEditAction = _activeEditAction == action ? null : action;
    });
  }
  
  void _updateEditConfig({
    double? brightness,
    double? contrast,
    double? saturation,
    PhotoFilter? filter,
    double? rotation,
    Rect? cropRect,
  }) {
    setState(() {
      _editConfig = _editConfig.copyWith(
        brightness: brightness,
        contrast: contrast,
        saturation: saturation,
        filter: filter,
        rotation: rotation,
        cropRect: cropRect,
      );
    });
  }
  
  void _rotatePhoto(double degrees) {
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    
    final radians = degrees * (3.14159 / 180);
    _updateEditConfig(rotation: _editConfig.rotation + radians);
  }
  
  void _resetEdits() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.mediumImpact();
    }
    
    setState(() {
      _editConfig = const PhotoEditConfig();
    });
  }
  
  Future<void> _savePhoto() async {
    if (widget.enableHapticFeedback) {
      HapticFeedback.heavyImpact();
    }
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      // Simulate processing time
      await Future.delayed(const Duration(seconds: 2));
      
      widget.onSave?.call(widget.photo, _editConfig);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo saved successfully')),
      );
      
      _exitEditMode();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save photo: $e')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
}
