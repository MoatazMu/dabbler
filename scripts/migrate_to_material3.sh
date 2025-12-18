#!/bin/bash

# Dabbler Material 3 Migration Script
# Replaces custom design tokens with Material 3 equivalents

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "🚀 Starting Material 3 Migration..."
echo "📁 Working directory: $PROJECT_ROOT"
echo ""

# Create backup
echo "📦 Creating backup..."
BACKUP_DIR="backups/pre_material3_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -R lib "$BACKUP_DIR/"
echo "✅ Backup created at: $BACKUP_DIR"
echo ""

# Function to replace in file
replace_in_file() {
    local file="$1"
    local search="$2"
    local replace="$3"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/$search/$replace/g" "$file"
    else
        # Linux
        sed -i "s/$search/$replace/g" "$file"
    fi
}

echo "🔄 Phase 1: Replacing AppTypography with Theme.of(context).textTheme..."

# Find all dart files in lib/features (exclude test and generated files)
find lib/features -name "*.dart" -type f ! -path "*/test/*" ! -name "*.g.dart" ! -name "*.freezed.dart" | while read -r file; do
    # Check if file contains AppTypography
    if grep -q "AppTypography\." "$file"; then
        echo "  ↳ Processing: $file"
        
        # Replace AppTypography with Theme.of(context).textTheme
        replace_in_file "$file" "AppTypography\.displayLarge" "Theme.of(context).textTheme.displayLarge"
        replace_in_file "$file" "AppTypography\.displayMedium" "Theme.of(context).textTheme.displayMedium"
        replace_in_file "$file" "AppTypography\.displaySmall" "Theme.of(context).textTheme.displaySmall"
        replace_in_file "$file" "AppTypography\.headlineLarge" "Theme.of(context).textTheme.headlineLarge"
        replace_in_file "$file" "AppTypography\.headlineMedium" "Theme.of(context).textTheme.headlineMedium"
        replace_in_file "$file" "AppTypography\.headlineSmall" "Theme.of(context).textTheme.headlineSmall"
        replace_in_file "$file" "AppTypography\.titleLarge" "Theme.of(context).textTheme.titleLarge"
        replace_in_file "$file" "AppTypography\.titleMedium" "Theme.of(context).textTheme.titleMedium"
        replace_in_file "$file" "AppTypography\.titleSmall" "Theme.of(context).textTheme.titleSmall"
        replace_in_file "$file" "AppTypography\.bodyLarge" "Theme.of(context).textTheme.bodyLarge"
        replace_in_file "$file" "AppTypography\.bodyMedium" "Theme.of(context).textTheme.bodyMedium"
        replace_in_file "$file" "AppTypography\.bodySmall" "Theme.of(context).textTheme.bodySmall"
        replace_in_file "$file" "AppTypography\.labelLarge" "Theme.of(context).textTheme.labelLarge"
        replace_in_file "$file" "AppTypography\.labelMedium" "Theme.of(context).textTheme.labelMedium"
        replace_in_file "$file" "AppTypography\.labelSmall" "Theme.of(context).textTheme.labelSmall"
        
        # Add ? for null safety after textTheme properties when used with copyWith
        replace_in_file "$file" "\.textTheme\.\([a-zA-Z]*\)\.copyWith" ".textTheme.\1?.copyWith"
    fi
done

echo "✅ AppTypography replacement complete!"
echo ""

echo "🔄 Phase 2: Replacing AppSpacing with numeric values..."

find lib/features -name "*.dart" -type f ! -path "*/test/*" ! -name "*.g.dart" ! -name "*.freezed.dart" | while read -r file; do
    if grep -q "AppSpacing\." "$file"; then
        echo "  ↳ Processing: $file"
        
        # Replace AppSpacing constants
        replace_in_file "$file" "AppSpacing\.huge" "48.0"
        replace_in_file "$file" "AppSpacing\.xxl" "32.0"
        replace_in_file "$file" "AppSpacing\.xl" "24.0"
        replace_in_file "$file" "AppSpacing\.lg" "16.0"
        replace_in_file "$file" "AppSpacing\.md" "12.0"
        replace_in_file "$file" "AppSpacing\.sm" "8.0"
        replace_in_file "$file" "AppSpacing\.xs" "4.0"
        
        # Handle special cases like buttonBorderRadius
        replace_in_file "$file" "AppSpacing\.buttonBorderRadius" "12.0"
    fi
done

echo "✅ AppSpacing replacement complete!"
echo ""

echo "🎨 Phase 3: Formatting code..."
dart format lib/features
echo "✅ Code formatted!"
echo ""

echo "✅ Migration complete!"
echo ""
echo "Next steps:"
echo "1. Review changes with: git diff"
echo "2. Run: flutter analyze"
echo "3. Run: flutter pub run build_runner build -d"
echo "4. Test the app thoroughly"
echo ""
echo "Backup location: $BACKUP_DIR"
