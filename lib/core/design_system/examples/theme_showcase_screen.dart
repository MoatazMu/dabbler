import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:dabbler/core/design_system/design_system.dart';

/// Complete Design System Showcase
/// Demonstrates:
/// - All 10 theme modes with design tokens
/// - Material Design 3 components (Button, Label, Chip, Tab)
/// - Typography, spacing, colors, and design tokens
class ThemeShowcaseScreen extends StatefulWidget {
  const ThemeShowcaseScreen({super.key});

  @override
  State<ThemeShowcaseScreen> createState() => _ThemeShowcaseScreenState();
}

class _ThemeShowcaseScreenState extends State<ThemeShowcaseScreen> {
  AppThemeMode _selectedTheme = AppThemeMode.mainLight;
  int _selectedChipIndex = 0;
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final themeData = TokenBasedTheme.build(_selectedTheme);

    return Theme(
      data: themeData,
      child: Scaffold(
        backgroundColor: themeData.colorScheme.surface,
        appBar: AppBar(
          title: Text(
            'Design System Showcase',
            style: themeData.textTheme.titleLarge,
          ),
        ),
        body: Column(
          children: [
            // Theme selector
            _buildThemeSelector(themeData),

            // Theme preview
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildThemePreview(themeData),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Theme Mode', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppThemeMode.values.map((mode) {
              final isSelected = _selectedTheme == mode;
              return ChoiceChip(
                label: Text(mode.name),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedTheme = mode);
                  }
                },
                selectedColor: theme.colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildThemePreview(ThemeData theme) {
    final tokens = _selectedTheme.colorTokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overview
        _buildSection('Design System Components', theme, [
          const Text(
            'Local Components (Material Design 3 Foundation)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '• AppButton - Buttons with 5 styles and 3 sizes\n'
            '• AppLabel - Labels/badges with pill shape\n'
            '• AppChip - Chips for filtering and selection\n'
            '• AppTab - Tab navigation components\n'
            '• AppCard - Card components for content\n'
            '• DSAvatar - Avatar components\n'
            '• AppSportIcon - Sport-specific icons\n'
            '• AppInputField - Form input fields\n'
            '• AppSearchInput - Search input component\n'
            '• AppProgressIndicator - Progress indicators\n'
            '• AppSteps - Step indicators\n'
            '• UpcomingGameCard - Game card component\n'
            '• InteractiveCardStack - Swipeable card stack',
            style: TextStyle(fontSize: 12, height: 1.8),
          ),
        ]),

        const SizedBox(height: 24),

        // Color Tokens
        _buildSection('Color Tokens', theme, [
          _buildColorRow('Header', tokens.header, theme),
          _buildColorRow('Section', tokens.section, theme),
          _buildColorRow('Button', tokens.button, theme),
          _buildColorRow('Button Base', tokens.btnBase, theme),
          _buildColorRow('Tab Active', tokens.tabActive, theme),
          _buildColorRow('Card', tokens.card, theme),
          _buildColorRow('Stroke', tokens.stroke, theme),
          _buildColorRow('Neutral', tokens.neutral, theme),
          _buildColorRow('On Button', tokens.onBtn, theme),
        ]),

        const SizedBox(height: 16),

        // Button Color Mapping
        _buildSection('Button Token Mapping', theme, [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'colors/brand/button → tokens.button',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                _buildColorRow('Filled Background', tokens.button, theme),
                const SizedBox(height: 8),
                Text(
                  'colors/brand/on-btn → tokens.onBtn',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                _buildColorRow('Filled Text/Icon', tokens.onBtn, theme),
                const SizedBox(height: 8),
                Text(
                  'colors/brand/on-btn-icon → tokens.onBtnIcon',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                _buildColorRow('Icon Color', tokens.onBtnIcon, theme),
                const SizedBox(height: 8),
                Text(
                  'colors/brand/stroke → tokens.stroke (button @ 18%)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                _buildColorRow('Outlined Border', tokens.stroke, theme),
                const SizedBox(height: 8),
                Text(
                  'colors/brand/neutral → tokens.neutral (#1A1A1A @ 92%)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                _buildColorRow('Ghost Text', tokens.neutral, theme),
              ],
            ),
          ),
        ]),

        const SizedBox(height: 24),

        // Typography - All 17 Figma Styles
        _buildSection('Typography (17 Figma Styles)', theme, [
          const Text(
            'Display Styles:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Display Large (36px, Bold)',
            style: theme.textTheme.displayLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Display Medium (30px, SemiBold)',
            style: theme.textTheme.displayMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Display Small (24px, Regular)',
            style: theme.textTheme.displaySmall,
          ),
          const SizedBox(height: 16),

          const Text(
            'Headline Styles:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Headline Large (24px, Bold)',
            style: theme.textTheme.headlineLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Headline Medium (21px, Medium)',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Headline Small (19px, Bold)',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          const Text(
            'Title Styles:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Title Large (21px, Bold)', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Title Medium (19px, Regular)',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Title Small (17px, Regular)',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 16),

          const Text(
            'Body Styles:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Body Large (17px, Regular)', style: theme.textTheme.bodyLarge),
          const SizedBox(height: 4),
          Text(
            'Body Medium (15px, Regular)',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text('Body Small (12px, Regular)', style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),

          const Text(
            'Label Styles:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Label Large (17px, Bold)', style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(
            'Label Medium (15px, SemiBold)',
            style: theme.textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Label Small (12px, Regular)',
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(height: 16),

          const Text(
            'Caption Styles:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Caption Default (12px, Regular)', style: AppTypography.caption),
          const SizedBox(height: 4),
          Text(
            'CAPTION FOOTNOTE (9PX, LIGHT)'.toUpperCase(),
            style: AppTypography.captionFootnote,
          ),
        ]),

        const SizedBox(height: 24),

        // AppButton Component - Material Design 3 Foundation (5 styles × 3 sizes × 4 icon configs)
        _buildSection('AppButton (Material Design 3 - 60 Variants)', theme, [
          const Text(
            'Material Design 3 Foundation: FilledButton, OutlinedButton, TextButton',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            '5 Button Styles: Filled, Outline, Ghost, Ghost-Outline, Subtle',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            '3 Sizes: Small (24px), Default (36px), Large (48px)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Small Size (24px height)
          Text('Small Size (24px)', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),

          // Filled buttons
          const Text('Filled:', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton.primary(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.sm,
              ),
              AppButton.primary(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.sm,
                leftIcon: const Icon(Iconsax.add_copy),
              ),
              AppButton.primary(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.sm,
                rightIcon: const Icon(Iconsax.arrow_right_copy),
              ),
              AppButton.primary(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.sm,
                leftIcon: const Icon(Iconsax.add_copy),
                rightIcon: const Icon(Iconsax.arrow_right_copy),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Text('Outlined:', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton.outlined(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.sm,
              ),
              AppButton.outlined(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.sm,
                leftIcon: const Icon(Iconsax.add_copy),
              ),
              AppButton.outlined(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.sm,
                rightIcon: const Icon(Iconsax.arrow_right_copy),
              ),
              AppButton.outlined(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.sm,
                leftIcon: const Icon(Iconsax.add_copy),
                rightIcon: const Icon(Iconsax.arrow_right_copy),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Text('Ghost:', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton.ghost(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.sm,
              ),
              AppButton.ghost(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.sm,
                leftIcon: const Icon(Iconsax.add_copy),
              ),
              AppButton.ghost(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.sm,
                rightIcon: const Icon(Iconsax.arrow_right_copy),
              ),
              AppButton.ghost(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.sm,
                leftIcon: const Icon(Iconsax.add_copy),
                rightIcon: const Icon(Iconsax.arrow_right_copy),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Text('Ghost Outline:', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton.ghostOutline(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.sm,
              ),
              AppButton.ghostOutline(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.sm,
                leftIcon: const Icon(Iconsax.add_copy),
              ),
              AppButton.ghostOutline(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.sm,
                rightIcon: const Icon(Iconsax.arrow_right_copy),
              ),
              AppButton.ghostOutline(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.sm,
                leftIcon: const Icon(Iconsax.add_copy),
                rightIcon: const Icon(Iconsax.arrow_right_copy),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Text('Subtle:', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton.subtle(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.sm,
              ),
              AppButton.subtle(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.sm,
                leftIcon: const Icon(Iconsax.add_copy),
              ),
              AppButton.subtle(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.sm,
                rightIcon: const Icon(Iconsax.arrow_right_copy),
              ),
              AppButton.subtle(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.sm,
                leftIcon: const Icon(Iconsax.add_copy),
                rightIcon: const Icon(Iconsax.arrow_right_copy),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Default Size (36px height)
          Text('Default Size (36px)', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),

          const Text('Filled:', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton.primary(label: 'Continue', onPressed: () {}),
              AppButton.primary(
                label: 'Continue',
                onPressed: () {},
                leftIcon: const Icon(Iconsax.add_copy),
              ),
              AppButton.primary(
                label: 'Continue',
                onPressed: () {},
                rightIcon: const Icon(Iconsax.arrow_right_copy),
              ),
              AppButton.primary(
                label: 'Continue',
                onPressed: () {},
                leftIcon: const Icon(Iconsax.add_copy),
                rightIcon: const Icon(Iconsax.arrow_right_copy),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Text('Outlined:', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton.outlined(label: 'Continue', onPressed: () {}),
              AppButton.outlined(
                label: 'Continue',
                onPressed: () {},
                leftIcon: const Icon(Iconsax.add_copy),
              ),
              AppButton.outlined(
                label: 'Continue',
                onPressed: () {},
                rightIcon: const Icon(Iconsax.arrow_right_copy),
              ),
              AppButton.outlined(
                label: 'Continue',
                onPressed: () {},
                leftIcon: const Icon(Iconsax.add_copy),
                rightIcon: const Icon(Iconsax.arrow_right_copy),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Text('Ghost:', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton.ghost(label: 'Continue', onPressed: () {}),
              AppButton.ghost(
                label: 'Continue',
                onPressed: () {},
                leftIcon: const Icon(Iconsax.add_copy),
              ),
              AppButton.ghost(
                label: 'Continue',
                onPressed: () {},
                rightIcon: const Icon(Iconsax.arrow_right_copy),
              ),
              AppButton.ghost(
                label: 'Continue',
                onPressed: () {},
                leftIcon: const Icon(Iconsax.add_copy),
                rightIcon: const Icon(Iconsax.arrow_right_copy),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Text('Ghost Outline:', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton.ghostOutline(label: 'Continue', onPressed: () {}),
              AppButton.ghostOutline(
                label: 'Continue',
                onPressed: () {},
                leftIcon: const Icon(Iconsax.add_copy),
              ),
              AppButton.ghostOutline(
                label: 'Continue',
                onPressed: () {},
                rightIcon: const Icon(Iconsax.arrow_right_copy),
              ),
              AppButton.ghostOutline(
                label: 'Continue',
                onPressed: () {},
                leftIcon: const Icon(Iconsax.add_copy),
                rightIcon: const Icon(Iconsax.arrow_right_copy),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Text('Subtle:', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton.subtle(label: 'Continue', onPressed: () {}),
              AppButton.subtle(
                label: 'Continue',
                onPressed: () {},
                leftIcon: const Icon(Iconsax.add_copy),
              ),
              AppButton.subtle(
                label: 'Continue',
                onPressed: () {},
                rightIcon: const Icon(Iconsax.arrow_right_copy),
              ),
              AppButton.subtle(
                label: 'Continue',
                onPressed: () {},
                leftIcon: const Icon(Iconsax.add_copy),
                rightIcon: const Icon(Iconsax.arrow_right_copy),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Large Size (48px height)
          Text('Large Size (48px)', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),

          const Text('Filled:', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton.primary(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.lg,
              ),
              AppButton.primary(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.lg,
                leftIcon: const Icon(Iconsax.add_copy),
              ),
              AppButton.primary(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.lg,
                rightIcon: const Icon(Iconsax.arrow_right_copy),
              ),
              AppButton.primary(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.lg,
                leftIcon: const Icon(Iconsax.add_copy),
                rightIcon: const Icon(Iconsax.arrow_right_copy),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Text('Outlined:', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton.outlined(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.lg,
              ),
              AppButton.outlined(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.lg,
                leftIcon: const Icon(Iconsax.add_copy),
              ),
              AppButton.outlined(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.lg,
                rightIcon: const Icon(Iconsax.arrow_right_copy),
              ),
              AppButton.outlined(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.lg,
                leftIcon: const Icon(Iconsax.add_copy),
                rightIcon: const Icon(Iconsax.arrow_right_copy),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Text('Ghost:', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton.ghost(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.lg,
              ),
              AppButton.ghost(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.lg,
                leftIcon: const Icon(Iconsax.add_copy),
              ),
              AppButton.ghost(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.lg,
                rightIcon: const Icon(Iconsax.arrow_right_copy),
              ),
              AppButton.ghost(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.lg,
                leftIcon: const Icon(Iconsax.add_copy),
                rightIcon: const Icon(Iconsax.arrow_right_copy),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Text('Ghost Outline:', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton.ghostOutline(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.lg,
              ),
              AppButton.ghostOutline(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.lg,
                leftIcon: const Icon(Iconsax.add_copy),
              ),
              AppButton.ghostOutline(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.lg,
                rightIcon: const Icon(Iconsax.arrow_right_copy),
              ),
              AppButton.ghostOutline(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.lg,
                leftIcon: const Icon(Iconsax.add_copy),
                rightIcon: const Icon(Iconsax.arrow_right_copy),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Text('Subtle:', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton.subtle(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.lg,
              ),
              AppButton.subtle(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.lg,
                leftIcon: const Icon(Iconsax.add_copy),
              ),
              AppButton.subtle(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.lg,
                rightIcon: const Icon(Iconsax.arrow_right_copy),
              ),
              AppButton.subtle(
                label: 'Continue',
                onPressed: () {},
                size: AppButtonSize.lg,
                leftIcon: const Icon(Iconsax.add_copy),
                rightIcon: const Icon(Iconsax.arrow_right_copy),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          // Disabled State Example
          Text(
            'Disabled State (All 5 Styles):',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton.primary(label: 'Disabled', onPressed: null),
              AppButton.outlined(label: 'Disabled', onPressed: null),
              AppButton.ghost(label: 'Disabled', onPressed: null),
              AppButton.ghostOutline(label: 'Disabled', onPressed: null),
              AppButton.subtle(label: 'Disabled', onPressed: null),
            ],
          ),
        ]),

        const SizedBox(height: 24),

        // AppLabel
        _buildSection('AppLabel (Material Design 3 Chip Foundation)', theme, [
          const Text(
            'Small Size (20px):',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppLabel.filled(text: 'Continue', size: AppLabelSize.sm),
              AppLabel.filled(
                text: 'Continue',
                size: AppLabelSize.sm,
                leftIcon: const Icon(Iconsax.add_copy),
              ),
              AppLabel.filled(
                text: 'Continue',
                size: AppLabelSize.sm,
                rightIcon: const Icon(Iconsax.arrow_right_copy),
              ),
              AppLabel.outline(text: 'Continue', size: AppLabelSize.sm),
              AppLabel.subtle(
                text: 'Continue',
                size: AppLabelSize.sm,
                leftIcon: const Icon(Iconsax.star_copy),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Default Size (24px):',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppLabel.filled(text: 'Continue'),
              AppLabel.filled(
                text: 'Continue',
                leftIcon: const Icon(Iconsax.add_copy),
              ),
              AppLabel.filled(
                text: 'Continue',
                rightIcon: const Icon(Iconsax.arrow_right_copy),
              ),
              AppLabel.outline(text: 'Continue'),
              AppLabel.subtle(
                text: 'Continue',
                leftIcon: const Icon(Iconsax.star_copy),
                rightIcon: const Icon(Iconsax.tick_circle_copy),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Large Size (30px):',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppLabel.filled(text: 'Continue', size: AppLabelSize.lg),
              AppLabel.filled(
                text: 'Continue',
                size: AppLabelSize.lg,
                leftIcon: const Icon(Iconsax.add_copy),
              ),
              AppLabel.filled(
                text: 'Continue',
                size: AppLabelSize.lg,
                rightIcon: const Icon(Iconsax.arrow_right_copy),
              ),
              AppLabel.outline(text: 'Continue', size: AppLabelSize.lg),
              AppLabel.subtle(
                text: 'Continue',
                size: AppLabelSize.lg,
                leftIcon: const Icon(Iconsax.star_copy),
              ),
            ],
          ),
        ]),

        const SizedBox(height: 24),

        // Figma Components - AppChip
        _buildSection(
          'AppChip (Material Design 3 FilterChip/ChoiceChip)',
          theme,
          [
            const Text('Default Size:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                AppChip(
                  label: 'All',
                  isActive: _selectedChipIndex == 0,
                  onTap: () => setState(() => _selectedChipIndex = 0),
                ),
                AppChip(
                  label: 'Football',
                  isActive: _selectedChipIndex == 1,
                  icon: const Icon(Iconsax.ticket_2_copy),
                  onTap: () => setState(() => _selectedChipIndex = 1),
                ),
                AppChip(
                  label: 'Basketball',
                  isActive: _selectedChipIndex == 2,
                  counter: '12',
                  onTap: () => setState(() => _selectedChipIndex = 2),
                ),
                AppChip(
                  label: 'Cricket',
                  isActive: _selectedChipIndex == 3,
                  icon: const Icon(Iconsax.game_copy),
                  counter: '5',
                  onTap: () => setState(() => _selectedChipIndex = 3),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Small Size:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                AppChip(
                  label: 'Filter 1',
                  isSmall: true,
                  isActive: _selectedChipIndex == 4,
                  onTap: () => setState(() => _selectedChipIndex = 4),
                ),
                AppChip(
                  label: 'Filter 2',
                  isSmall: true,
                  isActive: _selectedChipIndex == 5,
                  icon: const Icon(Iconsax.filter_copy),
                  onTap: () => setState(() => _selectedChipIndex = 5),
                ),
                AppChip(
                  label: 'Filter 3',
                  isSmall: true,
                  isActive: _selectedChipIndex == 6,
                  counter: '8',
                  onTap: () => setState(() => _selectedChipIndex = 6),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Figma Components - AppTab
        _buildSection('AppTab (Material Design 3 TabBar Foundation)', theme, [
          const Text('Tab Bar (Horizontal):'),
          const SizedBox(height: 8),
          AppTabBar(
            tabs: [
              AppTab(label: 'All', counter: 24),
              AppTab(label: 'Active', counter: 5),
              AppTab(label: 'Completed', counter: 19),
              AppTab(label: 'Upcoming'),
            ],
            selectedIndex: _selectedTabIndex,
            onTabSelected: (index) => setState(() => _selectedTabIndex = index),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          const Text('Individual Tabs:'),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTab(
                label: 'Home',
                isActive: _selectedTabIndex == 0,
                onTap: () => setState(() => _selectedTabIndex = 0),
              ),
              const SizedBox(height: 8),
              AppTab(
                label: 'Explore',
                isActive: _selectedTabIndex == 1,
                icon: const Icon(Iconsax.search_normal_copy),
                onTap: () => setState(() => _selectedTabIndex = 1),
              ),
              const SizedBox(height: 8),
              AppTab(
                label: 'Notifications',
                isActive: _selectedTabIndex == 2,
                counter: 12,
                onTap: () => setState(() => _selectedTabIndex = 2),
              ),
            ],
          ),
        ]),

        const SizedBox(height: 24),

        // Avatar Component
        _buildSection('DSAvatar (Theme-Aware)', theme, [
          const Text('Avatar Sizes:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16.0,
            runSpacing: 16.0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                children: [
                  DSAvatar.size24(initials: 'JD'),
                  const SizedBox(height: 4),
                  Text('24px', style: theme.textTheme.labelSmall),
                ],
              ),
              Column(
                children: [
                  DSAvatar.size30(
                    initials: 'AB',
                    sportIcon: AppSportIcon.size12(emoji: '🏀'),
                  ),
                  const SizedBox(height: 4),
                  Text('30px', style: theme.textTheme.labelSmall),
                ],
              ),
              Column(
                children: [
                  DSAvatar.size42(
                    initials: 'CD',
                    sportIcon: AppSportIcon.size18(emoji: '🎾'),
                  ),
                  const SizedBox(height: 4),
                  Text('42px', style: theme.textTheme.labelSmall),
                ],
              ),
              Column(
                children: [
                  DSAvatar.size48(
                    initials: 'EF',
                    sportIcon: AppSportIcon.size18(emoji: '⚽️'),
                  ),
                  const SizedBox(height: 4),
                  Text('48px', style: theme.textTheme.labelSmall),
                ],
              ),
              Column(
                children: [
                  DSAvatar.size54(initials: 'GH'),
                  const SizedBox(height: 4),
                  Text('54px', style: theme.textTheme.labelSmall),
                ],
              ),
            ],
          ),
        ]),

        const SizedBox(height: 24),

        // Sport Icon Component
        _buildSection('AppSportIcon (Theme-Aware)', theme, [
          const Text('Sport Icon Sizes:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16.0,
            runSpacing: 16.0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                children: [
                  AppSportIcon.size12(emoji: '🏀'),
                  const SizedBox(height: 4),
                  Text('12px', style: theme.textTheme.labelSmall),
                ],
              ),
              Column(
                children: [
                  AppSportIcon.size18(emoji: '🎾'),
                  const SizedBox(height: 4),
                  Text('18px', style: theme.textTheme.labelSmall),
                ],
              ),
              Column(
                children: [
                  AppSportIcon.size24(emoji: '⚽️'),
                  const SizedBox(height: 4),
                  Text('24px', style: theme.textTheme.labelSmall),
                ],
              ),
              Column(
                children: [
                  AppSportIcon.size30(emoji: '🏈'),
                  const SizedBox(height: 4),
                  Text('30px', style: theme.textTheme.labelSmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Different Sports:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12.0,
            runSpacing: 12.0,
            children: [
              AppSportIcon.size24(emoji: '🏀'),
              AppSportIcon.size24(emoji: '🎾'),
              AppSportIcon.size24(emoji: '⚽️'),
              AppSportIcon.size24(emoji: '🏈'),
              AppSportIcon.size24(emoji: '🏐'),
              AppSportIcon.size24(emoji: '🏏'),
              AppSportIcon.size24(emoji: '⚾️'),
              AppSportIcon.size24(emoji: '🏒'),
            ],
          ),
        ]),

        const SizedBox(height: 24),

        // Upcoming Game Card Component
        _buildSection('UpcomingGameCard (Figma Design)', theme, [
          const Text('Collapsed View:'),
          const SizedBox(height: 8),
          UpcomingGameCard.collapsed(
            title: 'Upcoming Game',
            gameName: 'Football Game',
            timeRemaining: '0h 45m',
            sportIcon: AppSportIcon.size18(emoji: '⚽️'),
            borderRadiusVariant: BorderRadiusVariant.all,
          ),
          const SizedBox(height: 12),
          const Text('Collapsed - Bottom Corners Only:'),
          const SizedBox(height: 8),
          UpcomingGameCard.collapsed(
            title: 'Upcoming Game',
            gameName: 'Basketball Match',
            timeRemaining: '1h 30m',
            sportIcon: AppSportIcon.size18(emoji: '🏀'),
            borderRadiusVariant: BorderRadiusVariant.bottomOnly,
          ),
          const SizedBox(height: 16),
          const Text('Expanded View (Full Details):'),
          const SizedBox(height: 8),
          UpcomingGameCard.expanded(
            title: 'Upcoming Game',
            gameName: 'Football Game',
            timeRemaining: '0h 45m',
            sportIcon: AppSportIcon.size18(emoji: '⚽️'),
            dateTime: 'Mon, Dec 1 - 6:00 PM - 8:00 PM',
            location: 'Downtown Sports Center',
            borderRadiusVariant: BorderRadiusVariant.all,
          ),
          const SizedBox(height: 12),
          const Text('Expanded - Top Corners Only:'),
          const SizedBox(height: 8),
          UpcomingGameCard.expanded(
            title: 'Next Match',
            gameName: 'Tennis Tournament',
            timeRemaining: '2h 15m',
            sportIcon: AppSportIcon.size18(emoji: '🎾'),
            dateTime: 'Wed, Dec 3 - 5:00 PM - 7:00 PM',
            location: 'Tennis Club',
            borderRadiusVariant: BorderRadiusVariant.topOnly,
          ),
          const SizedBox(height: 12),
          const Text('Interactive Stack (Tap to expand/collapse):'),
          const SizedBox(height: 8),
          const InteractiveCardStack(
            cards: [
              StackCardData(
                title: 'Upcoming Game',
                sportIcon: AppSportIcon.size18(emoji: '⚽️'),
                gameName: 'Football Game',
                timeRemaining: '0h 45m',
                dateTime: 'Mon, Dec 1 - 6:00 PM - 8:00 PM',
                location: 'Downtown Sports Center',
              ),
              StackCardData(
                title: 'Upcoming Game',
                sportIcon: AppSportIcon.size18(emoji: '🏀'),
                gameName: 'Basketball Match',
                timeRemaining: '2h 15m',
                dateTime: 'Tue, Dec 2 - 7:00 PM - 9:00 PM',
                location: 'Central Arena',
              ),
              StackCardData(
                title: 'Upcoming Game',
                sportIcon: AppSportIcon.size18(emoji: '🎾'),
                gameName: 'Tennis Tournament',
                timeRemaining: '4h 30m',
                dateTime: 'Wed, Dec 3 - 5:00 PM - 7:00 PM',
                location: 'Tennis Club',
              ),
            ],
          ),
          const SizedBox(height: 12),
        ]),

        const SizedBox(height: 24),

        // Progress & Stepper Components
        _buildSection('Progress & Steps (Figma Design)', theme, [
          const Text('Step States:'),
          const SizedBox(height: 8),
          Row(
            children: [
              Column(
                children: [
                  const AppStep(state: AppStepState.defaultState),
                  const SizedBox(height: 4),
                  Text('Default', style: theme.textTheme.labelSmall),
                ],
              ),
              const SizedBox(width: 24),
              Column(
                children: [
                  const AppStep(state: AppStepState.current),
                  const SizedBox(height: 4),
                  Text('Current', style: theme.textTheme.labelSmall),
                ],
              ),
              const SizedBox(width: 24),
              Column(
                children: [
                  const AppStep(state: AppStepState.done),
                  const SizedBox(height: 4),
                  Text('Done', style: theme.textTheme.labelSmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Horizontal Stepper:'),
          const SizedBox(height: 8),
          const AppSteps(totalSteps: 5, currentStep: 2),
          const SizedBox(height: 16),
          const Text('Progress Indicator with Text:'),
          const SizedBox(height: 8),
          const AppProgressIndicator(
            totalSteps: 4,
            currentStep: 1,
            title: 'Personal info',
            description: 'Enter your details to get started',
          ),
        ]),

        const SizedBox(height: 24),

        // AppCard
        _buildSection('AppCard', theme, [
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AppCard Component', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Custom card from design system',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ]),

        const SizedBox(height: 24),

        // AppFilterChip
        _buildSection('AppFilterChip', theme, [
          Wrap(
            spacing: 8,
            children: [
              AppFilterChip(
                label: 'Filter 1',
                emoji: '⚽',
                isSelected: true,
                onTap: () {},
              ),
              AppFilterChip(
                label: 'Filter 2',
                emoji: '🏀',
                isSelected: false,
                count: 5,
                onTap: () {},
              ),
              AppFilterChip(
                label: 'Filter 3',
                icon: Iconsax.filter_copy,
                isSelected: false,
                onTap: () {},
              ),
            ],
          ),
        ]),

        const SizedBox(height: 24),

        // AppInputField & AppSearchInput
        _buildSection('Input Components', theme, [
          const Text('AppSearchInput:'),
          const SizedBox(height: 8),
          AppSearchInput(hintText: 'Search...', onChanged: (value) {}),
          const SizedBox(height: 16),
          const Text('AppInputField:'),
          const SizedBox(height: 8),
          AppInputField(
            label: 'Email',
            placeholder: 'Enter your email',
            prefixIcon: Iconsax.sms_copy,
          ),
          const SizedBox(height: 12),
          AppInputField(
            label: 'Password',
            placeholder: 'Enter password',
            prefixIcon: Iconsax.lock_copy,
            obscureText: true,
            suffixIcon: const Icon(Iconsax.eye_copy, size: 18),
          ),
          const SizedBox(height: 12),
          const AppInputField(
            placeholder: 'Search...',
            prefixIcon: Iconsax.search_normal_copy,
          ),
        ]),

        const SizedBox(height: 24),

        // Spacing Reference
        _buildSection('Spacing Scale', theme, [
          _buildSpacingRow('XXS (3px)', DesignTokens.spacingXxs, theme),
          _buildSpacingRow('XS (6px)', DesignTokens.spacingXs, theme),
          _buildSpacingRow('SM (12px)', DesignTokens.spacingSm, theme),
          _buildSpacingRow('MD (18px)', DesignTokens.spacingMd, theme),
          _buildSpacingRow('LG (24px)', DesignTokens.spacingLg, theme),
          _buildSpacingRow('XL (30px)', DesignTokens.spacingXl, theme),
        ]),

        const SizedBox(height: 24),

        // Theme Info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Theme Info', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Mode: ${_selectedTheme.name}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                'Category: ${_selectedTheme.category}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                'Brightness: ${_selectedTheme.isLight ? "Light" : "Dark"}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Usage Guidelines
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Component Guidelines', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                '• AppChip: Filters, categories, selectable options\n'
                '• Supports 2 sizes: default (36px) and small (18px)\n'
                '• Optional icon, counter badge, and tap callback\n'
                '• AppTab: Navigation sections or content tabs\n'
                '• Active tabs have 2px bottom border, bold text\n'
                '• AppTabBar: Horizontal scrollable tab navigation',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, ThemeData theme, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildColorRow(String label, Color color, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outline),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelLarge),
                Text(
                  '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpacingRow(String label, double spacing, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: spacing,
            height: 24,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Text(label, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
