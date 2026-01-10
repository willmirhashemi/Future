# Endless Calendar

An AI-powered iOS calendar app that helps users achieve their dreams and goals through personalized task generation, journaling, and achievement tracking.

## Features

### AI-Powered Goal Planning
- **Personalized Plans**: Answer a questionnaire about your goals, and our AI (powered by Gemini) generates a comprehensive calendar of events tailored to your needs
- **Category Focus**: Choose from Study & Learning, Fitness & Health, Financial, Creative & Hobby, Networking & Social, Self-Care & Rest, or Career Development
- **Smart Scheduling**: Events are scheduled based on your preferred time of day and available hours

### Calendar View
- **Timeline View**: Hour-by-hour view similar to Apple Calendar, with support for 1-3 day views
- **Month Calendar**: Full month overview with event indicators
- **Event Management**:
  - AI-generated events can have times adjusted but not deleted
  - Manual events are fully customizable
  - Color-coded events by type

### Journal & Tracking
- **Daily Journaling**: Free-form or guided prompts based on your preferences
- **Mood Tracking**: Track your daily mood with emoji indicators
- **Weekly Reviews**: Automatic Sunday evening prompts to reflect on your week
- **Accomplishments & Gratitude**: Track wins and things you're grateful for

### Achievements
- **Journal Streaks**: Earn badges for consistent journaling (7, 30, 100 days)
- **Event Creation**: Achievements for adding your own events (10, 50, 100+)
- **Task Completion**: Recognition for completing tasks
- **App Usage**: Rewards for consistent app usage

### Design
- **Dark Matte Theme**: Easy on the eyes with a sophisticated dark color scheme
- **Native iOS**: Built with SwiftUI for smooth, native performance
- **Intuitive UI**: Familiar calendar interface inspired by Apple and Google Calendar

## Tech Stack

- **Frontend**: Swift 5.9, SwiftUI
- **Backend**: Firebase (Auth, Firestore)
- **AI**: Google Gemini API
- **Authentication**: Email/Password, Google Sign-In, Apple Sign-In
- **Notifications**: Firebase Cloud Messaging

## Getting Started

See [SETUP.md](EndlessCalendar/SETUP.md) for detailed setup instructions.

### Quick Start

1. Clone the repository
2. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
3. Generate the Xcode project: `cd EndlessCalendar && xcodegen`
4. Set up Firebase and add your `GoogleService-Info.plist`
5. Add your Gemini API key to `Info.plist`
6. Build and run!

## Project Structure

```
EndlessCalendar/
├── App/                    # App entry point and root navigation
├── Models/                 # Data models (User, Event, Journal, Achievement)
├── Views/
│   ├── Onboarding/        # Authentication and goal setup
│   ├── Calendar/          # Calendar tab views
│   ├── Journal/           # Journal and achievements tab
│   └── Settings/          # App settings
├── Services/              # Firebase, Gemini AI, Notifications
├── Utilities/             # Theme, extensions, helpers
└── Resources/             # Plists, assets
```

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- Firebase project
- Gemini API key

## License

This project is proprietary. All rights reserved.

## Support

For questions or issues, please open an issue in this repository.
