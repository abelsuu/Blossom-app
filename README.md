# Blossom App 🌸

A cross-platform Flutter application for a modern beauty & wellness center. This project demonstrates a complete ecosystem with three distinct user roles:

1.  **Customer App (Mobile):** AI-powered skin analysis, booking management, and loyalty rewards.
2.  **Admin Portal (Web):** Dashboard for managing staff, services, users, and business analytics.
3.  **Staff App (Mobile):** Schedule management and appointment tracking.

---

## 🏗️ Project Architecture

The project follows a **Feature-First** architecture for scalability and maintainability.

### 📂 Directory Structure (`lib/`)
*   **`main.dart`**: Entry point. Handles role-based routing (Admin vs. Customer vs. Staff) and Firebase initialization.
*   **`features/`**: Contains all business logic, split by domain:
    *   **`auth/`**: Authentication screens and logic.
    *   **`customer/`**:
        *   `facial_ai/`: Custom camera implementation and AI instruction logic.
        *   `booking/`: Complex slot management and double-booking prevention.
        *   `ai_skin_analysis/`: Logic for processing skin metrics.
    *   **`admin/`**: Web-optimized screens for database management.
    *   **`staff/`**: Logic for shift management and daily tasks.
*   **`core/` & `common/`**: Shared widgets (Buttons, Dialogs) and constants.

---

## 🚀 Key Features & Implementation

### 1. Smart Booking System
*   **Location:** `features/customer/screens/booking/booking_screen.dart`
*   **Logic:**
    *   **Client-Side Filtering:** Fetches bookings and locally filters for "upcoming" slots to reduce database read costs.
    *   **Conflict Prevention:** Checks `availability/$date/$time` nodes in Firebase before confirming a slot.
    *   **Dynamic Time Slots:** Automatically disables past time slots based on the user's current device time.

### 2. AI Skin Analysis
*   **Location:** `features/customer/screens/facial_ai/` & `ai_skin_analysis/`
*   **Workflow:**
    1.  **Instruction Screen:** Guides user on lighting and positioning.
    2.  **Image Capture:** Uses `image_picker` (with specific Web/Mobile handling).
    3.  **Analysis:** (Mock/Integration) returns metrics for Acne, Sensitivity, and Elasticity.
    4.  **Profile Update:** Automatically updates the user's profile in Firebase with new skin stats.

### 3. Role-Based Authentication
*   **Location:** `main.dart`
*   **Logic:** Listens to the Firebase Auth Stream.
    *   `email.startsWith('admin')` → Redirects to **Admin Web Portal**.
    *   `email.startsWith('staff')` → Redirects to **Staff Dashboard**.
    *   Others → Redirects to **Customer Home**.

### 4. Real-Time Data Sync
*   **Tech:** `StreamBuilder` + `Firebase Realtime Database`.
*   **Benefit:** Updates to appointments, loyalty points, or staff schedules reflect instantly across all devices without pulling-to-refresh.

---

## 🛠 Tech Stack

*   **Frontend:** Flutter (Dart)
*   **Backend:** Firebase Realtime Database
*   **Auth:** Firebase Authentication
*   **State Management:** `setState` (local) + `Streams` (global data)

---

## 🔌 How to Run

### 1. Customer / Staff App (Mobile)
1.  Connect your Android device via USB.
2.  Enable **USB Debugging** in Developer Options.
3.  Run:
    ```bash
    flutter run
    ```

### 2. Admin Dashboard (Web)
For the best experience, run the Admin portal in Chrome:
```bash
flutter run -d chrome --web-port=5000
```

---

## ⚙️ Backend Setup (Firebase)
*   **No Local Server Required:** The app connects directly to the Google Cloud (Firebase).
*   **Requirements:** Active Internet connection is mandatory for data fetching.
*   **Persistence:** Mobile apps have offline persistence enabled for viewing cached data.

---

## 🔌 FAQ: Phone Connection & Unplugging

**Q: Does my phone have to be connected to my laptop to run the app?**
**A: No, not permanently.**

*   **During Development:** Yes, you need the cable connected to install the app and see the logs (errors, print statements) on your laptop.
*   **After Installation:** Once the app is installed on your phone (after `flutter run` finishes installing), **you can unplug the cable**. The app is now installed on your device like any other app from the App Store.

**Q: Can I run it if I unplug?**
**A: Yes!** You can close the terminal, unplug your phone, and walk away. Just tap the **Blossom App** icon on your phone's home screen to open it.

**Q: What do I need for it to work?**
**A: Internet Connection.**
Since the app connects to a cloud database (Firebase) to save bookings, fetch services, and perform AI analysis, **your phone must have an active internet connection (Wi-Fi or Mobile Data)**. It does **not** need to be on the same Wi-Fi as your laptop.
