# Problem Solving Plan - Dabbler App

## 📋 Executive Summary
Found **1,455 errors** across the codebase. This document provides a structured approach to systematically resolve all issues.

---

## 🎯 Priority Classification

### P0 - Critical (Blocking)
**Impact:** App cannot compile or run
- [ ] Result type parameter issues (13+ occurrences)
- [ ] AnalyticsService missing methods (30+ occurrences)
- [ ] AuthService missing methods (1 occurrence)

### P1 - High (Important)
**Impact:** Features broken, type safety compromised
- [ ] Unused imports cleanup
- [ ] Constructor issues with AnalyticsService

### P2 - Medium (Code Quality)
**Impact:** Technical debt, maintenance issues
- [ ] Code organization improvements
- [ ] Consistent error handling patterns

---

## 🔧 Problem Categories & Solutions

### 1. **Result Type Generic Parameters Issue**
**Files Affected:** `auth_profile_service.dart`

**Problem:**
```dart
// Current (Incorrect - 1 type parameter)
Future<Result<Profile>> getMyProfile() async

// Expected (Correct - 2 type parameters)
Future<Result<Failure, Profile>> getMyProfile() async
```

**Root Cause:** Result type requires 2 generic parameters: `Result<L, R>` where L is Left (error) and R is Right (success)

**Solution Steps:**
1. Update all Result type declarations to include both type parameters
2. Pattern: `Result<T>` → `Result<Failure, T>`
3. Update helper functions:
   ```dart
   Result<L, R> success<L, R>(R value) => Right(value);
   Result<L, R> failure<L, R>(L error) => Left(error);
   ```

**Files to Fix:**
- `/lib/core/services/auth_profile_service.dart` (11 occurrences)

**Estimated Time:** 30 minutes

---

### 2. **AnalyticsService Missing Methods**
**Files Affected:** `analytics_helpers.dart`

**Problem:**
```dart
_analytics.trackGameCreationStep(...) // Method doesn't exist
_analytics.trackGameCreated(...) // Method doesn't exist
// + 28 more missing methods
```

**Root Cause:** AnalyticsService interface incomplete or implementation mismatch

**Solution Options:**

**Option A: Stub Methods (Quick Fix)**
```dart
// Add to AnalyticsService
Future<void> trackGameCreationStep(String step, Map<String, dynamic> data) async {
  // TODO: Implement analytics tracking
  return;
}
```

**Option B: Refactor Analytics (Proper Fix)**
1. Define complete AnalyticsService interface
2. Implement all required tracking methods
3. Update analytics_helpers.dart to use correct methods

**Option C: Remove Analytics (Temporary)**
- Comment out analytics calls temporarily
- Focus on core functionality first
- Re-implement analytics later

**Recommended:** Option A (Quick stub) → Then Option B (Proper implementation)

**Missing Methods:**
- `trackGameCreationStep()` - 8 occurrences
- `trackGameCreated()` - 2 occurrences
- `trackGameJoined()` - 1 occurrence
- `trackGameSearch()` - 4 occurrences
- `trackFilterUsed()` - 2 occurrences
- `trackGameCheckIn()` - 2 occurrences
- `trackVenueSelected()` - 1 occurrence
- `trackScreenView()` - 1 occurrence
- `trackFeatureUsed()` - 4 occurrences
- `trackError()` - 1 occurrence
- `trackGameEngagement()` - 1 occurrence
- `trackSearchResultClicked()` - 1 occurrence
- `trackCheckInAttempt()` - 1 occurrence
- `trackPerformanceMetric()` - 4 occurrences

**Estimated Time:** 2-3 hours (Option A), 1 day (Option B)

---

### 3. **AnalyticsService Constructor Issue**
**Files Affected:** `analytics_helpers.dart`

**Problem:**
```dart
final AnalyticsService _analytics = AnalyticsService(); // No unnamed constructor
```

**Root Cause:** AnalyticsService only has named constructors

**Solution:**
Find the correct constructor and use it:
```dart
// Option 1: Singleton pattern
final AnalyticsService _analytics = AnalyticsService.instance;

// Option 2: Factory pattern
final AnalyticsService _analytics = AnalyticsService.create();

// Option 3: Provider injection
final AnalyticsService _analytics = ref.read(analyticsServiceProvider);
```

**Files to Fix:**
- Check AnalyticsService class definition
- Update 30+ instantiation calls

**Estimated Time:** 30 minutes

---

### 4. **AuthService Missing Method**
**Files Affected:** `auth_profile_service.dart`

**Problem:**
```dart
_authService.signUpWithEmailAndMetadata(...) // Method doesn't exist
```

**Solution:**
1. Check AuthService for correct method name
2. Likely alternatives:
   - `signUp()`
   - `signUpWithEmail()`
   - `createUserWithEmailAndPassword()`
3. Update call site with correct method

**Estimated Time:** 15 minutes

---

### 5. **Unused Imports Cleanup**
**Files Affected:** Multiple files

**Problem:**
```dart
import 'package:dabbler/core/design_system/design_system.dart'; // Unused
import 'package:flutter_svg/flutter_svg.dart'; // Unused
```

**Solution:**
Automated cleanup:
```bash
# Run Flutter analyzer
flutter analyze

# Use IDE quick fix (VS Code / Android Studio)
# Or run dart fix
dart fix --apply
```

**Estimated Time:** 10 minutes

---

## 📊 Implementation Strategy

### Phase 1: Critical Fixes (Day 1)
**Goal:** Get app compiling

1. **Morning (2 hours)**
   - [ ] Fix Result type parameters (30 min)
   - [ ] Add AnalyticsService stub methods (1.5 hr)

2. **Afternoon (2 hours)**
   - [ ] Fix AnalyticsService constructor (30 min)
   - [ ] Fix AuthService method (15 min)
   - [ ] Test compilation (15 min)
   - [ ] Clean up unused imports (10 min)
   - [ ] Buffer time (50 min)

### Phase 2: Verification (Day 1 Evening)
**Goal:** Ensure stability

- [ ] Run full test suite
- [ ] Check all screens load
- [ ] Verify critical user flows
- [ ] Document any remaining issues

### Phase 3: Analytics Implementation (Day 2)
**Goal:** Proper analytics tracking

- [ ] Design AnalyticsService interface
- [ ] Implement all tracking methods
- [ ] Add tests
- [ ] Update documentation

---

## 🔍 Error Distribution Analysis

```
Total Errors: 1,455
├─ auth_profile_service.dart: 14 errors (Result types + method)
├─ analytics_helpers.dart: 62 errors (30 missing methods × 2 call sites)
├─ Unused imports: ~50 files
└─ Other files: 0 errors (clean!)
```

**Key Insight:** 95%+ of errors come from just 2 files!

---

## ✅ Quick Wins

Before starting major fixes, address these quick wins:

1. **Unused Imports** (10 min)
   ```bash
   dart fix --dry-run  # Preview changes
   dart fix --apply    # Apply fixes
   ```

2. **Format Code** (5 min)
   ```bash
   dart format .
   ```

3. **Update Dependencies** (10 min)
   ```bash
   flutter pub upgrade
   ```

---

## 🎯 Success Criteria

### Phase 1 Complete When:
- [ ] `flutter analyze` shows 0 errors
- [ ] App compiles successfully
- [ ] App launches without crashes
- [ ] All screens accessible

### Phase 2 Complete When:
- [ ] All tests pass
- [ ] No console errors during navigation
- [ ] Core user flows work end-to-end

### Phase 3 Complete When:
- [ ] Analytics events firing correctly
- [ ] All tracking methods implemented
- [ ] Analytics documented

---

## 🚀 Getting Started

### Step 1: Create Feature Branch
```bash
git checkout -b fix/compilation-errors
```

### Step 2: Fix Result Types
```bash
# Edit: lib/core/services/auth_profile_service.dart
# Replace: Result<T> → Result<Failure, T>
```

### Step 3: Stub Analytics
```bash
# Edit: lib/core/services/analytics_service.dart
# Add stub methods for all missing functions
```

### Step 4: Test & Verify
```bash
flutter clean
flutter pub get
flutter analyze
flutter run
```

---

## 📝 Notes & Considerations

### Why So Many Errors?
- Recent refactoring of Result type (1 → 2 parameters)
- Analytics service interface incomplete
- Normal for large codebase during active development

### Risk Mitigation
- Make atomic commits per fix
- Test after each major change
- Keep main branch stable
- Use feature flags for analytics

### Dependencies Check
- `dartz` package for Result/Either types
- Analytics package (Firebase? Amplitude?)
- Supabase for auth

---

## 🤝 Team Coordination

### Before Starting:
- [ ] Notify team of error fixing session
- [ ] Check for conflicting work
- [ ] Review recent commits for context

### During Work:
- [ ] Commit frequently with clear messages
- [ ] Update this plan as you progress
- [ ] Document any unexpected findings

### After Completion:
- [ ] Create PR with detailed description
- [ ] Request code review
- [ ] Update team on completion
- [ ] Archive this plan for reference

---

## 📚 Reference Links

- [Dartz Package (Result/Either)](https://pub.dev/packages/dartz)
- [Flutter Error Handling Best Practices](https://docs.flutter.dev/testing/errors)
- [Effective Dart Style Guide](https://dart.dev/guides/language/effective-dart)

---

**Last Updated:** November 8, 2025  
**Status:** Ready to Execute  
**Estimated Total Time:** 6-8 hours
