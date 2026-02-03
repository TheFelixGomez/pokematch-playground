# Pokematch Playground

A Flutter-based playground application exploring advanced mobile features, including swipeable interfaces, text recognition, and state management.

## 🚀 Features

- **Pokemon Matching**: Tinder-style swipe interface for browsing Pokemon using `appinio_swiper`.
- **OCR Scanner**: Integrated text recognition (using `google_mlkit_text_recognition`) to scan and identify Pokemon names from images.
- **Authentication**: Secure login and user session management.
- **Settings**: Customizable app preferences including theming and potential localization.
- **Favorites**: Save and manage your favorite Pokemon.
- **Offline First**: Utilizes `hive` for high-performance local data persistence.

## 🛠️ Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: [Riverpod](https://riverpod.dev/)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
- **Local Storage**: [Hive](https://docs.hivedb.dev/) + `shared_preferences`
- **Networking**: [Dio](https://pub.dev/packages/dio)
- **ML/AI**: Google ML Kit (Text Recognition)
- **UI Components**: `appinio_swiper`, custom widgets

## 📂 Project Structure

```
lib/
├── models/         # Data models and entities
├── pages/          # Application screens and views
├── providers/      # Riverpod state providers
├── services/       # Business logic and external API handling
├── widgets/        # Reusable UI components
├── main.dart       # Entry point
└── router.dart     # Navigation configuration
```

## 🏁 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed and configured.
- An IDE (VS Code or Android Studio) with Flutter plugins.

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/yourusername/pokematch-playground.git
    cd pokematch-playground
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the app:**
    ```bash
    flutter run
    ```

## 🧪 Running Tests

To run unit and widget tests:

```bash
flutter test
```
