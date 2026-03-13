# Product Requirement Document (PRD)
## Smart Class Check-in & Learning Reflection App

## Student Information
- Name: Nang Phyo Thet Thet Khaing
- Student ID: 6731503071

## 1) Problem Statement
Class attendance can be inaccurate when recorded manually, and attendance alone does not show student participation.
This project provides a simple mobile app for students to check in and finish class using GPS and QR verification, plus short learning reflections.
The goal is to confirm both physical presence and engagement in each class session.

## 2) Target Users
- Primary users: University students attending class
- Secondary users: Instructors who review attendance and reflection records

## 3) Objectives
- Verify student attendance with GPS + QR
- Collect short pre-class and post-class learning reflections
- Store records reliably for later review
- Deliver a working MVP within exam time constraints

## 4) Feature List (MVP)

### 4.1 Home Screen
- Show app title and two main actions:
  - Check-in
  - Finish Class
- Navigate to corresponding forms

### 4.2 Check-in (Before Class)
Student must:
1. Tap Check-in
2. Capture current GPS location
3. Scan class QR code
4. Fill required fields:
   - Previous class topic
   - Expected topic for today
   - Mood before class (1–5)

System records:
- Check-in timestamp
- GPS latitude/longitude
- QR payload
- Form inputs

### 4.3 Finish Class (After Class)
Student must:
1. Tap Finish Class
2. Scan QR code
3. Capture current GPS location
4. Fill required fields:
   - What I learned today
   - Feedback for class/instructor

System records:
- Finish timestamp
- GPS latitude/longitude
- QR payload
- Form inputs

## 5) User Flow

### 5.1 Check-in Flow
Home -> Check-in Screen -> Get GPS -> Scan QR -> Fill Form -> Submit -> Save success message

### 5.2 Finish Class Flow
Home -> Finish Class Screen -> Scan QR -> Get GPS -> Fill Form -> Submit -> Save success message

## 6) Data Fields

| Field Name | Type | Required | Description |
|---|---|---|---|
| recordId | String | Yes | Unique record ID |
| studentId | String | Yes | Student identifier |
| classSessionId | String | Yes | Session identifier |
| checkInTime | DateTime | Yes (check-in) | Time of check-in |
| checkInLat | Double | Yes (check-in) | Latitude during check-in |
| checkInLng | Double | Yes (check-in) | Longitude during check-in |
| checkInQr | String | Yes (check-in) | QR value scanned at check-in |
| previousTopic | String | Yes (check-in) | Topic from previous class |
| expectedTopic | String | Yes (check-in) | Topic expected today |
| moodBefore | Int (1–5) | Yes (check-in) | Student mood before class |
| checkOutTime | DateTime | Yes (finish) | Time of class completion |
| checkOutLat | Double | Yes (finish) | Latitude during finish |
| checkOutLng | Double | Yes (finish) | Longitude during finish |
| checkOutQr | String | Yes (finish) | QR value scanned at finish |
| learnedToday | String | Yes (finish) | Student learning summary |
| feedback | String | Yes (finish) | Class/instructor feedback |
| createdAt | DateTime | Yes | Record creation timestamp |

## 7) Validation Rules
- Submit is blocked until all required fields are filled
- GPS must be captured before submit
- QR must be scanned before submit
- Mood value must be between 1 and 5
- Text fields cannot be empty

## 8) Tech Stack
- Frontend: Flutter (Dart)
- Location: geolocator
- QR Scanner: mobile_scanner (or equivalent)
- Local Storage (MVP): sqflite (or SharedPreferences for simple version)
- Backend/Cloud: Firebase (Firestore for cloud storage)
- Deployment: Firebase Hosting (Flutter Web build or landing/demo page)

## 9) Non-Functional Requirements
- Simple and clear UI for fast form completion
- Data save should complete within a few seconds
- App should handle permission denial with clear messages
- Works as MVP on Android device/emulator

## 10) Scope

### In Scope (Exam MVP)
- 3 screens (Home, Check-in, Finish Class)
- GPS + QR + form input
- Local data storage
- Basic Firebase integration and one deployed component

### Out of Scope
- Full authentication system
- Admin dashboard analytics
- Advanced reporting/export
- Multi-role management

## 11) Success Criteria
- User can complete both Check-in and Finish Class flows without crash
- Required data is stored locally for each submission
- At least one component is deployed on Firebase Hosting with accessible URL
- Project repository includes source code, README, and AI usage report
