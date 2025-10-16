import 'package:flutter/material.dart';

class A11y {
  // Semantic wrappers
  static Widget button({
    required String label,
    required Widget child,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: child,
    );
  }

  static Widget image({
    required String label,
    required Widget child,
  }) {
    return Semantics(
      image: true,
      label: label,
      child: child,
    );
  }

  static Widget liveRegion({
    required String label,
    required Widget child,
    bool assertive = false,
  }) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: label,
      child: ExcludeSemantics(
        excluding: !assertive,
        child: child,
      ),
    );
  }

  // Focus helpers
  static void moveFocusTo(BuildContext context, FocusNode node) {
    FocusScope.of(context).requestFocus(node);
  }

  static FocusTraversalGroup keyboardTraversal({required Widget child}) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: child,
    );
  }
}
