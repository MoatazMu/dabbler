# Material 3 Components Quick Reference

## 🎨 Color Tokens Access

```dart
// In any widget
final colorScheme = Theme.of(context).colorScheme;

// Category colors
colorScheme.categoryMain        // Purple (0xFF7328CE light, 0xFFC18FFF dark)
colorScheme.categorySocial      // Blue (0xFF3473D7 light, 0xFFA6DCFF dark)
colorScheme.categorySports      // Green (0xFF348638 light, 0xFF7FD89B dark)
colorScheme.categoryActivities  // Pink (0xFFD72078 light, 0xFFFFA8D5 dark)
colorScheme.categoryProfile     // Orange (0xFFF59E0B light, 0xFFFFCE7A dark)

// Light variants
colorScheme.categoryMainLight
colorScheme.categorySocialLight
// ... etc

// Semantic colors
colorScheme.success  // 0xFF00A63E / 0xFF0FBF5A
colorScheme.warning  // 0xFFEC8F1E / 0xFFFBBF24
colorScheme.error    // Material default

// Detailed tokens (for advanced use)
final tokens = context.colorTokens;
tokens.header       // Header background
tokens.section      // Section background
tokens.button       // Button color
tokens.onBtn        // Button text color
tokens.stroke       // Border color
tokens.neutral      // Body text color
```

## 🔘 Buttons

### Filled Button (Primary)
```dart
// Simple
FilledButton(
  onPressed: () {},
  child: Text('Save'),
)

// With icon
FilledButton.icon(
  onPressed: () {},
  icon: Icon(Icons.add),
  label: Text('Add'),
)

// Custom color
FilledButton(
  onPressed: () {},
  style: FilledButton.styleFrom(
    backgroundColor: colorScheme.categorySports,
  ),
  child: Text('Sports Action'),
)
```

### Outlined Button (Secondary)
```dart
OutlinedButton(
  onPressed: () {},
  child: Text('Cancel'),
)

OutlinedButton.icon(
  onPressed: () {},
  icon: Icon(Icons.edit),
  label: Text('Edit'),
)
```

### Text Button (Ghost/Tertiary)
```dart
TextButton(
  onPressed: () {},
  child: Text('Skip'),
)

TextButton.icon(
  onPressed: () {},
  icon: Icon(Icons.share),
  label: Text('Share'),
)
```

### Elevated Button
```dart
ElevatedButton(
  onPressed: () {},
  child: Text('Submit'),
)
```

### Icon Button
```dart
IconButton(
  onPressed: () {},
  icon: Icon(Icons.favorite),
)

IconButton.filled(
  onPressed: () {},
  icon: Icon(Icons.add),
)

IconButton.outlined(
  onPressed: () {},
  icon: Icon(Icons.settings),
)
```

## 🃏 Cards

### Filled Card (Default)
```dart
Card.filled(
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Text('Content'),
  ),
)
```

### Outlined Card
```dart
Card.outlined(
  child: ListTile(
    leading: Icon(Icons.person),
    title: Text('John Doe'),
    subtitle: Text('Software Engineer'),
  ),
)
```

### Card with Custom Color
```dart
Card.filled(
  color: colorScheme.categorySocial.withOpacity(0.1),
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [
        Icon(Icons.people, color: colorScheme.categorySocial),
        Text('Social', style: TextStyle(
          color: colorScheme.categorySocial,
        )),
      ],
    ),
  ),
)
```

## 📝 Input Fields

### TextField
```dart
TextField(
  decoration: InputDecoration(
    labelText: 'Email',
    hintText: 'Enter your email',
    prefixIcon: Icon(Icons.email),
  ),
)
```

### TextFormField (with validation)
```dart
TextFormField(
  controller: controller,
  decoration: InputDecoration(
    labelText: 'Password',
    prefixIcon: Icon(Icons.lock),
  ),
  validator: (value) {
    if (value?.isEmpty ?? true) return 'Required';
    return null;
  },
  obscureText: true,
)
```

### Search Field
```dart
TextField(
  decoration: InputDecoration(
    hintText: 'Search...',
    prefixIcon: Icon(Icons.search),
    filled: true,
    fillColor: colorScheme.surfaceContainerHighest,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: BorderSide.none,
    ),
  ),
)
```

## 🏷️ Chips

### Filter Chip
```dart
FilterChip(
  label: Text('Sports'),
  selected: isSelected,
  onSelected: (value) {
    setState(() => isSelected = value);
  },
)

// Custom color
FilterChip(
  label: Text('Sports'),
  selected: true,
  backgroundColor: colorScheme.categorySports.withOpacity(0.1),
  selectedColor: colorScheme.categorySports.withOpacity(0.2),
  checkmarkColor: colorScheme.categorySports,
  onSelected: (value) {},
)
```

### Action Chip
```dart
ActionChip(
  label: Text('Add'),
  avatar: Icon(Icons.add, size: 18),
  onPressed: () {},
)
```

### Input Chip (for tags)
```dart
InputChip(
  label: Text('Flutter'),
  onDeleted: () {},
)
```

### Choice Chip (radio button alternative)
```dart
Wrap(
  spacing: 8,
  children: ['Main', 'Social', 'Sports'].map((category) {
    return ChoiceChip(
      label: Text(category),
      selected: selectedCategory == category,
      onSelected: (selected) {
        setState(() => selectedCategory = category);
      },
    );
  }).toList(),
)
```

## 🧭 Navigation

### Navigation Bar (Bottom)
```dart
NavigationBar(
  selectedIndex: currentIndex,
  onDestinationSelected: (index) {
    setState(() => currentIndex = index);
  },
  destinations: [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.people_outlined),
      selectedIcon: Icon(Icons.people),
      label: 'Social',
    ),
  ],
)
```

### Tab Bar
```dart
TabBar(
  tabs: [
    Tab(icon: Icon(Icons.home), text: 'Home'),
    Tab(icon: Icon(Icons.people), text: 'Social'),
  ],
)
```

## 📋 Lists

### ListTile
```dart
ListTile(
  leading: CircleAvatar(child: Icon(Icons.person)),
  title: Text('John Doe'),
  subtitle: Text('Software Engineer'),
  trailing: Icon(Icons.arrow_forward),
  onTap: () {},
)
```

### Divider
```dart
Divider()
Divider(height: 1, thickness: 1)
```

## 💬 Dialogs & Sheets

### Alert Dialog
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Confirm'),
    content: Text('Are you sure?'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {},
        child: Text('Confirm'),
      ),
    ],
  ),
)
```

### Bottom Sheet
```dart
showModalBottomSheet(
  context: context,
  builder: (context) => Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon(Icons.share),
          title: Text('Share'),
          onTap: () {},
        ),
        // ...
      ],
    ),
  ),
)
```

## 🎯 Best Practices

1. **Always use colorScheme** for colors instead of hardcoded values
2. **Prefer native components** over custom widgets for consistency
3. **Use appropriate button types**:
   - FilledButton for primary actions
   - OutlinedButton for secondary actions
   - TextButton for tertiary actions
4. **Test in both light and dark mode**
5. **Use semantic colors** (success, warning, error) for feedback
6. **Follow Material 3 spacing** (4dp grid)
7. **Leverage ThemeData** for global styling
