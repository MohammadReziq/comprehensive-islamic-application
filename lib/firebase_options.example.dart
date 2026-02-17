// Copy this file as firebase_options.dart and fill with your own values,
// OR run: dart run flutterfire_cli:flutterfire configure
// Do NOT commit firebase_options.dart with real API keys (it is in .gitignore).

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      case TargetPlatform.iOS: return ios;
      case TargetPlatform.macOS: return macos;
      case TargetPlatform.windows: return windows;
      default: throw UnsupportedError('Platform not supported');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'your-project-id',
    authDomain: 'your-project.firebaseapp.com',
    storageBucket: 'your-project.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'your-project-id',
    storageBucket: 'your-project.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'your-project-id',
    storageBucket: 'your-project.firebasestorage.app',
    iosBundleId: 'com.example.yourapp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'your-project-id',
    storageBucket: 'your-project.firebasestorage.app',
    iosBundleId: 'com.example.yourapp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'your-project-id',
    authDomain: 'your-project.firebaseapp.com',
    storageBucket: 'your-project.firebasestorage.app',
  );
}
