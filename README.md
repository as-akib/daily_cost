# DailyCost 💰

> **Know where your money goes.**

DailyCost is a production-quality personal finance mobile application built with **Flutter** (Material 3), targeting both **Android** and **iOS**. 

Instead of treating budgeting as complex spreadsheets or passive expense logging, DailyCost reframes budgeting around a single, actionable question: **"How much am I actually allowed to spend today?"**

---

## 🌟 Key Features

1. **Daily Cost Allowance Engine (§5)**
   - Calculates your exact daily disposable allowance based on your monthly income, fixed recurring commitments (rent, utilities, subscriptions), and targeted monthly savings.
   $$\text{Available} = \text{Monthly Income} - \text{Total Fixed Costs} - \text{Monthly Savings Goal}$$
   $$\text{Daily Cost} = \frac{\text{Available}}{\text{Days in Current Cycle}}$$
   - **Custom Salary Cycles:** Full support for any payday (e.g., 5th, 20th, 25th, or the last day of the month) with automatic month-clamping logic for months with 28, 29, 30, or 31 days.
   - **Daily Reset (No Rollover):** Every morning is a clean slate. Yesterday's overspend is not penalized forward, and underspend is banked directly into savings.

2. **6-Step Onboarding Wizard (§7.2)**
   - Guided setup covering base currency selection (with live search across 28+ world currencies), monthly income, fixed costs checklist (with custom item builder), savings goal slider/input, cycle start date picker, and an instant summary confirmation.

3. **Intuitive Dashboard (§7.3)**
   - Hero **Daily Cost Card** displaying today's remaining allowance, a circular progress ring, and real-time status badges (*On Track*, *Caution*, *Over Budget*).
   - At-a-glance metrics: Month Available, Fixed Costs, and Target Savings.
   - Recent expenses list with swipe-to-delete and instant undo snackbars.
   - Quick Access Floating Action Button (FAB) to record new spending in seconds.

4. **Streamlined Add Expense Sheet (§7.4)**
   - Numeric keypad for rapid entry.
   - Category selector with vibrant visual icons.
   - Date picker (defaults to today).
   - Note/memo field.
   - **Multi-Currency Support:** Log expenses in any foreign currency with instant conversion to your base currency powered by Frankfurter API with 24-hour offline caching.

5. **"Can I Afford This?" Calculator (§7.5)**
   - Answers discretionary spending dilemmas before making a purchase.
   - Converts any purchase amount into **"X days of your daily budget"**.
   - Assesses cycle feasibility: informs you if the purchase fits within your remaining cycle buffer and how much your remaining daily allowance would adjust to.

6. **Interactive Spending Summary (§7.6)**
   - Period filtering: *Today*, *This Week*, *This Cycle/Month*, and *Custom Date Range*.
   - Interactive `fl_chart` donut chart showing proportional breakdown by category.
   - Ranked category breakdown with total amounts, expense counts, and percentage of overall spend.

7. **Savings Goal Tracker (§7.7)**
   - Tracks real-time cycle adherence and projected savings based on current spending pace.
   - Visual counter of **Days Under Budget** vs. **Days Over Budget**.
   - Educational micro-insights on how adherence directly boosts savings.

8. **Salary Cycle & Monthly History (§7.8)**
   - Cycle-aware financial breakdown: Total Earned, Fixed Expenses, Total Discretionary Spent, and Net Saved.
   - Historical cycle selector to review past pay cycles with clamped calendar date ranges.

9. **Settings & Customization (§7.9)**
   - Update income, fixed costs, savings goal, or salary start day at any time with immediate allowance recalculation across the entire app.
   - **Category Management:** Hide/show default categories, or create custom categories with tailored names, icons, and colors.
   - **Account Upgrade:** Convert anonymous guest accounts to authenticated Google accounts with automatic cloud data merging.
   - **Smart Notifications:** High-priority local notification alerts for daily overspends and spending spike anomalies (>50% above 7-day average), with a built-in test notification trigger.
   - **Exchange Rates Monitor:** Real-time sync status indicator and manual rate refresh button.

---

## 🏗 Architecture & Project Structure

DailyCost follows a clean, feature-first architecture utilizing **Riverpod** for reactive state management and **Cloud Firestore** for local-first, offline-resilient data persistence:

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart       # Vibrant Material 3 color palette & gradients
│   │   └── app_constants.dart    # Preset categories, icon registry, currency list
│   ├── errors/
│   │   └── app_exception.dart    # Typed domain exceptions
│   ├── theme/
│   │   └── app_theme.dart        # Light and Dark Material 3 theme definitions
│   └── utils/
│       ├── currency_formatter.dart # Currency formatting & symbol helpers
│       ├── date_utils.dart       # Period & range utility functions
│       └── salary_cycle.dart     # Clamping cycle math & date generators
├── data/
│   ├── models/
│   │   ├── category_item.dart    # Category data model
│   │   ├── exchange_rates.dart   # Frankfurter exchange rate response model
│   │   ├── expense.dart          # Expense entry model with multi-currency fields
│   │   ├── fixed_cost.dart       # Recurring fixed commitment model
│   │   └── user_profile.dart     # User profile and financial settings model
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── category_repository.dart
│   │   ├── expense_repository.dart
│   │   ├── profile_repository.dart
│   │   └── providers.dart        # Riverpod providers and budget stats state
│   └── services/
│       ├── auth_service.dart     # Firebase Auth (Guest + Google linking)
│       ├── currency_service.dart # Frankfurter API client + SharedPreferences cache
│       ├── firestore_service.dart # Cloud Firestore sync + offline persistence
│       └── notification_service.dart # flutter_local_notifications engine
├── features/
│   ├── add_expense/              # Modal expense entry sheet with keypad
│   ├── auth/                     # Guest & Google Sign-in screen
│   ├── can_i_afford/             # "Can I Afford This?" decision tool
│   ├── dashboard/                # Main daily allowance hero & recent feed
│   ├── monthly_summary/          # Pay cycle breakdown & past cycles
│   ├── onboarding/               # 6-step initial wizard
│   ├── savings_goal/             # Savings tracker & adherence metrics
│   ├── settings/                 # Category manager, profile editor, alerts
│   └── summary/                  # FlChart donut chart & category rankings
├── routing/
│   └── app_router.dart           # AuthGate, OnboardingGate, NavigationShell
└── main.dart                     # App entry point & initialization
```

---

## 🚀 Getting Started & Setup Guide

### 1. Prerequisites
- **Flutter SDK:** `>= 3.4.0` (Dart SDK `^3.4.0`)
- **Android Studio** / **Xcode** (for iOS simulator/device)
- **Firebase CLI:** Installed and authenticated (`firebase login`)

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Firebase Setup

DailyCost uses **Firebase Authentication** and **Cloud Firestore**. Follow these steps to link your Firebase project:

1. Go to the [Firebase Console](https://console.firebase.google.com/) and click **Add project**.
2. **Configure Authentication:**
   - Go to **Build > Authentication > Sign-in method**.
   - Enable **Anonymous** sign-in (for "Continue as Guest").
   - Enable **Google** sign-in (for "Sign in with Google" & Account Upgrade).
3. **Configure Cloud Firestore:**
   - Go to **Build > Firestore Database** and click **Create database**.
   - Start in production mode.
4. **Register Android App:**
   - Package name: `com.akib.dailycost`
   - Add your debug and release SHA-1 certificate fingerprints (required for Google Sign-In).
   - Download `google-services.json` and place it in:
     ```
     android/app/google-services.json
     ```
5. **Register iOS App:**
   - Bundle ID: `com.akib.dailycost`
   - App Store ID / Team ID as applicable.
   - Download `GoogleService-Info.plist` and place it in:
     ```
     ios/Runner/GoogleService-Info.plist
     ```
   - Make sure `GoogleService-Info.plist` is added to Xcode's Runner target, and add the `REVERSED_CLIENT_ID` URL scheme to `ios/Runner/Info.plist` if using Google Sign-In on iOS.

### 4. Deploy Firestore Security Rules
Deploy the included user-isolated security rules using the Firebase CLI:
```bash
firebase deploy --only firestore:rules
```
The rules in `firestore.rules` ensure users can only read and write documents within their own `users/{userId}` hierarchy:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

> **Note:** If run without Firebase credentials configured, DailyCost includes an automated local-first fallback mode so you can immediately preview and interact with all screens.

---

## 📱 Running the Application

### Run on Connected Device / Simulator
```bash
flutter run
```

### Run Static Analysis
```bash
flutter analyze
```

### Run Unit & Widget Tests
```bash
flutter test
```

All 12 test suites cover:
- Salary cycle math, boundary dates, and February/leap-year clamping.
- "Can I Afford This?" calculation logic.
- Savings adherence and cycle projection formulas.
- Riverpod state management and widget rendering.

---

## 🛡 Platform Identifiers

- **Android Application ID:** `com.akib.dailycost`
- **iOS Bundle Identifier:** `com.akib.dailycost`
- **Min Android SDK:** `23` (Android 6.0 Marshmallow) with Java 8 core desugaring enabled
- **Target Android SDK:** `34` (Android 14)

---

## 📄 Documentation

For in-depth mathematical formulas, offline synchronization design, and architectural decisions, please refer to [NOTES.md](file:///Users/akibsiddiquee/Documents/Akib/AI%20APPS/daily_cost/NOTES.md).
