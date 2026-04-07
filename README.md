# 🙏 सप्ताह व्यवस्थापक - Saptah Manager

**अखंड हरिनाम सप्ताह व ज्ञानेश्वरी पारायण सोहळा**  
हनुमान मंदिर, चिंचोली-भोसे, ता. पंढरपूर

---

## 📱 App Features

### Authentication
- OTP-based login (Firebase Phone Auth)
- Auto-detect new users → name setup
- Role-based access: Admin / User

### Home Dashboard
- Live donation/expense balance
- Today's events
- Today's Mahaprasad menu
- Quick action buttons

### Schedule (कार्यक्रम)
- Day 1–8 tab view
- Live & upcoming event highlighting
- Admin: Add/Edit/Delete events
- Maharaj photo, name, location

### Donations (देणगी)
- Add donations: Cash, Online, Items
- Filter by type, sort by amount/date
- Export: PDF & CSV
- Admin: Edit/Delete any donation
- User: View own 3-year history

### Expenses (खर्च) — NEW: Request System
- **Users** submit expense requests
  - Fields: Name, Amount, Category, Description, Photo
  - Status: Pending / Approved / Rejected
- **Admin** approves/rejects requests
  - Atomic transaction: approval creates expense + deducts balance
  - Rejection with reason
  - Duplicate approval prevention
- Admin can also add direct expenses

### Notifications
- Firebase Cloud Messaging
- Templates for common announcements
- All users receive push notifications

### Mahaprasad
- Daily menu: text + image
- Admin updates, sends notification

### Profile
- User info display
- 3-year donation history (year-grouped)
- Submit suggestions (private)

### Admin Panel
- Expense request approval dashboard
- Direct expense entry
- Send notifications to all users
- Update Mahaprasad
- View suggestions
- Resolve issues/complaints

---

## 🚀 Setup Guide

### Step 1: Flutter Setup
```bash
flutter --version  # Ensure 3.x+
```

### Step 2: Firebase Project
1. Go to https://console.firebase.google.com
2. Create new project: **saptah-manager**
3. Enable these services:
   - **Authentication** → Phone
   - **Firestore Database** → Start in production mode
   - **Storage** → Start in production mode
   - **Cloud Messaging** (automatic)

### Step 3: Configure Firebase in Flutter
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Login
firebase login

# Configure (run inside project root)
cd saptah_manager
flutterfire configure
```
This generates `lib/firebase_options.dart` automatically.

### Step 4: Android Setup
1. In Firebase Console → Project Settings → Add Android app
   - Package name: `com.saptah.manager`
2. Download `google-services.json`
3. Place it at: `android/app/google-services.json`

### Step 5: Update build.gradle

**android/build.gradle:**
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

**android/app/build.gradle:**
```gradle
apply plugin: 'com.google.gms.google-services'

android {
    compileSdkVersion 34
    defaultConfig {
        applicationId "com.saptah.manager"
        minSdkVersion 21
        targetSdkVersion 34
    }
}

dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
}
```

### Step 6: Deploy Security Rules
```bash
# Install Firebase CLI
npm install -g firebase-tools
firebase login

# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules
firebase deploy --only storage
```

### Step 7: Set Admin Role
After first login, manually set admin role in Firestore:
1. Open Firebase Console → Firestore
2. Find your user document in `users/` collection
3. Change `role` field from `"user"` to `"admin"`

### Step 8: Install Dependencies
```bash
cd saptah_manager
flutter pub get
```

### Step 9: Build APK
```bash
# Debug APK (for testing)
flutter build apk --debug

# Release APK (for distribution)
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```
APK location: `build/app/outputs/flutter-apk/app-release.apk`

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry + AuthGate
├── firebase_options.dart        # Firebase config (auto-generated)
├── theme/
│   └── app_theme.dart           # Saffron/Orange theme
├── utils/
│   ├── app_constants.dart       # All constants, collection names
│   └── app_helpers.dart         # Formatters, dialogs, toasts
├── models/
│   ├── user_model.dart
│   ├── donation_model.dart
│   ├── expense_model.dart
│   ├── expense_request_model.dart  ← NEW
│   ├── event_model.dart
│   ├── mahaprasad_model.dart
│   ├── suggestion_model.dart
│   └── issue_model.dart
├── services/
│   ├── auth_service.dart
│   ├── donation_service.dart
│   ├── expense_service.dart     ← Includes request logic
│   ├── event_service.dart
│   ├── other_services.dart      # Notifications, Mahaprasad, Suggestions, Issues
│   └── export_service.dart      # PDF & CSV export
├── widgets/
│   └── common_widgets.dart      # Reusable UI components
└── screens/
    ├── auth/
    │   └── login_screen.dart
    ├── home/
    │   ├── main_navigation.dart
    │   └── home_screen.dart
    ├── schedule/
    │   ├── schedule_screen.dart
    │   └── add_edit_event_screen.dart
    ├── donations/
    │   ├── donations_screen.dart
    │   └── add_donation_screen.dart
    ├── expenses/
    │   └── expenses_screen.dart  ← Submit requests + view list
    ├── admin/
    │   └── admin_panel_screen.dart  ← Full admin panel
    └── profile/
        └── profile_screen.dart
```

---

## 🔥 Firestore Collections

| Collection | Description |
|---|---|
| `users` | User profiles, roles, FCM tokens |
| `donations` | All donation records |
| `expenses` | Approved/direct expenses |
| `expense_requests` | User expense requests (pending/approved/rejected) |
| `events` | Saptah schedule events |
| `mahaprasad` | Daily menu records |
| `notifications` | Sent notifications log |
| `suggestions` | User suggestions (private) |
| `issues` | Donation complaints |

---

## 🔐 Expense Request Flow

```
User submits request
        ↓
Status: PENDING
        ↓
Admin reviews in Admin Panel
        ↓
   ┌────┴────┐
APPROVE    REJECT
   ↓          ↓
Creates      Status:
expense      REJECTED
entry +      (with reason)
Status:
APPROVED
```

**Atomic Transaction Guarantee:**
- Firebase transaction prevents double-approval
- If request is already approved/rejected → throws error

---

## 📞 Support
App built for: **समस्त ग्रामस्थ भजनी मंडळ, चिंचोली-भोसे**  
Event: **अखंड हरिनाम सप्ताह व ज्ञानेश्वरी पारायण सोहळा**

🙏 **हरे राम हरे राम राम राम हरे हरे**
