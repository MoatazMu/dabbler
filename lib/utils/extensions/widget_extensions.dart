import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Extension methods for Widget manipulation
extension WidgetExtensions on Widget {
  /// Adds padding to all sides
  Widget pad([double value = AppConstants.defaultPadding]) {
    return Padding(
      padding: EdgeInsets.all(value),
    );
  }

  /// Adds horizontal and vertical padding
  Widget padSymmetric({
    double horizontal = AppConstants.defaultPadding,
    double vertical = AppConstants.defaultPadding,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontal,
        vertical: vertical,
      ),
      child: this,
    );
  }

  /// Adds padding only to specified sides
  Widget padOnly({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: left,
        top: top,
        right: right,
        bottom: bottom,
      ),
      child: this,
    );
  }

  /// Centers the widget
  Widget get center => Center(child: this);

  /// Expands the widget to fill available space
  Widget get expanded => Expanded(child: this);

  /// Makes the widget flexible
  Widget flexible({int flex = 1}) => Flexible(
        flex: flex,
        child: this,
      );

  /// Adds a tap handler to the widget
  Widget onTap(VoidCallback action) => GestureDetector(
        onTap: action,
        child: this,
      );

  /// Makes the widget dismissible
  Widget dismissible({
    required Key key,
    required DismissDirectionCallback onDismissed,
    Widget? background,
  }) {
    return Dismissible(
      key: key,
      onDismissed: onDismissed,
      background: background,
      child: this,
    );
  }

  /// Clips the widget with rounded corners
  Widget withRoundedCorners([double radius = AppConstants.defaultRadius]) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: this,
    );
  }

  /// Adds a border to the widget
  Widget withBorder({
    Color color = Colors.grey,
    double width = 1.0,
    double radius = AppConstants.defaultRadius,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: color,
          width: width,
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: this,
    );
  }

  /// Adds a shadow to the widget
  Widget withShadow({
    Color? shadowColor,
    double blurRadius = 8,
    Offset offset = const Offset(0, 4),
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: shadowColor ?? Colors.black.withOpacity(0.1),
            blurRadius: blurRadius,
            offset: offset,
          ),
        ],
      ),
      child: this,
    );
  }

  /// Makes the widget scrollable
  Widget scrollable({
    ScrollPhysics? physics,
    EdgeInsets? padding,
    Axis scrollDirection = Axis.vertical,
  }) {
    return SingleChildScrollView(
      physics: physics,
      padding: padding,
      scrollDirection: scrollDirection,
      child: this,
    );
  }

  /// Constrains the widget size
  Widget constrained({
    double? maxWidth,
    double? maxHeight,
    double? minWidth,
    double? minHeight,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? double.infinity,
        maxHeight: maxHeight ?? double.infinity,
        minWidth: minWidth ?? 0.0,
        minHeight: minHeight ?? 0.0,
      ),
      child: this,
    );
  }

  /// Shows/hides the widget based on a condition
  Widget visible(bool visible) {
    return Visibility(
      visible: visible,
      child: this,
    );
  }

  /// Shows a loading indicator while the widget is loading
  Widget loading(bool isLoading, {Widget? loadingWidget}) {
    return Stack(
      children: [
        this,
        if (isLoading)
          loadingWidget ??
              const Center(
                child: CircularProgressIndicator(),
              ),
      ],
    );
  }

  /// Makes the widget draggable
  Widget draggable<T extends Object>({
    required T data,
    Widget? feedback,
    Widget? childWhenDragging,
  }) {
    return Draggable<T>(
      data: data,
      feedback: feedback ?? this,
      childWhenDragging: childWhenDragging,
      child: this,
    );
  }

  /// Makes the widget a drop target
  Widget dropTarget<T extends Object>({
    required void Function(DragTargetDetails<T>) onAccept,
    DragTargetWillAcceptWithDetails<T>? onWillAccept,
  }) {
    return DragTarget<T>(
      onAcceptWithDetails: onAccept,
      onWillAcceptWithDetails: onWillAccept,
      builder: (context, candidateData, rejectedData) => this,
    );
  }
}
