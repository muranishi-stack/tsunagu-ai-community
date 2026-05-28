// File generated for TSUNAGU-AI-Community Firebase project
// Project ID: tsunagu-ai-community
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  // Web configuration (uses Android API key for now, update when Web app added)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBi4AQlhZy5LYLbjuXFrkAvu-B9o8AWJbo',
    appId: '1:695399022046:web:f424cf6137ae4e5557f14f',
    messagingSenderId: '695399022046',
    projectId: 'tsunagu-ai-community',
    storageBucket: 'tsunagu-ai-community.firebasestorage.app',
    authDomain: 'tsunagu-ai-community.firebaseapp.com',
  );

  // Android configuration (from google-services.json)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBi4AQlhZy5LYLbjuXFrkAvu-B9o8AWJbo',
    appId: '1:695399022046:android:f424cf6137ae4e5557f14f',
    messagingSenderId: '695399022046',
    projectId: 'tsunagu-ai-community',
    storageBucket: 'tsunagu-ai-community.firebasestorage.app',
  );

  // iOS configuration (from GoogleService-Info.plist)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDtBgxHwwza70dvOQ6pxqsq8JfaF4mxOh4',
    appId: '1:695399022046:ios:b874e2175dbc932a57f14f',
    messagingSenderId: '695399022046',
    projectId: 'tsunagu-ai-community',
    storageBucket: 'tsunagu-ai-community.firebasestorage.app',
    iosBundleId: 'com.tsunagu.app',
  );
}
