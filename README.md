# 📋 Planly – Smart Task Manager (Flutter)

Planly is a **production-grade Smart Task Manager application** built using **Flutter**, following **Clean Architecture**, **Provider state management**, **Firebase integration**, **REST API integration**, and an **offline-first strategy**.

This project demonstrates **real-world Flutter development practices** with a strong focus on scalability, maintainability, and clean code.

---

## 🎯 Objective

- Clean Architecture
- Proper state management using **Provider**
- Firebase Authentication & Firestore integration
- REST API integration
- Offline-first strategy
- Robust error handling & edge cases
- Scalable folder structure
- Clean and maintainable code practices

---

## 🔐 Authentication (Firebase)

### Features
- Email & Password login / registration
- Logout functionality
- Persistent login session
- Proper input validation
- Firebase errors mapped to user-friendly messages

### Flow

Login / Register
↓
Firebase Authentication
↓
Fetch User Profile from Firestore
↓
Navigate to Dashboard


---

## 👤 User Profile (Firestore)

User data is stored under:

users/{userId}


### Stored Fields
- `name`
- `email`
- `createdAt`
- `themeMode` (light / dark)

### Capabilities
- Dark / Light mode preference saved in Firestore
- Auto-apply saved theme on app launch
- Update profile feature
- Real-time Firestore synchronization

---

## 🗂️ Task Module (REST API + Local Cache)

### 🌐 API Details
- **Base URL:**  
  https://taskmanager.uat-lplusltd.com
- **Swagger Documentation:**  
  https://taskmanager.uat-lplusltd.com/docs
- **Authentication:**  
  All endpoints require `user_id` as a query parameter

---

### 📥 Fetch Tasks

GET /tasks/?user_id={uid}&skip=0&limit=10


### Features
- Infinite scroll pagination using `skip` & `limit`
- Pull-to-refresh functionality
- Client-side filtering:
  - All
  - Completed
  - Pending
- Client-side search by task title
- Sorting by:
  - Due Date
  - Priority
  - Created Date

### Task Fields
- `priority`
- `category`
- `due_date`
- `is_completed`

---

## ➕ Add / ✏️ Update / ❌ Delete Tasks

### Create Task

POST /tasks/?user_id={uid}


### Update Task

PUT /tasks/{id}?user_id={uid}


### Delete Task

DELETE /tasks/{id}?user_id={uid}


### UX Enhancements
- Optimistic UI updates
- Smooth state transitions
- Instant user feedback

---

## 📡 Offline-First Strategy

- Local persistence using **Hive / SQLite**
- Cached API responses
- Load tasks from local storage when offline
- Automatic data sync when internet connectivity is restored
- Offline banner indicator for better user experience

---

## 🧠 State Management

- **Provider** (Mandatory)
- No business logic inside UI layer
- Proper loading, success & error states
- Minimal widget rebuilds
- Predictable and reactive UI behavior

---

## ⚠️ Error Modeling

Centralized error handling using custom exceptions:
- `AppException`
- `NetworkException`
- `ServerException`
- `CacheException`
- `AuthException`

UI reacts appropriately based on error type:
- Retry options
- Error messages
- Empty state handling

---

## 🎨 UI / UX

- Material 3 design system
- Dark / Light mode toggle
- Clean and minimal UI
- Proper spacing and alignment
- Empty state UI
- No layout overflow issues

---

## ⭐ Bonus Implementations

- Dio with interceptors
- Connectivity Plus (network awareness)
- Debounced search
- Infinite scroll pagination

---

## 🏗️ Project Structure (Clean Architecture)


lib/
│
├── core/
│ ├── error/
│ ├── network/
│ └── utils/
│
├── features/
│ ├── auth/
│ │ ├── data/
│ │ ├── domain/
│ │ └── presentation/
│ │
│ ├── profile/
│ └── tasks/
│
├── shared/
│
└── main.dart


---

## 🛠️ Tech Stack

- Flutter
- Dart
- Provider
- Firebase Authentication
- Cloud Firestore
- REST APIs
- Hive / SQLite
- Dio
- Material 3

---

## ⚙️ Setup & Installation

```bash
git clone https://github.com/your-username/planly.git
cd planly
flutter pub get
Firebase Setup

Add google-services.json (Android)

Configure Firebase project credentials

📦 Build APK (Release Mode)
flutter build apk --release
📋 Submission Checklist

✅ Public GitHub repository

✅ Clean commit history

✅ Release-mode APK

✅ Clean Architecture

✅ Proper documentation

👨‍💻 Author

Ayush Antony
Flutter Developer
Clean Architecture • Provider • Firebase • REST APIs

📌 Note

Planly is built to reflect industry-level Flutter development standards and demonstrates readiness for professional Flutter developer roles, not just academic or demo projects.
