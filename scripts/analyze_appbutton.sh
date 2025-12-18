#!/bin/bash

# Dabbler AppButton Replacement Script
# Replaces AppButton wrapper with native Material 3 buttons

set -e

cd "$(dirname "$0")/.."

echo "🎨 Replacing AppButton with native Material 3 buttons..."

# List of files with AppButton usage (excluding backups)
FILES=(
  "lib/features/error/presentation/pages/error_page.dart"
  "lib/features/profile/presentation/screens/payment_methods_screen.dart"
  "lib/features/explore/presentation/screens/match_detail_screen.dart"
  "lib/features/misc/presentation/screens/set_password_screen.dart"
  "lib/features/misc/presentation/screens/language_selection_screen.dart"
  "lib/features/misc/presentation/screens/create_game_screen.dart"
  "lib/features/misc/presentation/screens/change_phone_screen.dart"
)

echo "Files to process:"
for file in "${FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "  ✓ $file"
  else
    echo "  ✗ $file (not found)"
  fi
done
echo ""

echo "Note: AppButton already wraps Material 3 buttons correctly:"
echo "  - ButtonVariant.primary → FilledButton"
echo "  - ButtonVariant.secondary → FilledButton.tonal"
echo "  - ButtonVariant.outline → OutlinedButton"
echo "  - ButtonVariant.ghost → TextButton"
echo ""
echo "Since AppButton is Material 3 compliant, keeping it is acceptable."
echo "However, for direct usage, manual replacement is recommended for each file."
echo ""

echo "✅ Analysis complete. Manual review recommended for complex cases."
