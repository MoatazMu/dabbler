import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget for inputting game price with currency handling and free option
class PriceInputField extends StatefulWidget {
  /// Current price value (null for free)
  final double? price;
  
  /// Currency code (e.g., 'USD', 'EUR')
  final String currency;
  
  /// Called when price changes
  final Function(double? price)? onChanged;
  
  /// Whether the field is enabled
  final bool enabled;
  
  /// Whether to show the free option
  final bool allowFree;
  
  /// Label for the field
  final String label;
  
  /// Hint text
  final String? hint;
  
  /// Validation function
  final String? Function(double? price)? validator;
  
  /// Minimum allowed price
  final double? minPrice;
  
  /// Maximum allowed price
  final double? maxPrice;
  
  /// Currency symbol to display
  final String? currencySymbol;
  
  /// Number of decimal places
  final int decimalPlaces;

  const PriceInputField({
    super.key,
    this.price,
    this.currency = 'USD',
    this.onChanged,
    this.enabled = true,
    this.allowFree = true,
    this.label = 'Price',
    this.hint,
    this.validator,
    this.minPrice,
    this.maxPrice,
    this.currencySymbol,
    this.decimalPlaces = 2,
  });

  @override
  State<PriceInputField> createState() => _PriceInputFieldState();
}

class _PriceInputFieldState extends State<PriceInputField> {
  late TextEditingController _controller;
  bool _isFree = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _isFree = widget.price == null;
    _controller = TextEditingController(
      text: widget.price?.toStringAsFixed(widget.decimalPlaces) ?? '',
    );
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PriceInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.price != oldWidget.price) {
      _isFree = widget.price == null;
      _controller.text = widget.price?.toStringAsFixed(widget.decimalPlaces) ?? '';
    }
  }

  void _onTextChanged() {
    if (_isFree) return;
    
    final text = _controller.text;
    final price = double.tryParse(text);
    
    _validate(price);
    
    if (_validationError == null) {
      widget.onChanged?.call(price);
    }
  }

  void _validate(double? price) {
    String? error;
    
    if (!_isFree && price == null && _controller.text.isNotEmpty) {
      error = 'Please enter a valid price';
    } else if (price != null) {
      if (widget.minPrice != null && price < widget.minPrice!) {
        error = 'Price must be at least ${_formatPrice(widget.minPrice!)}';
      } else if (widget.maxPrice != null && price > widget.maxPrice!) {
        error = 'Price cannot exceed ${_formatPrice(widget.maxPrice!)}';
      } else if (widget.validator != null) {
        error = widget.validator!(price);
      }
    }
    
    setState(() {
      _validationError = error;
    });
  }

  void _toggleFree(bool isFree) {
    setState(() {
      _isFree = isFree;
      if (isFree) {
        _controller.clear();
        _validationError = null;
        widget.onChanged?.call(null);
      } else {
        // Set to minimum price or 0
        final defaultPrice = widget.minPrice ?? 0.0;
        _controller.text = defaultPrice.toStringAsFixed(widget.decimalPlaces);
        widget.onChanged?.call(defaultPrice);
      }
    });
  }

  String _formatPrice(double price) {
    final symbol = widget.currencySymbol ?? _getCurrencySymbol(widget.currency);
    return '$symbol${price.toStringAsFixed(widget.decimalPlaces)}';
  }

  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'CAD':
        return 'C\$';
      case 'AUD':
        return 'A\$';
      default:
        return currency;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with free option
        Row(
          children: [
            Text(
              widget.label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (widget.allowFree)
              _buildFreeToggle(theme),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Price input field
        AnimatedOpacity(
          opacity: _isFree ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: TextField(
            controller: _controller,
            enabled: widget.enabled && !_isFree,
            keyboardType: TextInputType.numberWithOptions(
              decimal: widget.decimalPlaces > 0,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'^\d*\.?\d{0,' + widget.decimalPlaces.toString() + '}'),
              ),
            ],
            decoration: InputDecoration(
              prefixText: _getCurrencySymbol(widget.currency),
              hintText: widget.hint ?? '0.00',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              errorText: _validationError,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        // Quick price options
        if (!_isFree) ...[
          const SizedBox(height: 12),
          _buildQuickPriceOptions(theme),
        ],
      ],
    );
  }

  Widget _buildFreeToggle(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(
          value: _isFree,
          onChanged: widget.enabled ? _toggleFree : null,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: widget.enabled ? () => _toggleFree(!_isFree) : null,
          child: Text(
            'Free',
            style: theme.textTheme.titleSmall?.copyWith(
              color: _isFree
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickPriceOptions(ThemeData theme) {
    // Common price points
    final commonPrices = [5.0, 10.0, 15.0, 20.0, 25.0];
    
    return Wrap(
      spacing: 8,
      children: commonPrices.map((price) {
        final isValid = (widget.minPrice == null || price >= widget.minPrice!) &&
                       (widget.maxPrice == null || price <= widget.maxPrice!);
        
        if (!isValid) return const SizedBox.shrink();
        
        return ActionChip(
          label: Text(_formatPrice(price)),
          onPressed: widget.enabled ? () {
            _controller.text = price.toStringAsFixed(widget.decimalPlaces);
            widget.onChanged?.call(price);
          } : null,
          backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          labelStyle: theme.textTheme.bodySmall,
        );
      }).toList(),
    );
  }
}

/// Simple price display widget
class PriceDisplay extends StatelessWidget {
  final double? price;
  final String currency;
  final String? currencySymbol;
  final int decimalPlaces;
  final TextStyle? textStyle;
  final String freeText;

  const PriceDisplay({
    super.key,
    required this.price,
    this.currency = 'USD',
    this.currencySymbol,
    this.decimalPlaces = 2,
    this.textStyle,
    this.freeText = 'Free',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveStyle = textStyle ?? theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );
    
    if (price == null || price == 0) {
      return Text(
        freeText,
        style: effectiveStyle?.copyWith(
          color: theme.colorScheme.primary,
        ),
      );
    }
    
    final symbol = currencySymbol ?? _getCurrencySymbol(currency);
    final formattedPrice = '$symbol${price!.toStringAsFixed(decimalPlaces)}';
    
    return Text(
      formattedPrice,
      style: effectiveStyle,
    );
  }

  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'CAD':
        return 'C\$';
      case 'AUD':
        return 'A\$';
      default:
        return currency;
    }
  }
}

/// Price range selector widget
class PriceRangeSelector extends StatefulWidget {
  final double? minPrice;
  final double? maxPrice;
  final double rangeMin;
  final double rangeMax;
  final Function(double? min, double? max)? onChanged;
  final String currency;
  final String? currencySymbol;
  final int decimalPlaces;
  final bool allowFree;

  const PriceRangeSelector({
    super.key,
    this.minPrice,
    this.maxPrice,
    this.rangeMin = 0.0,
    this.rangeMax = 100.0,
    this.onChanged,
    this.currency = 'USD',
    this.currencySymbol,
    this.decimalPlaces = 2,
    this.allowFree = true,
  });

  @override
  State<PriceRangeSelector> createState() => _PriceRangeSelectorState();
}

class _PriceRangeSelectorState extends State<PriceRangeSelector> {
  late RangeValues _values;
  bool _isFreeRange = false;

  @override
  void initState() {
    super.initState();
    _isFreeRange = widget.minPrice == null && widget.maxPrice == null;
    _values = RangeValues(
      widget.minPrice ?? widget.rangeMin,
      widget.maxPrice ?? widget.rangeMax,
    );
  }

  void _onRangeChanged(RangeValues values) {
    setState(() {
      _values = values;
    });
    
    if (!_isFreeRange) {
      widget.onChanged?.call(values.start, values.end);
    }
  }

  void _toggleFreeRange(bool isFree) {
    setState(() {
      _isFreeRange = isFree;
    });
    
    if (isFree) {
      widget.onChanged?.call(null, null);
    } else {
      widget.onChanged?.call(_values.start, _values.end);
    }
  }

  String _formatPrice(double price) {
    final symbol = widget.currencySymbol ?? _getCurrencySymbol(widget.currency);
    return '$symbol${price.toStringAsFixed(widget.decimalPlaces)}';
  }

  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'CAD':
        return 'C\$';
      case 'AUD':
        return 'A\$';
      default:
        return currency;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Price Range',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (widget.allowFree) ...[
              Switch(
                value: _isFreeRange,
                onChanged: _toggleFreeRange,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 8),
              Text(
                'Any Price',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: _isFreeRange
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        
        const SizedBox(height: 16),
        
        if (!_isFreeRange) ...[
          RangeSlider(
            values: _values,
            min: widget.rangeMin,
            max: widget.rangeMax,
            onChanged: _onRangeChanged,
            divisions: ((widget.rangeMax - widget.rangeMin) / 5).round(),
          ),
          
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Min: ${_formatPrice(_values.start)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Max: ${_formatPrice(_values.end)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.all_inclusive_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'All price ranges included',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
