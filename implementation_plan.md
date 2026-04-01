# Firebase Integration Plan

Now that you have successfully placed the Firebase configuration files in your project (`google-services.json` and `GoogleService-Info.plist`), it's time to connect the app to the cloud!

In this phase, we will migrate the application from "mock" authentication to real **Firebase Authentication** (Email/Password & Google Sign In). We will also fix the macOS networking issue so you can test the app cleanly on your Mac.

## User Review Required

> [!CAUTION]
> **Platform Support**: I see you have previously tested the app by running it as a **macOS Desktop application** (`flutter run -d macos`). By default, macOS Flutter apps are "sandboxed" and completely blocked from accessing the internet. This is why you saw those red `google_fonts` network errors earlier. 
> To fix this, I will modify your `macos/Runner/*.entitlements` files to allow incoming and outgoing internet connections. This will fix the font errors AND allow Firebase to work on your Mac. 

## Proposed Changes

### Configuration Updates

#### [MODIFY] [pubspec.yaml](file:///Users/apple/rahul/Computer%20Science/code_projects/Projexa-Project/pubspec.yaml)
- Add `firebase_core`: Required to run Firebase.
- Add `firebase_auth`: Required for email/password and user state management.
- Add `google_sign_in`: Required for the Google Single-Sign-On flow.

#### [MODIFY] [android/build.gradle](file:///Users/apple/rahul/Computer%20Science/code_projects/Projexa-Project/android/build.gradle)
- Add Google Services classpath plugin dependency so Android knows how to read your `google-services.json` file.

#### [MODIFY] [android/app/build.gradle](file:///Users/apple/rahul/Computer%20Science/code_projects/Projexa-Project/android/app/build.gradle)
- Apply the `com.google.gms.google-services` plugin at the bottom of the file.

#### [MODIFY] [macos/Runner/DebugProfile.entitlements](file:///Users/apple/rahul/Computer%20Science/code_projects/Projexa-Project/macos/Runner/DebugProfile.entitlements)
#### [MODIFY] [macos/Runner/Release.entitlements](file:///Users/apple/rahul/Computer%20Science/code_projects/Projexa-Project/macos/Runner/Release.entitlements)
- Add the `com.apple.security.network.client` key and set it to `true`. This grants the macOS build permission to access the internet.

### Code Updates

#### [NEW] [lib/firebase_options.dart](file:///Users/apple/rahul/Computer%20Science/code_projects/Projexa-Project/lib/firebase_options.dart)
- I will programmatically generate this file utilizing the API keys and App IDs strictly extracted from your `google-services.json` and `GoogleService-Info.plist`. This allows Firebase to initialize cleanly across Android, iOS, and macOS seamlessly without needing you to install the Firebase CLI.

#### [MODIFY] [lib/main.dart](file:///Users/apple/rahul/Computer%20Science/code_projects/Projexa-Project/lib/main.dart)
- Convert `main()` to `async` and invoke `await Firebase.initializeApp(...)` before running the app.

#### [MODIFY] [lib/services/auth_service.dart](file:///Users/apple/rahul/Computer%20Science/code_projects/Projexa-Project/lib/services/auth_service.dart)
- Remove the `Future.delayed` mocks.
- Implement real `FirebaseAuth.instance` calls for:
  - `createUserWithEmailAndPassword()`
  - `signInWithEmailAndPassword()`
  - `signOut()`
- Implement real Google Sign In flow using `GoogleSignIn()`.

#### [MODIFY] [lib/widgets/social_login_buttons.dart](file:///Users/apple/rahul/Computer%20Science/code_projects/Projexa-Project/lib/widgets/social_login_buttons.dart)
- Connect the Google button to the new `signInWithGoogle` method in the `AuthService`. 

## Verification Plan

### Automated Steps
1. Run `flutter pub get` to download the Firebase packages.
2. Run `flutter analyze` to ensure no syntax errors were introduced.

### Manual Verification
1. I will ask you to run the app on the macOS target.
2. Sign up with a test email inside the app.
3. Once completed, you should be able to view that new user directly inside your Firebase Authentication Console online!
