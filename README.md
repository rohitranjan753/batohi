# Batohi - Firebase & Google Sign-In with BLoC

A Flutter application with Firebase authentication, Google Sign-In, and BLoC state management.

## Features

- 🔥 Firebase Authentication
- 🔐 Google Sign-In
- 🏗️ BLoC State Management Pattern
- 📱 Cross-platform (iOS, Android, Web, macOS, Windows)
- 🎨 Material Design 3

## Architecture

The app uses the BLoC (Business Logic Component) pattern for state management:

- **Models**: User model with Equatable for state comparison
- **Repositories**: AuthenticationRepository for Firebase and Google Sign-In logic
- **BLoCs**: 
  - AuthenticationBloc for managing authentication state
  - LoginBloc for handling sign-in process
- **Pages**: Login and Home pages with reactive UI

## Firebase Setup

To complete the Firebase setup, you need to:

### 1. Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select an existing one
3. Enable Authentication and choose Google as a sign-in provider

### 2. Add Firebase Configuration Files

#### For Android:
1. Add your Android app to Firebase project
2. Download `google-services.json`
3. Place it in `android/app/` directory (already exists in your project)

#### For iOS:
1. Add your iOS app to Firebase project
2. Download `GoogleService-Info.plist`
3. Place it in `ios/Runner/` directory

#### For Web:
1. Add your Web app to Firebase project
2. Copy the configuration and update `lib/firebase_options.dart`

### 3. Update Firebase Configuration

Replace the placeholder values in `lib/firebase_options.dart` with your actual Firebase project configuration:

```dart
// Update these values with your Firebase project configuration
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'your-actual-android-api-key',
  appId: 'your-actual-android-app-id',
  messagingSenderId: 'your-actual-sender-id',
  projectId: 'your-actual-project-id',
  storageBucket: 'your-actual-project-id.appspot.com',
);
```

### 4. Configure Google Sign-In

#### For Android:
1. In Firebase Console, go to Authentication > Sign-in method
2. Enable Google provider
3. Add your SHA-1 fingerprint:
   ```bash
   keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore
   ```

#### For iOS:
1. Add the reversed client ID to `ios/Runner/Info.plist`:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleURLName</key>
           <string>REVERSED_CLIENT_ID</string>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>YOUR_REVERSED_CLIENT_ID</string>
           </array>
       </dict>
   </array>
   ```

## Quick Start

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Configure Firebase (using FlutterFire CLI - Recommended)
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your project
flutterfire configure
```

This will automatically:
- Generate the correct `firebase_options.dart`
- Add necessary configuration files
- Update platform-specific configurations

### 3. Run the App
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point with Firebase initialization
├── firebase_options.dart     # Firebase configuration
├── models/
│   └── user.dart            # User model
├── repositories/
│   └── authentication_repository.dart  # Firebase auth logic
├── blocs/
│   ├── authentication/      # Authentication BLoC
│   │   ├── authentication_bloc.dart
│   │   ├── authentication_event.dart
│   │   └── authentication_state.dart
│   └── login/              # Login BLoC
│       ├── login_bloc.dart
│       ├── login_event.dart
│       └── login_state.dart
└── pages/
    ├── login_page.dart     # Login UI
    └── home_page.dart      # Authenticated user home
```

## Usage

The app automatically handles authentication state:

1. **Splash Screen**: Shows while checking authentication status
2. **Login Page**: Displays when user is not authenticated
3. **Home Page**: Shows user information when authenticated

### Authentication Flow

```dart
// Sign in with Google
context.read<LoginBloc>().add(const LoginGooglePressed());

// Sign out
context.read<AuthenticationBloc>().add(const AuthenticationLogoutRequested());
```

## Testing

Run tests:
```bash
flutter test
```

## Building

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## Troubleshooting

### Common Issues

1. **Google Sign-In not working on Android**:
   - Ensure SHA-1 fingerprint is added to Firebase
   - Check `google-services.json` is in the correct location

2. **Firebase initialization errors**:
   - Verify `firebase_options.dart` has correct configuration
   - Ensure Firebase project is properly set up

3. **Build errors**:
   - Run `flutter clean && flutter pub get`
   - Check all configuration files are in place

## Dependencies

- `firebase_core`: Firebase SDK initialization
- `firebase_auth`: Firebase Authentication
- `google_sign_in`: Google Sign-In integration
- `flutter_bloc`: BLoC state management
- `bloc`: Core BLoC library
- `equatable`: Value equality for models

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and analysis
5. Submit a pull request

## License

This project is open source and available under the [MIT License](LICENSE).
