import 'package:flutter/material.dart';
import '../core/components/dabbler_button.dart';
import '../core/components/dabbler_card.dart';
import '../core/components/dabbler_form_field.dart';
import '../core/config/design_system/design_tokens/spacing.dart';
import '../core/config/design_system/design_tokens/typography.dart';
import '../widgets/elegant_loading_screen.dart';
import '../widgets/loading_spinner.dart';

/// A demo screen showcasing the new design system components
class DesignSystemDemo extends StatelessWidget {
  const DesignSystemDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Design System Demo',
          style: DabblerTypography.headline6(),
        ),
      ),
      body: SingleChildScrollView(
        padding: DabblerSpacing.all16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buttons',
              style: DabblerTypography.headline5(),
            ),
            SizedBox(height: DabblerSpacing.spacing16),
            Wrap(
              spacing: DabblerSpacing.spacing8,
              runSpacing: DabblerSpacing.spacing8,
              children: [
                DabblerButton(
                  text: 'Primary Button',
                  onPressed: () {},
                  variant: ButtonVariant.primary,
                ),
                DabblerButton(
                  text: 'Secondary Button',
                  onPressed: () {},
                  variant: ButtonVariant.secondary,
                ),
                DabblerButton(
                  text: 'Text Button',
                  onPressed: () {},
                  variant: ButtonVariant.text,
                ),
                DabblerButton(
                  text: 'Loading',
                  onPressed: () {},
                  isLoading: true,
                ),
                DabblerButton(
                  text: 'Disabled',
                  onPressed: null,
                ),
              ],
            ),
            SizedBox(height: DabblerSpacing.spacing32),
            Text(
              'Cards',
              style: DabblerTypography.headline5(),
            ),
            SizedBox(height: DabblerSpacing.spacing16),
            DabblerContentCard(
              title: 'Content Card',
              subtitle: 'With title, subtitle, content and actions',
              content: const Text(
                'This is an example of a content card with multiple elements. '
                'It demonstrates the spacing, typography, and component composition.',
              ),
              actions: [
                DabblerButton(
                  text: 'Cancel',
                  onPressed: () {},
                  variant: ButtonVariant.text,
                ),
                SizedBox(width: DabblerSpacing.spacing8),
                DabblerButton(
                  text: 'Submit',
                  onPressed: () {},
                ),
              ],
            ),
            SizedBox(height: DabblerSpacing.spacing32),
            Text(
              'Form Fields',
              style: DabblerTypography.headline5(),
            ),
            SizedBox(height: DabblerSpacing.spacing16),
            DabblerCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DabblerFormField(
                    label: 'Username',
                    placeholder: 'Enter your username',
                    helperText: 'This will be your display name',
                  ),
                  SizedBox(height: DabblerSpacing.spacing16),
                  const DabblerFormField(
                    label: 'Password',
                    placeholder: '••••••••',
                    obscureText: true,
                  ),
                  SizedBox(height: DabblerSpacing.spacing16),
                  DabblerFormField(
                    label: 'Email',
                    placeholder: 'Enter your email',
                    errorText: 'Please enter a valid email address',
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
            ),
            SizedBox(height: DabblerSpacing.spacing32),
            Text(
              'Loading Screens',
              style: DabblerTypography.headline5(),
            ),
            SizedBox(height: DabblerSpacing.spacing16),
            _buildLoadingScreensSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreensSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Loading Screens',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        // Elegant Loading Screen
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Elegant Loading Screen',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ElegantLoadingScreen(
                      title: 'Loading...',
                      subtitle: 'Please wait while we prepare your experience',
                      logoPath: 'assets/logo.png',
                      accentColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Features:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Smooth fade and slide animations\n'
                  '• Pulsing logo effect\n'
                  '• Animated decorative dots\n'
                  '• Elegant shadows and gradients\n'
                  '• Customizable colors and timing',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Simple Loading Screen
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Simple Loading Screen',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 150,
                  child: SimpleLoadingScreen(
                    message: 'Loading...',
                    logoPath: 'assets/logo.png',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Features:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Clean and minimal design\n'
                  '• Subtle background styling\n'
                  '• Lightweight implementation\n'
                  '• Perfect for quick loading states',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Enhanced Loading Spinner
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enhanced Loading Spinner',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: LoadingSpinner(
                    message: 'Processing your request...',
                    showLogo: true,
                    logoPath: 'assets/logo.png',
                    size: 50,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Features:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Enhanced with logo support\n'
                  '• Elegant shadows and styling\n'
                  '• Message container with background\n'
                  '• Customizable size and colors',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Minimal Loading Indicator
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Minimal Loading Indicator',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const MinimalLoadingIndicator(size: 20),
                    const MinimalLoadingIndicator(size: 30, strokeWidth: 2.5),
                    const MinimalLoadingIndicator(size: 40, strokeWidth: 3),
                    MinimalLoadingIndicator(
                      size: 50,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Features:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Perfect for inline use\n'
                  '• Customizable size and stroke width\n'
                  '• Lightweight and efficient\n'
                  '• Consistent with app theme',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
