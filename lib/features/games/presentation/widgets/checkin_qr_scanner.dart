import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ScannerState { scanning, success, error, manual }

class CheckinQRScanner extends StatefulWidget {
  final Function(String) onScanned;
  final Function(String)? onManualCodeEntered;
  final VoidCallback? onTorchToggle;
  final VoidCallback? onGallerySelect;
  final String? initialCode;
  final bool showTorchButton;
  final bool showGalleryButton;
  final bool showManualEntry;

  const CheckinQRScanner({
    super.key,
    required this.onScanned,
    this.onManualCodeEntered,
    this.onTorchToggle,
    this.onGallerySelect,
    this.initialCode,
    this.showTorchButton = true,
    this.showGalleryButton = true,
    this.showManualEntry = true,
  });

  @override
  State<CheckinQRScanner> createState() => _CheckinQRScannerState();
}

class _CheckinQRScannerState extends State<CheckinQRScanner>
    with TickerProviderStateMixin {
  late AnimationController _scanAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _scanAnimation;
  late Animation<double> _pulseAnimation;
  
  final TextEditingController _manualCodeController = TextEditingController();
  ScannerState _state = ScannerState.scanning;
  bool _isTorchOn = false;
  bool _showManualEntry = false;
  String? _lastScannedCode;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    
    // Scan line animation
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Pulse animation for success/error feedback
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.elasticOut,
    ));

    _scanAnimationController.repeat();
    
    if (widget.initialCode != null) {
      _manualCodeController.text = widget.initialCode!;
    }
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    _pulseAnimationController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: _showManualEntry
          ? _buildManualEntryView()
          : _buildScannerView(),
    );
  }

  Widget _buildScannerView() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              // Camera preview placeholder
              _buildCameraPreview(),
              
              // Scan overlay
              _buildScanOverlay(),
              
              // Control buttons
              _buildControlButtons(),
              
              // Status messages
              _buildStatusMessage(),
            ],
          ),
        ),
        
        // Bottom controls
        _buildBottomControls(),
      ],
    );
  }

  Widget _buildCameraPreview() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'Camera Preview\n(QR Scanner would be integrated here)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildScanOverlay() {
    return Center(
      child: SizedBox(
        width: 250,
        height: 250,
        child: Stack(
          children: [
            // Corner brackets
            ..._buildCornerBrackets(),
            
            // Scanning line animation
            if (_state == ScannerState.scanning)
              AnimatedBuilder(
                animation: _scanAnimation,
                builder: (context, child) {
                  return Positioned(
                    top: _scanAnimation.value * 230,
                    left: 10,
                    right: 10,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            
            // Success/Error feedback
            if (_state == ScannerState.success || _state == ScannerState.error)
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _state == ScannerState.success 
                              ? Colors.green 
                              : Colors.red,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                                              child: Icon(
                        _state == ScannerState.success 
                            ? Icons.check_circle 
                            : Icons.error,
                        color: _state == ScannerState.success 
                            ? Colors.green 
                            : Colors.red,
                        size: 60,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCornerBrackets() {
    const bracketSize = 30.0;
    const bracketThickness = 4.0;
    
    return [
      // Top-left
      Positioned(
        top: 0,
        left: 0,
        child: _buildCornerBracket(
          [Alignment.topLeft],
          bracketSize,
          bracketThickness,
        ),
      ),
      // Top-right
      Positioned(
        top: 0,
        right: 0,
        child: _buildCornerBracket(
          [Alignment.topRight],
          bracketSize,
          bracketThickness,
        ),
      ),
      // Bottom-left
      Positioned(
        bottom: 0,
        left: 0,
        child: _buildCornerBracket(
          [Alignment.bottomLeft],
          bracketSize,
          bracketThickness,
        ),
      ),
      // Bottom-right
      Positioned(
        bottom: 0,
        right: 0,
        child: _buildCornerBracket(
          [Alignment.bottomRight],
          bracketSize,
          bracketThickness,
        ),
      ),
    ];
  }

  Widget _buildCornerBracket(
    List<Alignment> alignments,
    double size,
    double thickness,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border(
          left: alignments.contains(Alignment.topLeft) || 
                 alignments.contains(Alignment.bottomLeft)
              ? BorderSide(color: Colors.white, width: thickness)
              : BorderSide.none,
          right: alignments.contains(Alignment.topRight) || 
                  alignments.contains(Alignment.bottomRight)
              ? BorderSide(color: Colors.white, width: thickness)
              : BorderSide.none,
          top: alignments.contains(Alignment.topLeft) || 
               alignments.contains(Alignment.topRight)
              ? BorderSide(color: Colors.white, width: thickness)
              : BorderSide.none,
          bottom: alignments.contains(Alignment.bottomLeft) || 
                  alignments.contains(Alignment.bottomRight)
              ? BorderSide(color: Colors.white, width: thickness)
              : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Positioned(
      top: 20,
      right: 20,
      child: Column(
        children: [
          if (widget.showTorchButton)
            _buildControlButton(
              icon: _isTorchOn ? Icons.flash_on : Icons.flash_off,
              onPressed: _toggleTorch,
              isActive: _isTorchOn,
            ),
          
          const SizedBox(height: 12),
          
          if (widget.showGalleryButton)
            _buildControlButton(
              icon: Icons.photo_library,
              onPressed: widget.onGallerySelect,
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    bool isActive = false,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.black.withOpacity(0.6),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isActive ? Colors.black : Colors.white,
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildStatusMessage() {
    if (_state == ScannerState.scanning) return const SizedBox.shrink();

    String message;
    Color color;
    IconData icon;

    switch (_state) {
      case ScannerState.success:
        message = 'Code scanned successfully!';
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case ScannerState.error:
        message = _errorMessage ?? 'Failed to scan code';
        color = Colors.red;
        icon = Icons.error;
        break;
      case ScannerState.manual:
        return const SizedBox.shrink();
      case ScannerState.scanning:
        return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 100,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Instructions
          Text(
            'Point your camera at the QR code to check in',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Manual entry button
          if (widget.showManualEntry)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showManualEntry = true;
                });
              },
              icon: const Icon(Icons.keyboard),
              label: const Text('Enter code manually'),
            ),
        ],
      ),
    );
  }

  Widget _buildManualEntryView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _showManualEntry = false;
                  });
                },
                icon: const Icon(Icons.arrow_back),
              ),
              const Expanded(
                child: Text(
                  'Enter Check-in Code',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // Balance the back button
            ],
          ),
          
          const SizedBox(height: 40),
          
          // Manual code input
          TextField(
            controller: _manualCodeController,
            decoration: const InputDecoration(
              labelText: 'Game Check-in Code',
              hintText: 'Enter 6-digit code',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.qr_code),
            ),
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
            maxLength: 8,
            onChanged: (value) {
              // Auto-submit if code is complete
              if (value.length == 6) {
                _submitManualCode();
              }
            },
          ),
          
          const SizedBox(height: 20),
          
          // Submit button
          ElevatedButton.icon(
            onPressed: _submitManualCode,
            icon: const Icon(Icons.login),
            label: const Text('Check In'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Help text
          Text(
            'Ask the game organizer for the 6-digit check-in code if you can\'t scan the QR code.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _toggleTorch() {
    setState(() {
      _isTorchOn = !_isTorchOn;
    });
    widget.onTorchToggle?.call();
  }

  void _simulateQRScan(String code) {
    setState(() {
      _state = ScannerState.success;
      _lastScannedCode = code;
    });
    
    _pulseAnimationController.forward().then((_) {
      _pulseAnimationController.reverse();
    });
    
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    // Notify parent
    widget.onScanned(code);
    
    // Reset state after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _state = ScannerState.scanning;
        });
      }
    });
  }

  void _simulateQRError(String error) {
    setState(() {
      _state = ScannerState.error;
      _errorMessage = error;
    });
    
    _pulseAnimationController.forward().then((_) {
      _pulseAnimationController.reverse();
    });
    
    // Haptic feedback
    HapticFeedback.heavyImpact();
    
    // Reset state after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _state = ScannerState.scanning;
        });
      }
    });
  }

  void _submitManualCode() {
    final code = _manualCodeController.text.trim().toUpperCase();
    
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a check-in code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-in code must be at least 6 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Hide keyboard
    FocusScope.of(context).unfocus();
    
    // Notify parent
    widget.onManualCodeEntered?.call(code);
  }

  // Public methods for external control
  void startScanning() {
    setState(() {
      _state = ScannerState.scanning;
      _showManualEntry = false;
    });
    _scanAnimationController.repeat();
  }

  void stopScanning() {
    _scanAnimationController.stop();
  }

  void simulateSuccessfulScan(String code) {
    _simulateQRScan(code);
  }

  void simulateFailedScan(String error) {
    _simulateQRError(error);
  }

  // Getter for the last scanned code
  String? get lastScannedCode => _lastScannedCode;
}
