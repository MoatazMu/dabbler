import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/constants/sports_constants.dart';

/// Widget for selecting minimum and maximum player count with validation
class PlayerCountSelector extends StatefulWidget {
  /// Current minimum player count
  final int minPlayers;
  
  /// Current maximum player count
  final int maxPlayers;
  
  /// Sport type for validation limits
  final SportType? sportType;
  
  /// Called when player counts change
  final Function(int minPlayers, int maxPlayers)? onChanged;
  
  /// Whether the selector is enabled
  final bool enabled;
  
  /// Custom validation function
  final String? Function(int min, int max)? validator;
  
  /// Show validation errors
  final bool showValidation;

  const PlayerCountSelector({
    super.key,
    required this.minPlayers,
    required this.maxPlayers,
    this.sportType,
    this.onChanged,
    this.enabled = true,
    this.validator,
    this.showValidation = true,
  });

  @override
  State<PlayerCountSelector> createState() => _PlayerCountSelectorState();
}

class _PlayerCountSelectorState extends State<PlayerCountSelector> {
  late TextEditingController _minController;
  late TextEditingController _maxController;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _minController = TextEditingController(text: widget.minPlayers.toString());
    _maxController = TextEditingController(text: widget.maxPlayers.toString());
    _minController.addListener(_onMinChanged);
    _maxController.addListener(_onMaxChanged);
  }

  @override
  void dispose() {
    _minController.removeListener(_onMinChanged);
    _maxController.removeListener(_onMaxChanged);
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PlayerCountSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.minPlayers != oldWidget.minPlayers) {
      _minController.text = widget.minPlayers.toString();
    }
    if (widget.maxPlayers != oldWidget.maxPlayers) {
      _maxController.text = widget.maxPlayers.toString();
    }
  }

  void _onMinChanged() {
    final min = int.tryParse(_minController.text) ?? widget.minPlayers;
    final max = int.tryParse(_maxController.text) ?? widget.maxPlayers;
    _validateAndUpdate(min, max);
  }

  void _onMaxChanged() {
    final min = int.tryParse(_minController.text) ?? widget.minPlayers;
    final max = int.tryParse(_maxController.text) ?? widget.maxPlayers;
    _validateAndUpdate(min, max);
  }

  void _validateAndUpdate(int min, int max) {
    String? error = _validatePlayerCounts(min, max);
    
    setState(() {
      _validationError = error;
    });
    
    if (error == null) {
      widget.onChanged?.call(min, max);
    }
  }

  String? _validatePlayerCounts(int min, int max) {
    // Custom validation first
    if (widget.validator != null) {
      final customError = widget.validator!(min, max);
      if (customError != null) return customError;
    }

    // Basic validation
    if (min <= 0) return 'Minimum players must be greater than 0';
    if (max <= 0) return 'Maximum players must be greater than 0';
    if (min > max) return 'Minimum cannot be greater than maximum';

    // Sport-specific validation
    if (widget.sportType != null) {
      final sportConfig = SportsConstants.getConfiguration(widget.sportType!);
      
      if (sportConfig != null) {
        if (min < sportConfig.minPlayers) {
          return 'Minimum players for ${widget.sportType!.displayName} is ${sportConfig.minPlayers}';
        }
        
        if (max > sportConfig.maxPlayers) {
          return 'Maximum players for ${widget.sportType!.displayName} is ${sportConfig.maxPlayers}';
        }
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with sport info
        Row(
          children: [
            Text(
              'Player Count',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.sportType != null) ...[
              const SizedBox(width: 8),
              _buildSportLimitsChip(theme),
            ],
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Min/Max input row
        Row(
          children: [
            // Minimum players
            Expanded(
              child: _buildPlayerCountField(
                controller: _minController,
                label: 'Min',
                enabled: widget.enabled,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Dash separator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '—',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Maximum players
            Expanded(
              child: _buildPlayerCountField(
                controller: _maxController,
                label: 'Max',
                enabled: widget.enabled,
              ),
            ),
          ],
        ),
        
        // Quick selection buttons
        const SizedBox(height: 12),
        _buildQuickSelectionButtons(),
        
        // Validation error
        if (widget.showValidation && _validationError != null) ...[
          const SizedBox(height: 8),
          Text(
            _validationError!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlayerCountField({
    required TextEditingController controller,
    required String label,
    required bool enabled,
  }) {
    final theme = Theme.of(context);
    
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(3),
      ],
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
      textAlign: TextAlign.center,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSportLimitsChip(ThemeData theme) {
    if (widget.sportType == null) return const SizedBox.shrink();
    
    final sportConfig = SportsConstants.getConfiguration(widget.sportType!);
    if (sportConfig == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${sportConfig.minPlayers}-${sportConfig.maxPlayers} typical',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildQuickSelectionButtons() {
    if (widget.sportType == null) return const SizedBox.shrink();
    
    final sportConfig = SportsConstants.getConfiguration(widget.sportType!);
    if (sportConfig == null) return const SizedBox.shrink();
    
    final theme = Theme.of(context);
    
    // Generate common player count options
    final commonCounts = <String, List<int>>{};
    
    // Typical range
    final typicalMin = sportConfig.minPlayers;
    final typicalMax = sportConfig.maxPlayers;
    commonCounts['Typical'] = [typicalMin, typicalMax];
    
    // Small group
    if (typicalMin > 2) {
      commonCounts['Small'] = [2, typicalMin];
    }
    
    // Large group
    if (typicalMax < 20) {
      commonCounts['Large'] = [typicalMax, (typicalMax * 1.5).round()];
    }
    
    return Wrap(
      spacing: 8,
      children: commonCounts.entries.map((entry) {
        final label = entry.key;
        final range = entry.value;
        final min = range[0];
        final max = range[1];
        
        return ActionChip(
          label: Text('$label ($min-$max)'),
          onPressed: widget.enabled ? () {
            _minController.text = min.toString();
            _maxController.text = max.toString();
            _validateAndUpdate(min, max);
          } : null,
          backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          labelStyle: theme.textTheme.bodySmall,
        );
      }).toList(),
    );
  }
}

/// Simple stepper widget for player count
class PlayerCountStepper extends StatelessWidget {
  final int value;
  final int minValue;
  final int maxValue;
  final Function(int value)? onChanged;
  final String label;
  final bool enabled;

  const PlayerCountStepper({
    super.key,
    required this.value,
    this.minValue = 1,
    this.maxValue = 50,
    this.onChanged,
    this.label = 'Players',
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Decrease button
            IconButton(
              onPressed: enabled && value > minValue
                  ? () => onChanged?.call(value - 1)
                  : null,
              icon: const Icon(Icons.remove_rounded),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                foregroundColor: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Value display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value.toString(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Increase button
            IconButton(
              onPressed: enabled && value < maxValue
                  ? () => onChanged?.call(value + 1)
                  : null,
              icon: const Icon(Icons.add_rounded),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                foregroundColor: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        
        // Range indicator
        const SizedBox(height: 4),
        Text(
          '$minValue - $maxValue',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
