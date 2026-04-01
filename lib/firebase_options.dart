// File generated for Firebase Initialization
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBtqgsxjX8bNuq1tlVkMIAidPxUIAORr_E',
    appId: '1:497167395549:web:placeholder_we_only_support_mobile_for_now',
    messagingSenderId: '497167395549',
    projectId: 'warranty-vault-34782',
    authDomain: 'warranty-vault-34782.firebaseapp.com',
    storageBucket: 'warranty-vault-34782.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBtqgsxjX8bNuq1tlVkMIAidPxUIAORr_E',
    appId: '1:497167395549:android:6bfb281e9d95b5b2e4c934',
    messagingSenderId: '497167395549',
    projectId: 'warranty-vault-34782',
    storageBucket: 'warranty-vault-34782.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAng_XdXsc1hzx4kXZu6YVmbgYgBBCjCMw',
    appId: '1:497167395549:ios:21bf36c734184a44e4c934',
    messagingSenderId: '497167395549',
    projectId: 'warranty-vault-34782',
    storageBucket: 'warranty-vault-34782.firebasestorage.app',
    iosBundleId: 'com.example.projexa',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAng_XdXsc1hzx4kXZu6YVmbgYgBBCjCMw',
    appId: '1:497167395549:ios:21bf36c734184a44e4c934',
    messagingSenderId: '497167395549',
    projectId: 'warranty-vault-34782',
    storageBucket: 'warranty-vault-34782.firebasestorage.app',
    iosBundleId: 'com.example.projexa',
  );
}
