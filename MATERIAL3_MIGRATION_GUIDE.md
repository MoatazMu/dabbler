import 'package:flutter/material.dart';

/// Migration Guide: Custom Design System → Native Material 3
///
/// ## Replaced Components
///
/// ### Buttons
/// **OLD (Custom):**
/// ```dart
/// AppButton.primary(
///   label: 'Submit',
///   onPressed: () {},
///   size: AppButtonSize.lg,
/// )
/// ```
///
/// **NEW (Material 3):**
/// ```dart
/// // Filled button (primary)
/// FilledButton(
///   onPressed: () {},
///   child: Text('Submit'),
/// )
///
/// // With icon
/// FilledButton.icon(
///   onPressed: () {},
///   icon: Icon(Icons.add),
///   label: Text('Add'),
/// )
///
/// // Outlined button
/// OutlinedButton(onPressed: () {}, child: Text('Cancel'))
///
/// // Text button (ghost)
/// TextButton(onPressed: () {}, child: Text('Skip'))
///
/// // Elevated button
/// ElevatedButton(onPressed: () {}, child: Text('Save'))
/// ```
///
/// ### Cards
/// **OLD (Custom):**
/// ```dart
/// AppCard(
///   child: Text('Content'),
///   padding: EdgeInsets.all(16),
/// )
/// ```
///
/// **NEW (Material 3):**
/// ```dart
/// // Filled card (default)
/// Card.filled(
///   child: Padding(
///     padding: EdgeInsets.all(16),
///     child: Text('Content'),
///   ),
/// )
///
/// // Outlined card
/// Card.outlined(
///   child: ListTile(
///     title: Text('Title'),
///     subtitle: Text('Subtitle'),
///   ),
/// )
///
/// // Elevated card (deprecated in M3, use filled)
/// Card(child: Text('Content'))
/// ```
///
/// ### Input Fields
/// **OLD (Custom):**
/// ```dart
/// AppInputField(
///   label: 'Email',
///   hintText: 'Enter email',
///   controller: controller,
/// )
/// ```
///
/// **NEW (Material 3):**
/// ```dart
/// // TextField for simple input
/// TextField(
///   controller: controller,
///   decoration: InputDecoration(
///     labelText: 'Email',
///     hintText: 'Enter email',
///   ),
/// )
///
/// // TextFormField for forms with validation
/// TextFormField(
///   controller: controller,
///   decoration: InputDecoration(labelText: 'Email'),
///   validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
/// )
/// ```
///
/// ### Chips
/// **OLD (Custom):**
/// ```dart
/// AppChip(label: 'Filter', onPressed: () {})
/// ```
///
/// **NEW (Material 3):**
/// ```dart
/// // Filter chip
/// FilterChip(
///   label: Text('Filter'),
///   selected: isSelected,
///   onSelected: (value) {},
/// )
///
/// // Action chip
/// ActionChip(
///   label: Text('Action'),
///   onPressed: () {},
/// )
///
/// // Input chip (for tags)
/// InputChip(
///   label: Text('Tag'),
///   onDeleted: () {},
/// )
/// ```
///
/// ## Color Tokens Integration
///
/// ### Accessing Category Colors
/// ```dart
/// // In widgets
/// final colorScheme = Theme.of(context).colorScheme;
///
/// // Main category (purple)
/// Container(color: colorScheme.categoryMain)
///
/// // Social category (blue)
/// Container(color: colorScheme.categorySocial)
///
/// // Sports category (green)
/// Container(color: colorScheme.categorySports)
///
/// // Activities category (pink)
/// Container(color: colorScheme.categoryActivities)
///
/// // Profile category (orange)
/// Container(color: colorScheme.categoryProfile)
///
/// // Semantic colors
/// Text('Success', style: TextStyle(color: colorScheme.success))
/// Text('Warning', style: TextStyle(color: colorScheme.warning))
/// Text('Error', style: TextStyle(color: colorScheme.error))
/// ```
///
/// ### Using Theme Tokens
/// ```dart
/// // Get category-specific tokens
/// final tokens = context.colorTokens; // Main tokens
/// final socialTokens = context.getCategoryTokens('social');
///
/// // Use token colors
/// Container(
///   color: tokens.header,      // Header background
///   child: Text(
///     'Title',
///     style: TextStyle(color: tokens.titleOnHead),
///   ),
/// )
///
/// Button(
///   style: ButtonStyle(
///     backgroundColor: WidgetStateProperty.all(tokens.button),
///     foregroundColor: WidgetStateProperty.all(tokens.onBtn),
///   ),
/// )
/// ```
///
/// ## Theme Customization
///
/// ### Override Button Styles
/// ```dart
/// FilledButton(
///   onPressed: () {},
///   style: FilledButton.styleFrom(
///     backgroundColor: colorScheme.categorySports,
///     foregroundColor: Colors.white,
///     padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
///     shape: RoundedRectangleBorder(
///       borderRadius: BorderRadius.circular(12),
///     ),
///   ),
///   child: Text('Custom'),
/// )
/// ```
///
/// ### Override Card Styles
/// ```dart
/// Card.filled(
///   color: colorScheme.primaryContainer,
///   child: ListTile(
///     titleTextStyle: TextStyle(color: colorScheme.onPrimaryContainer),
///     title: Text('Custom Card'),
///   ),
/// )
/// ```
///
/// ### Override Input Styles
/// ```dart
/// TextField(
///   decoration: InputDecoration(
///     labelText: 'Custom',
///     filled: true,
///     fillColor: colorScheme.surfaceContainer,
///     border: OutlineInputBorder(
///       borderRadius: BorderRadius.circular(12),
///     ),
///     focusedBorder: OutlineInputBorder(
///       borderRadius: BorderRadius.circular(12),
///       borderSide: BorderSide(
///         color: colorScheme.categorySocial,
///         width: 2,
///       ),
///     ),
///   ),
/// )
/// ```
///
/// ## Migration Checklist
///
/// - [ ] Replace AppButton → FilledButton/OutlinedButton/TextButton
/// - [ ] Replace AppCard → Card.filled/Card.outlined
/// - [ ] Replace AppInputField → TextField/TextFormField
/// - [ ] Replace AppChip → FilterChip/ActionChip/InputChip
/// - [ ] Update color references to use colorScheme.categoryX
/// - [ ] Update token access to use context.colorTokens
/// - [ ] Test all UI components in light and dark mode
/// - [ ] Verify accessibility (contrast ratios, touch targets)
/// - [ ] Update documentation and examples
///
/// ## Benefits
///
/// ✅ Native Material 3 components with full platform support
/// ✅ Better accessibility out of the box
/// ✅ Consistent with Material Design guidelines
/// ✅ Automatic theme adaptation (light/dark mode)
/// ✅ Smaller codebase (less custom code to maintain)
/// ✅ Better performance (optimized native widgets)
/// ✅ Preserved custom color tokens for brand identity
