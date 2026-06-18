# GesturLink

GesturLink is an MVP Flutter application that translates human facial/head gestures into control commands sent over Bluetooth Low Energy (BLE). It features a modern, clean UI with a futuristic Dark Mode aesthetic and micro-animations.

## Architecture

This application consists of two main roles which can be selected via the **Selector Screen**:

1. **Gesture Controller (BLE Central)**
   - Uses the `camera` and `google_mlkit_face_detection` packages to stream and process facial geometry.
   - Detects Head Tilt Left (Euler Z < -15) and Head Tilt Right (Euler Z > 15).
   - Once a gesture is detected, it sends a BLE command ("LEFT" or "RIGHT") via `flutter_blue_plus` to the connected receiver.
   - Features a debouncing logic (500ms) to avoid command spamming.

2. **Command Receiver (BLE Peripheral)**
   - Uses `flutter_ble_peripheral` to advertise the specialized GesturLink Service UUID.
   - Listens to incoming connections and displays the commands in a real-time Action Log.

## Dependencies & Packages
- Provider (State Management)
- Permission Handler (Permissions)
- Camera & Google MLKit Face Detection (Computer Vision)
- Flutter Blue Plus & Flutter BLE Peripheral (Bluetooth)
- Google Fonts (Typography)

## How to Run & Test

1. Ensure you have two physical devices (e.g., two Android phones) as BLE and Camera features cannot be tested properly on emulators.
2. Build and install the app on both devices: `flutter run`
3. On **Device A (Receiver)**: Select "Act as Command Receiver". Ensure permissions are granted.
4. On **Device B (Controller)**: Select "Act as Gesture Controller". Ensure permissions are granted.
5. Device B will scan for Device A and connect.
6. Tilt your head left or right in front of Device B's camera to see the command appear on Device A's action log.
