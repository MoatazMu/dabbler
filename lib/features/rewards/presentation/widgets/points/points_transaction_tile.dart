import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Points transaction data
class PointsTransaction {
  final String id;
  final TransactionType type;
  final int points;
  final String description;
  final DateTime timestamp;
  final List<MultiplierData> multipliers;
  final String sourceReference;
  final int runningBalance;
  final Map<String, dynamic>? metadata;

  const PointsTransaction({
    required this.id,
    required this.type,
    required this.points,
    required this.description,
    required this.timestamp,
    this.multipliers = const [],
    this.sourceReference = '',
    required this.runningBalance,
    this.metadata,
  });

  bool get isPositive => points > 0;
  bool get isNegative => points < 0;
  int get absolutePoints => points.abs();

  String get formattedPoints {
    final formatted = absolutePoints.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return isPositive ? '+$formatted' : '-$formatted';
  }

  String get formattedBalance {
    return runningBalance.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  int get totalMultipliedPoints {
    if (multipliers.isEmpty) return points;
    
    double total = points.toDouble();
    for (final multiplier in multipliers) {
      total *= multiplier.value;
    }
    return total.round();
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Multiplier data
class MultiplierData {
  final String name;
  final double value;
  final String description;
  final Color color;

  const MultiplierData({
    required this.name,
    required this.value,
    required this.description,
    this.color = Colors.orange,
  });

  String get formattedValue => '${(value * 100).toInt()}%';
}

enum TransactionType {
  earned,
  spent,
  bonus,
  penalty,
  refund,
  gift,
  achievement,
  daily,
  challenge,
  referral,
}

/// Points transaction tile widget
class PointsTransactionTile extends StatefulWidget {
  final PointsTransaction transaction;
  final VoidCallback? onTap;
  final Function(String)? onAction;
  final bool showBalance;
  final bool showMultipliers;
  final bool showSource;
  final bool enableHaptics;
  final bool isExpanded;
  final EdgeInsets? padding;

  const PointsTransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.onAction,
    this.showBalance = true,
    this.showMultipliers = true,
    this.showSource = true,
    this.enableHaptics = true,
    this.isExpanded = false,
    this.padding,
  });

  @override
  State<PointsTransactionTile> createState() => _PointsTransactionTileState();
}

class _PointsTransactionTileState extends State<PointsTransactionTile>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _highlightController;
  late Animation<double> _slideAnimation;
  late Animation<double> _highlightAnimation;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    );

    _highlightAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _highlightController,
      curve: Curves.easeInOut,
    ));

    _slideController.forward();

    // Highlight recent transactions
    final isRecent = DateTime.now().difference(widget.transaction.timestamp).inMinutes < 5;
    if (isRecent) {
      Future.delayed(const Duration(milliseconds: 200), () {
        _highlightController.forward();
      });
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _highlightController.dispose();
    super.dispose();
  }

  Color _getTransactionColor(TransactionType type) {
    switch (type) {
      case TransactionType.earned:
        return Colors.green[600]!;
      case TransactionType.spent:
        return Colors.red[600]!;
      case TransactionType.bonus:
        return Colors.blue[600]!;
      case TransactionType.penalty:
        return Colors.red[700]!;
      case TransactionType.refund:
        return Colors.orange[600]!;
      case TransactionType.gift:
        return Colors.purple[600]!;
      case TransactionType.achievement:
        return Colors.amber[600]!;
      case TransactionType.daily:
        return Colors.teal[600]!;
      case TransactionType.challenge:
        return Colors.indigo[600]!;
      case TransactionType.referral:
        return Colors.pink[600]!;
    }
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.earned:
        return Icons.add_circle;
      case TransactionType.spent:
        return Icons.remove_circle;
      case TransactionType.bonus:
        return Icons.star;
      case TransactionType.penalty:
        return Icons.warning;
      case TransactionType.refund:
        return Icons.undo;
      case TransactionType.gift:
        return Icons.card_giftcard;
      case TransactionType.achievement:
        return Icons.emoji_events;
      case TransactionType.daily:
        return Icons.today;
      case TransactionType.challenge:
        return Icons.flag;
      case TransactionType.referral:
        return Icons.people;
    }
  }

  String _getTransactionTitle(TransactionType type) {
    switch (type) {
      case TransactionType.earned:
        return 'Points Earned';
      case TransactionType.spent:
        return 'Points Spent';
      case TransactionType.bonus:
        return 'Bonus Points';
      case TransactionType.penalty:
        return 'Point Penalty';
      case TransactionType.refund:
        return 'Points Refunded';
      case TransactionType.gift:
        return 'Gift Points';
      case TransactionType.achievement:
        return 'Achievement Reward';
      case TransactionType.daily:
        return 'Daily Bonus';
      case TransactionType.challenge:
        return 'Challenge Reward';
      case TransactionType.referral:
        return 'Referral Bonus';
    }
  }

  void _handleTap() {
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
    widget.onTap?.call();
  }

  void _handleExpansionToggle() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (widget.enableHaptics) {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactionColor = _getTransactionColor(widget.transaction.type);

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _slideAnimation.value)),
          child: Opacity(
            opacity: _slideAnimation.value,
            child: AnimatedBuilder(
              animation: _highlightAnimation,
              builder: (context, child) {
                return Container(
                  margin: widget.padding ?? const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _highlightAnimation.value > 0
                        ? transactionColor.withOpacity(0.1 * _highlightAnimation.value)
                        : null,
                    border: _highlightAnimation.value > 0
                        ? Border.all(
                            color: transactionColor.withOpacity(0.3 * _highlightAnimation.value),
                            width: 2,
                          )
                        : null,
                  ),
                  child: Card(
                    elevation: _highlightAnimation.value > 0 ? 4 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: _handleTap,
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        children: [
                          _buildMainRow(theme, transactionColor),
                          if (_isExpanded) _buildExpandedContent(theme, transactionColor),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainRow(ThemeData theme, Color transactionColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildTransactionIcon(transactionColor),
          const SizedBox(width: 12),
          Expanded(child: _buildTransactionInfo(theme)),
          const SizedBox(width: 8),
          _buildPointsDisplay(theme, transactionColor),
          if (widget.transaction.multipliers.isNotEmpty ||
              widget.showBalance ||
              widget.transaction.description.length > 50)
            IconButton(
              onPressed: _handleExpansionToggle,
              icon: Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionIcon(Color transactionColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: transactionColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _getTransactionIcon(widget.transaction.type),
        color: transactionColor,
        size: 24,
      ),
    );
  }

  Widget _buildTransactionInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.transaction.description.isNotEmpty
              ? widget.transaction.description
              : _getTransactionTitle(widget.transaction.type),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: _isExpanded ? null : 2,
          overflow: _isExpanded ? null : TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: 14,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              widget.transaction.timeAgo,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            if (widget.showSource && widget.transaction.sourceReference.isNotEmpty) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.link,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.transaction.sourceReference,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPointsDisplay(ThemeData theme, Color transactionColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          widget.transaction.formattedPoints,
          style: theme.textTheme.titleLarge?.copyWith(
            color: transactionColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (widget.showBalance) ...[
          const SizedBox(height: 2),
          Text(
            'Balance: ${widget.transaction.formattedBalance}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExpandedContent(ThemeData theme, Color transactionColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 12),
          
          if (widget.showMultipliers && widget.transaction.multipliers.isNotEmpty)
            _buildMultipliers(theme),
          
          if (widget.transaction.totalMultipliedPoints != widget.transaction.points) ...[
            const SizedBox(height: 12),
            _buildFinalCalculation(theme, transactionColor),
          ],
          
          if (widget.transaction.metadata != null && widget.transaction.metadata!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildMetadata(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildMultipliers(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Multipliers Applied',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: widget.transaction.multipliers.map((multiplier) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: multiplier.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: multiplier.color.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.close,
                    size: 12,
                    color: multiplier.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    multiplier.formattedValue,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: multiplier.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    multiplier.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: multiplier.color,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFinalCalculation(ThemeData theme, Color transactionColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: transactionColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: transactionColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Final Points',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.transaction.points != widget.transaction.totalMultipliedPoints) ...[
                Text(
                  widget.transaction.formattedPoints,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: transactionColor,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.transaction.isPositive 
                    ? '+${widget.transaction.totalMultipliedPoints}'
                    : '-${widget.transaction.totalMultipliedPoints.abs()}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: transactionColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Details',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...widget.transaction.metadata!.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    '${entry.key}:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.value.toString(),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}