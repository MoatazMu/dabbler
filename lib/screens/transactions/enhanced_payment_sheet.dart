import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../themes/app_theme.dart';

/// Enhanced Payment Sheet with professional UI/UX
/// 
/// Features:
/// - Multiple payment method support
/// - Real-time validation
/// - Loading states
/// - Success/Error animations
/// - Transaction confirmation
/// - Save to transaction history
class EnhancedPaymentSheet extends StatefulWidget {
  final double amount;
  final String currency;
  final String recipientName;
  final String description;
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;

  const EnhancedPaymentSheet({
    super.key,
    required this.amount,
    this.currency = 'AED',
    required this.recipientName,
    required this.description,
    this.onSuccess,
    this.onCancel,
  });

  @override
  State<EnhancedPaymentSheet> createState() => _EnhancedPaymentSheetState();
}

class _EnhancedPaymentSheetState extends State<EnhancedPaymentSheet> 
    with SingleTickerProviderStateMixin {
  String? _selectedPaymentMethod;
  bool _isProcessing = false;
  bool _isSuccess = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  // Mock payment methods - Replace with real data
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'card_1',
      'type': 'card',
      'name': 'Visa',
      'last4': '4242',
      'icon': LucideIcons.creditCard,
      'color': const Color(0xFF1A1F71),
      'brand': 'visa',
    },
    {
      'id': 'card_2',
      'type': 'card',
      'name': 'Mastercard',
      'last4': '8888',
      'icon': LucideIcons.creditCard,
      'color': const Color(0xFFEB001B),
      'brand': 'mastercard',
    },
    {
      'id': 'apple_pay',
      'type': 'wallet',
      'name': 'Apple Pay',
      'icon': LucideIcons.smartphone,
      'color': Colors.black,
      'brand': 'apple',
    },
    {
      'id': 'google_pay',
      'type': 'wallet',
      'name': 'Google Pay',
      'icon': LucideIcons.wallet,
      'color': const Color(0xFF4285F4),
      'brand': 'google',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (_paymentMethods.isNotEmpty) {
      _selectedPaymentMethod = _paymentMethods.first['id'];
    }
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: _isSuccess 
          ? _buildSuccessState(context) 
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHandle(context),
                _buildHeader(context),
                _buildAmountSection(context),
                if (_errorMessage != null) _buildErrorBanner(context),
                _buildPaymentMethods(context),
                _buildTransactionDetails(context),
                _buildActions(context),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
    );
  }

  Widget _buildHandle(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: context.colors.outline.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.shield,
              color: context.colors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Payment',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Your payment is encrypted & secure',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              LucideIcons.x,
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF813FD6),
            const Color(0xFF813FD6).withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF813FD6).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Total Amount',
            style: context.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.currency} ${widget.amount.toStringAsFixed(2)}',
            style: context.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.building,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.recipientName,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.alertCircle,
            color: Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: context.textTheme.bodySmall?.copyWith(
                color: Colors.red.shade900,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _errorMessage = null),
            icon: Icon(LucideIcons.x, size: 18, color: Colors.red),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Text(
            'Payment Method',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: _paymentMethods.length,
          itemBuilder: (context, index) {
            final method = _paymentMethods[index];
            final isSelected = _selectedPaymentMethod == method['id'];
            
            return GestureDetector(
              onTap: () => setState(() => _selectedPaymentMethod = method['id']),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? context.colors.primary.withValues(alpha: 0.1) 
                      : context.violetCardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? context.colors.primary 
                        : context.colors.outline.withValues(alpha: 0.1),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (method['color'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        method['icon'],
                        color: method['color'],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method['name'],
                            style: context.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (method['last4'] != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '•••• ${method['last4']}',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        LucideIcons.checkCircle2,
                        color: context.colors.primary,
                        size: 24,
                      )
                    else
                      Icon(
                        LucideIcons.circle,
                        color: context.colors.outline,
                        size: 24,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTransactionDetails(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transaction Details',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(context, 'Description', widget.description),
          _buildDetailRow(context, 'Recipient', widget.recipientName),
          _buildDetailRow(context, 'Transaction Fee', 'Free'),
          const Divider(height: 24),
          _buildDetailRow(
            context, 
            'Total', 
            '${widget.currency} ${widget.amount.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
              color: isTotal ? context.colors.primary : context.colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isProcessing
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.lock, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Pay ${widget.currency} ${widget.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _isProcessing ? null : () {
              widget.onCancel?.call();
              Navigator.of(context).pop();
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.checkCircle2,
                color: Colors.green,
                size: 64,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Payment Successful!',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your payment of ${widget.currency} ${widget.amount.toStringAsFixed(2)} has been processed successfully.',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSuccess?.call();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == null) {
      setState(() {
        _errorMessage = 'Please select a payment method';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    // Add haptic feedback
    HapticFeedback.mediumImpact();

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    // Simulate 90% success rate
    final isSuccess = DateTime.now().millisecond % 10 != 0;

    if (isSuccess) {
      // TODO: Save transaction to database
      final transactionId = 'TXN${DateTime.now().millisecondsSinceEpoch}';
      print('Transaction successful: $transactionId');
      
      setState(() {
        _isProcessing = false;
        _isSuccess = true;
      });
      
      _animationController.forward();
      
      // Auto-close after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          widget.onSuccess?.call();
          Navigator.of(context).pop();
        }
      });
    } else {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Payment failed. Please try again or use a different payment method.';
      });
      
      // Vibrate for error
      HapticFeedback.heavyImpact();
    }
  }
}
