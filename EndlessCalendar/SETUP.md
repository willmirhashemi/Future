# Endless Calendar - Setup Guide

## Prerequisites

- Xcode 15.0 or later
- iOS 17.0+ deployment target
- A Firebase project
- A Google Cloud project with Gemini API enabled
- CocoaPods or Swift Package Manager

## Step 1: Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select an existing one
3. Add an iOS app to your Firebase project:
   - Bundle ID: `com.yourcompany.EndlessCalendar`
   - Download the `GoogleService-Info.plist` file
4. Place `GoogleService-Info.plist` in the `EndlessCalendar/Resources/` folder

### Enable Firebase Services

In the Firebase Console, enable:
- **Authentication**: Email/Password, Google Sign-In, Apple Sign-In
- **Cloud Firestore**: Create database in production mode
- **Cloud Messaging**: For push notifications

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Events collection
    match /events/{eventId} {
      allow read, write: if request.auth != null &&
        request.auth.uid == resource.data.userId;
      allow create: if request.auth != null;
    }

    // Journal entries collection
    match /journalEntries/{entryId} {
      allow read, write: if request.auth != null &&
        request.auth.uid == resource.data.userId;
      allow create: if request.auth != null;
    }

    // Weekly reviews collection
    match /weeklyReviews/{reviewId} {
      allow read, write: if request.auth != null &&
        request.auth.uid == resource.data.userId;
      allow create: if request.auth != null;
    }

    // AI Plans collection
    match /aiPlans/{planId} {
      allow read, write: if request.auth != null &&
        request.auth.uid == resource.data.userId;
      allow create: if request.auth != null;
    }
  }
}
```

## Step 2: Google Sign-In Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Navigate to "APIs & Services" > "Credentials"
4. Create an OAuth 2.0 Client ID for iOS
5. Add your bundle ID
6. Copy the Client ID and update:
   - `Info.plist`: Update `GIDClientID` and `CFBundleURLSchemes`

## Step 3: Apple Sign-In Setup

1. In your Apple Developer account, enable "Sign In with Apple" capability
2. In Xcode, add the "Sign In with Apple" capability to your target
3. Configure the service in Firebase Console under Authentication > Sign-in method

## Step 4: Gemini API Setup

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create an API key
3. Update `Info.plist`:
   ```xml
   <key>GEMINI_API_KEY</key>
   <string>YOUR_GEMINI_API_KEY_HERE</string>
   ```

## Step 5: Push Notifications

1. Create an Apple Push Notification service (APNs) key in Apple Developer Console
2. Upload the key to Firebase Console > Project Settings > Cloud Messaging
3. In Xcode, add "Push Notifications" capability

## Step 6: Install Dependencies

### Using Swift Package Manager (Recommended)

The dependencies are already configured in `Package.swift`. Xcode will automatically resolve them.

### Using CocoaPods (Alternative)

Create a `Podfile`:

```ruby
platform :ios, '17.0'
use_frameworks!

target 'EndlessCalendar' do
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'Firebase/Messaging'
  pod 'GoogleSignIn'
  pod 'GoogleGenerativeAI'
end
```

Then run:
```bash
pod install
```

## Step 7: Build and Run

1. Open `EndlessCalendar.xcodeproj` (or `.xcworkspace` if using CocoaPods)
2. Select your development team in Signing & Capabilities
3. Update the Bundle Identifier if needed
4. Build and run on a simulator or device

## Project Structure

```
EndlessCalendar/
├── App/
│   ├── EndlessCalendarApp.swift    # App entry point
│   └── RootView.swift              # Root navigation
├── Models/
│   ├── User.swift                  # User data model
│   ├── Event.swift                 # Calendar event model
│   ├── JournalEntry.swift          # Journal entry model
│   └── Achievement.swift           # Achievement model
├── Views/
│   ├── Onboarding/                 # Authentication & onboarding
│   ├── Calendar/                   # Calendar tab views
│   ├── Journal/                    # Journal tab views
│   ├── Settings/                   # Settings views
│   └── Components/                 # Reusable components
├── Services/
│   ├── AuthService.swift           # Authentication
│   ├── FirestoreService.swift      # Database operations
│   ├── GeminiService.swift         # AI integration
│   └── NotificationService.swift   # Push notifications
├── Utilities/
│   └── Theme.swift                 # Colors, fonts, styles
└── Resources/
    ├── Info.plist
    └── GoogleService-Info.plist
```

## Environment Variables

For production, consider using environment variables or a secure configuration manager for:
- `GEMINI_API_KEY`
- Firebase configuration

## Troubleshooting

### Common Issues

1. **"Missing GoogleService-Info.plist"**
   - Ensure the file is in the Resources folder and added to the target

2. **"Google Sign-In failed"**
   - Verify the URL scheme matches your Client ID
   - Check that the Client ID in Info.plist matches Firebase

3. **"Gemini API error"**
   - Verify your API key is valid
   - Check that the Gemini API is enabled in Google Cloud Console

4. **"Push notifications not working"**
   - Ensure APNs key is uploaded to Firebase
   - Test on a real device (simulators don't support push)

## Support

For issues or questions, please open an issue in the repository.
