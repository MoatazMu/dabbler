import 'package:flutter/material.dart';

/// Generic infinite scroll list widget with pagination support
class InfiniteScrollList<T> extends StatefulWidget {
  /// Items to display in the list
  final List<T> items;
  
  /// Function to build each list item
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  
  /// Function called when more items need to be loaded
  final Future<void> Function()? onLoadMore;
  
  /// Whether more items can be loaded
  final bool hasMore;
  
  /// Whether currently loading more items
  final bool isLoadingMore;
  
  /// Error that occurred during loading
  final String? loadingError;
  
  /// Function called when retry is tapped
  final VoidCallback? onRetry;
  
  /// Widget to show when list is empty
  final Widget? emptyWidget;
  
  /// Distance from bottom to trigger loading
  final double loadingTriggerOffset;
  
  /// Loading indicator widget
  final Widget? loadingIndicator;
  
  /// Error widget builder
  final Widget Function(String error, VoidCallback? onRetry)? errorBuilder;

  const InfiniteScrollList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onLoadMore,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.loadingError,
    this.onRetry,
    this.emptyWidget,
    this.loadingTriggerOffset = 200.0,
    this.loadingIndicator,
    this.errorBuilder,
  });

  @override
  State<InfiniteScrollList<T>> createState() => _InfiniteScrollListState<T>();
}

class _InfiniteScrollListState<T> extends State<InfiniteScrollList<T>> {
  late ScrollController _scrollController;
  bool _isLoadingTriggered = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - widget.loadingTriggerOffset) {
      _triggerLoadMore();
    }
  }

  void _triggerLoadMore() {
    if (!_isLoadingTriggered &&
        widget.hasMore &&
        !widget.isLoadingMore &&
        widget.loadingError == null &&
        widget.onLoadMore != null) {
      _isLoadingTriggered = true;
      widget.onLoadMore!().whenComplete(() {
        _isLoadingTriggered = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show empty widget if no items
    if (widget.items.isEmpty && !widget.isLoadingMore) {
      return widget.emptyWidget ?? const _DefaultEmptyWidget();
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.items.length + (widget.hasMore || widget.isLoadingMore || widget.loadingError != null ? 1 : 0),
      itemBuilder: (context, index) {
        // Regular item
        if (index < widget.items.length) {
          return widget.itemBuilder(context, widget.items[index], index);
        }

        // Loading/error footer
        return _buildFooter();
      },
    );
  }

  Widget _buildFooter() {
    // Show error state
    if (widget.loadingError != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(widget.loadingError!, widget.onRetry);
      }
      return _DefaultErrorWidget(
        error: widget.loadingError!,
        onRetry: widget.onRetry,
      );
    }

    // Show loading state
    if (widget.isLoadingMore) {
      return widget.loadingIndicator ?? const _DefaultLoadingWidget();
    }

    // No more items
    return const SizedBox.shrink();
  }
}

/// Default loading indicator
class _DefaultLoadingWidget extends StatelessWidget {
  const _DefaultLoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// Default error widget
class _DefaultErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const _DefaultErrorWidget({
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: theme.colorScheme.error,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Failed to load more',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            error,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Default empty widget
class _DefaultEmptyWidget extends StatelessWidget {
  const _DefaultEmptyWidget();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No items found',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no items to display.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading more indicator that can be used separately
class LoadingMoreIndicator extends StatelessWidget {
  final bool isVisible;
  final String message;

  const LoadingMoreIndicator({
    super.key,
    this.isVisible = true,
    this.message = 'Loading more...',
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pagination controls widget
class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final Function(int page)? onPageSelected;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.hasNext = false,
    this.hasPrevious = false,
    this.onNext,
    this.onPrevious,
    this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          TextButton.icon(
            onPressed: hasPrevious ? onPrevious : null,
            icon: const Icon(Icons.chevron_left_rounded),
            label: const Text('Previous'),
          ),
          
          // Page indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Page $currentPage of $totalPages',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          // Next button
          TextButton.icon(
            onPressed: hasNext ? onNext : null,
            label: const Text('Next'),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

/// Pull to refresh wrapper
class PullToRefreshList<T> extends StatelessWidget {
  final List<T> items;
  final IndexedWidgetBuilder itemBuilder;
  final Future<void> Function() onRefresh;
  final Widget? emptyWidget;
  final bool isRefreshing;

  const PullToRefreshList({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onRefresh,
    this.emptyWidget,
    this.isRefreshing = false,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && !isRefreshing) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: emptyWidget ?? const _DefaultEmptyWidget(),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) => itemBuilder(context, index),
      ),
    );
  }
}
