# Smart Class Check-in & Learning Reflection App

**Student ID:** 6731503071
**Course:** Mobile Application Development — Midterm Lab Exam

---

## 1. Problem Statement & Requirements

Traditional attendance methods (name calling, paper sign-in) are time-consuming and prone to proxy attendance. This application solves these problems by requiring students to:

- **Physically be present** — GPS coordinates are captured at both check-in and class completion
- **Scan a unique QR code** — provided by the instructor, ensuring the student is in the correct room
- **Reflect on their learning** — short form inputs before and after class

**Target Users:** University students (primary), Instructors (data consumers)

### Core Feature Requirements

| # | Feature | Priority |
|---|---------|----------|
| 1 | User registration & login (Firebase Auth) | High |
| 2 | GPS location capture | High |
| 3 | QR code scanning | High |
| 4 | Pre-class reflection form | High |
| 5 | Post-class reflection form | High |
| 6 | Local data persistence (SQLite) | High |
| 7 | Cloud sync to Firebase Firestore | High |
| 8 | Session management (remember login) | Medium |

---

## 2. System Design

### User Flow

```
App Launch
    │
    ▼
Auth Gate ──► Welcome Screen ──► Login / Sign Up (Firebase Auth)
    │
    ▼ (authenticated)
Home Screen
    ├──► Check-in Flow
    │        ├── Capture GPS Location
    │        ├── Scan QR Code (mobile_scanner)
    │        ├── Fill pre-class form (previous topic, expected topic, mood 1–5)
    │        └── Save → SQLite (local) + Firestore (cloud)
    │
    └──► Finish Class Flow
             ├── Scan QR Code
             ├── Capture GPS Location
             ├── Fill post-class form (learned today, feedback, instructor rating)
             └── Save → SQLite (local) + Firestore (cloud)
```

### Data Schema

**`class_records` table (SQLite) / `class_records` collection (Firestore)**

| Field | Type | Description |
|-------|------|-------------|
| `flow_type` | String | `"checkin"` or `"finish"` |
| `timestamp` | String | ISO-8601 date-time |
| `latitude` | Real | GPS latitude |
| `longitude` | Real | GPS longitude |
| `qr_data` | String | Scanned QR code content |
| `previous_topic` | String | Topic from last class (check-in only) |
| `expected_topic` | String | Topic expected today (check-in only) |
| `mood_before` | Integer | 1–5 mood rating (check-in only) |
| `learned_today` | String | Reflection on learning (finish only) |
| `feedback` | String | Class/instructor feedback (finish only) |
| `instructor_rating` | Integer | 1–5 instructor rating (finish only) |
| `synced_at` | String | Cloud sync timestamp |

---

## 3. Flutter Application

### Screens

| Screen | File | Purpose |
|--------|------|---------|
| Welcome | `welcome_screen.dart` | Landing / branding screen |
| Login | `login_screen.dart` | Firebase email/password sign-in |
| Sign Up | `signup_screen.dart` | New account registration |
| Auth Gate | `auth_gate.dart` | Redirects based on auth state |
| Home | `home_screen.dart` | Main menu (Check-in / Finish Class) |
| Check-in | `checkin_screen.dart` | GPS + QR + pre-class form |
| QR Scanner | `qr_scanner_screen.dart` | Camera-based QR code reader |
| Finish Class | `finish_screen.dart` | QR + GPS + post-class reflection |

### Key Implementation Details

**Navigation** — `MaterialApp` with named-style push navigation between all screens; `AuthGate` listens to `FirebaseAuth.authStateChanges()` to gate access.

**Form Input** — `Form` + `GlobalKey<FormState>` with validation on all required fields; mood selector uses a custom emoji chip row (1–5 scale).

**QR Code Scanning** — `mobile_scanner ^7.2.0` opens the device camera in `QrScannerScreen`; result is passed back via `Navigator.pop`.

**GPS Location** — `geolocator ^14.0.2` checks service enabled → permission → returns `Position` (latitude/longitude); prompts user to open settings if disabled.

**Saving Data** — Every submission writes to:
1. Local **SQLite** via `DbService` (offline-first, `sqflite ^2.4.2`)
2. **Cloud Firestore** via `CloudSyncService` (`cloud_firestore ^5.6.0`)

### Project Structure

```
lib/
├── main.dart                   # App entry, Firebase init, session load
├── firebase_options.dart       # Auto-generated Firebase config
├── screens/
│   ├── auth_gate.dart
│   ├── welcome_screen.dart
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── home_screen.dart
│   ├── checkin_screen.dart
│   ├── qr_scanner_screen.dart
│   └── finish_screen.dart
└── services/
    ├── auth_api_service.dart   # Firebase Auth wrapper
    ├── auth_session_service.dart # SharedPreferences session persistence
    ├── db_service.dart         # SQLite local database
    └── cloud_sync_service.dart # Firestore cloud sync
```

---

## 4. Firebase Integration

The app uses three Firebase services:

| Service | Usage |
|---------|-------|
| **Firebase Auth** | Email/password sign-up and sign-in |
| **Cloud Firestore** | Stores every check-in/finish record in the `class_records` collection |
| **Firebase Hosting** | Web deployment of the Flutter web build |

Firebase is initialised at app startup in `main.dart` with a 12-second timeout. Firestore writes are performed in `CloudSyncService.saveRecord()` which adds each submission as a new document.

---

## 5. Deployment

The application is deployed as a **Flutter Web** app on **Firebase Hosting**.

**Live URL:** https://smart-class-checkin.web.app

To deploy manually:

```bash
flutter build web
firebase deploy --only hosting
```

---

## 6. How to Run Locally

### Prerequisites

- Flutter SDK `^3.11.1`
- A connected physical device or emulator
- Firebase project with Auth + Firestore enabled

### Steps

```bash
# 1. Clone the repository
git clone <repository-url>
cd smart_class_checkin

# 2. Install dependencies
flutter pub get

# 3. Run on device/emulator
flutter run
```

---

## 7. Dependencies

```yaml
geolocator: ^14.0.2        # GPS location
mobile_scanner: ^7.2.0     # QR code scanning
sqflite: ^2.4.2            # Local SQLite database
firebase_core: ^3.13.0     # Firebase initialisation
firebase_auth: ^5.5.0      # Authentication
cloud_firestore: ^5.6.0    # Cloud database
shared_preferences: ^2.3.2 # Session persistence
intl: ^0.20.2              # Date formatting
http: ^1.2.2               # HTTP utilities
```

---

## 8. AI Usage

GitHub Copilot was used during development to:

- Scaffold boilerplate widget code (screen layouts, form fields)
- Generate the SQLite schema and `DbService` CRUD methods
- Suggest `geolocator` permission-handling patterns
- Help structure the `CloudSyncService` Firestore integration

All generated code was reviewed, tested, and adapted to fit the application's requirements. The architecture decisions (dual local+cloud persistence, auth gate pattern, offline-first approach) were made independently based on the project requirements.
