# Blossom App

Blossom App is a cross-platform application for a beauty & wellness center, featuring:
- **Customer App (Mobile):** For booking appointments, AI skin analysis, and loyalty rewards.
- **Admin Portal (Web):** For managing bookings, staff, services, and users.
- **Staff App (Mobile):** For managing schedules and appointments.

---

## 🚀 How to Run the Application

### 1. Customer / Staff App (Mobile) - First Time Setup
To install and start the app on a new phone (or your own phone) for the first time:

1.  **Connect the Phone:** Plug your phone into the laptop via USB.
2.  **Enable USB Debugging:**
    *   Go to **Settings > About Phone**.
    *   Tap **Build Number** 7 times to enable Developer Options.
    *   Go back to **Settings > System > Developer Options**.
    *   Turn on **USB Debugging**.
3.  **Run the Installation Command:**
    Open a terminal in the project folder (`blossom_app`) and run:

```bash
flutter run
```

#### Running on a Specific Device
If you have multiple devices connected (e.g., your phone AND a Chrome browser), you need to specify which one to use.

1.  List available devices to find your **Device ID**:
    ```bash
    flutter devices
    ```
2.  Run with the specific ID (example ID: `53F0219509003796`):
    ```bash
    flutter run -d 53F0219509003796
    ```
    *(Replace `53F0219509003796` with your actual device ID).*

### 2. Admin Dashboard (Web)
The Admin Portal is optimized for Web. To launch it in a separate Chrome instance:

```bash
flutter run -d chrome --web-port=5000
```

*Note: The `--web-port=5000` flag is optional but recommended to keep a consistent testing address.*

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

---

## ⚙️ Background Processes & Setup

The application relies on **Firebase** for its backend. No manual local server (like Node.js or Python) needs to be started on your laptop for the mobile app to work. The "backend" runs in the cloud (Google Cloud Platform).

**Key Requirements:**
1.  **Internet Access:** The device must be online.
2.  **Firebase Configuration:** Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are present in the project (already configured).
3.  **CORS (For Web):** If you are developing the Admin Web Portal and encounter image upload errors, ensure CORS is configured on your Firebase Storage bucket (already handled via `cors.json`).

---

## 🛠 Troubleshooting

*   **App stuck on "Syncing" or Loading:** Check your internet connection.
*   **"Offline" status:** The app detects connection drops. Reconnect to Wi-Fi/Data.
*   **Build Errors:** Run `flutter clean` and then `flutter pub get` to refresh dependencies.
