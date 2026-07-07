# Donation Manager

Donation Manager is a Flutter + Firebase application for tracking donations, expenses, event schedules, announcements, and admin workflows for community events.

## What it does

- Phone-auth based sign-in with role-aware navigation
- Donation tracking with filters, editing, and PDF/CSV export
- Expense management with approval and rejection workflow
- Event and schedule management
- Mahaprasad, suggestions, issues, and notification utilities
- Admin dashboard for operational control

## Tech stack

- Flutter
- Firebase Auth
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Messaging

## Getting started

1. Install Flutter 3.41 or newer.
2. Run `flutter pub get`.
3. Add your Firebase Android config file at `android/app/google-services.json`.
4. Regenerate `lib/firebase_options.dart` with `flutterfire configure` if you want to use your own Firebase project.
5. Run the app with `flutter run`.

## Firebase note

The public repository excludes `android/app/google-services.json` so the project can be shared safely. To run the full app, add your own Firebase configuration locally before building Android.

## Verified locally

- `flutter test`
- `flutter build apk --debug`

## Project structure

```text
lib/
  main.dart
  models/
  screens/
  services/
  theme/
  utils/
  widgets/
```

## Resume-friendly summary

This project demonstrates a production-style Flutter app with:

- real-time Firebase data flows
- role-based admin and user experiences
- file export features
- operational workflow design for donations and expenses
- cross-screen state and navigation structure
