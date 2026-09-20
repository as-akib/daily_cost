# DailyCost — Engineering Notes & Architecture Decisions (v1)

This document records all architectural decisions, mathematical formulas, and implementation nuances for **DailyCost (v1)**.

---

## 1. Salary Cycle Mathematics & Month Clamping (§5)

### Problem
Calendar month budgeting fails for users paid on a custom date (e.g. the 5th, 20th, or 25th of the month). Furthermore, setting a cycle start day of 29, 30, or 31 can cause standard date math (like `DateTime(year, 2, 31)`) to roll over into March, creating bugs and invalid date ranges.

### Solution (`SalaryCycleHelper` in `lib/core/utils/salary_cycle.dart`)
1. **Dynamic Clamping:** For each cycle boundary, the effective start day is computed as:
   $$\text{effectiveStartDay} = \min(\text{cycleStartDay}, \text{daysInMonth}(Y, M))$$
   where $\text{daysInMonth}(Y, M) = \text{DateTime}(Y, M + 1, 0).\text{day}$.
2. **Cycle Boundaries:**
   - If reference date $D \ge \text{candidateStartThisMonth}$, cycle begins in month $M$ and ends at the boundary of month $M+1$.
   - If reference date $D < \text{candidateStartThisMonth}$, cycle began in month $M-1$ and ends at the boundary of month $M$.
3. **Daily Allowance:**
   $$\text{Daily Cost} = \frac{\text{Monthly Income} - \text{Total Fixed Costs} - \text{Monthly Savings Goal}}{\text{Days in Current Salary Cycle}}$$
4. **Daily Reset (No Rollover):**
   - Each day is evaluated independently.
   - Spending \$50 over budget today does **not** subtract from tomorrow's allowance.
   - Spending \$50 under budget today does **not** carry forward into tomorrow's allowance.
   - This keeps the budget mentally clean and prevents debt spirals.

---

## 2. Guest to Google Account Linking & Data Merging (§3)

### Behavior
- On first launch, the user can choose **"Continue as Guest"** (Anonymous Firebase Auth) or **"Sign in with Google"**.
- All user documents are stored under `users/{uid}` and `users/{uid}/expenses/{id}`.
- When an anonymous user later selects **"Upgrade & Link with Google"** in Settings:
  1. The app requests a Google credential via `google_sign_in`.
  2. The app calls `currentUser.linkWithCredential(credential)`.
  3. If successful, the existing anonymous UID is linked directly to the Google account and all data remains in place.
  4. **Edge Case (`credential-already-in-use`):** If the Google account was already used previously, the app catches this error, signs in to the existing Google account (`existingGoogleUid`), and performs a batch write merging all expenses and custom categories from `users/{anonUid}` into `users/{existingGoogleUid}` without overwriting existing records.

---

## 3. Cloud Firestore & Local-First Offline Resilience (§2)

### Architecture
- Cloud Firestore offline persistence is enabled explicitly at app launch via:
  ```dart
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  ```
- All reads and writes target the Firestore SDK directly, which caches documents locally on Android and iOS.
- **Graceful Fallback:** If the app is run before `google-services.json` or `GoogleService-Info.plist` are supplied by the developer, the service layer gracefully detects this and runs in local-first demo mode so that all calculations, screens, and UI flows can be inspected and tested immediately.

---

## 4. Multi-Currency Conversion via Frankfurter API (§8)

### Configuration
- Primary API endpoint: `https://api.frankfurter.dev/v1/latest`
- Fallback API endpoint: `https://api.frankfurter.app/latest`
- No API key is required.
- **Caching:** Rates for the user's base currency are cached in `SharedPreferences` for 24 hours. If network connectivity is unavailable, the cached rates are used. If launched offline for the first time with no cache, an offline fallback table of major currencies is provided.
- **Entry-time Conversion:** Every logged expense stores its original `amount` and `currency`, plus a computed `amountInBaseCurrency` using the exchange rate at entry time.
- Settings provides a live status indicator ("Live (Frankfurter)" or "Offline Fallback") and a manual **"Refresh Rates"** button.

---

## 5. Smart Notifications (§7.7)

### Local Notification Implementation (`flutter_local_notifications`)
- Channel: `dailycost_budget_alerts`
- High priority with notification sound and badge support on Android and iOS.
- **Trigger 1 (Overspend):** When an added expense causes today's spending to exceed today's Daily Cost, a friendly notification is scheduled.
- **Trigger 2 (Spike Detection):** If today's total spending is $>50\%$ above the trailing 7-day average spending (and exceeds \$15), a notice is triggered.
- **Debouncing:** A date key is saved in `SharedPreferences` so that multiple expenses logged on the same day do not repeatedly fire overspend alerts.
- **Tone:** Encouraging, positive, and forward-looking (e.g. *"Tomorrow is a fresh start!"*).
- Settings includes an on/off toggle and a **"Send Test Notification"** action.

---

## 6. Category Management (§4 & §7.9)

- 9 Preset categories (Food & Dining, Transport, Bills & Utilities, Shopping, Entertainment, Health & Fitness, Groceries, Rent & Housing, Other) with distinct, vibrant colors.
- Preset categories cannot be deleted, but users can toggle their visibility (`isHidden`).
- Custom categories can be added with custom names, custom accent colors, and an icon picked from a curated list of Material Icons.
