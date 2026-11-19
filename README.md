# Newsly

Newsly is a Flutter news reader for browsing headlines, viewing article details,
and saving articles as local bookmarks. It includes login and settings screens,
light and dark themes, and a persistent bottom navigation bar.

## Features

- Browse and search news headlines, with category filters, pagination, and
  pull-to-refresh.
- Open article details and save or remove bookmarks.
- Persist bookmarks, login state, and the selected theme on the device.
- Switch between Home, Bookmarks, and Settings using bottom navigation.
- Display loading, empty, API-error, and network-error states.

## Requirements

- Flutter SDK with Dart SDK `3.13.2` or compatible with the constraint in
  `pubspec.yaml`.
- An Android, iOS, web, Windows, macOS, or Linux development target supported
  by your Flutter installation.
- Internet access and a valid GNews API key to fetch headlines.

Check your local Flutter setup:

```shell
flutter --version
flutter doctor -v
```

## Project setup

1. Clone or download this repository and open its root directory.
2. Install the Dart and Flutter dependencies:

   ```shell
   flutter pub get
   ```

3. Configure a valid GNews API key for local development. The key is consumed by
   `NewsRepository` in `lib/features/home/data/repo/news_repo.dart`. Keep API
   credentials private and out of source control. The repository currently
   defines the key in that file; the `--dart-define` hint in the runtime error
   is not wired to the key-loading code yet.
4. Run the app on a connected device, emulator, or selected desktop/web target:

   ```shell
   flutter run
   ```

Useful development commands:

```shell
flutter analyze
flutter test
```

## Folder structure

```text
lib/
  core/
    bottom_navigation_bar/   Shared bottom navigation widget
    constants/               Shared colors and dimensions
    network/                 Shared network-related UI helpers
    routing/                 GoRouter routes, navigation shell, transitions
    storage/                 Hive-backed login and local storage helpers
    theme/                   App themes and persisted theme state
  features/
    home/
      data/
        model/               News article and API response models
        repo/                GNews API client/repository
      view/                  Home, search, bookmarks, article details
      view_model/            News and bookmark state
    login/
      view/                  Login and OTP screens
    setting/
      view/                  Appearance and account settings
  main.dart                  App initialization and dependency providers
test/                        Widget and persistence tests
android/                     Android host project
ios/                         iOS host project
web/                         Web entry point and manifest
linux/                        Linux host project
macos/                        macOS host project
windows/                      Windows host project
```

## Architecture

- **App composition:** `lib/main.dart` initializes Hive boxes and registers
  `HomeViewModel` and `ThemeProvider` with Provider before building the app.
- **Navigation:** `AppRouter` uses GoRouter for login, OTP, home, search,
  bookmarks, settings, and article-detail routes. Home, Bookmarks, and Settings
  share a stateful navigation shell and bottom bar.
- **Presentation and state:** Screens in each feature's `view/` directory build
  the UI. `HomeViewModel` manages headline and bookmark state and delegates
  network access to `NewsRepository`. `ThemeProvider` manages the persisted
  light/dark selection.
- **Data:** `NewsRepository` requests GNews headlines with Dio and converts the
  response into `NewsArticle` and `NewsPage` models. Hive stores local settings,
  login state, and bookmark data.

## Packages

### Runtime

| Package | Purpose |
| --- | --- |
| `provider` | Dependency injection and ChangeNotifier-based state management |
| `dio` | HTTP requests to the GNews API |
| `hive` | Local key-value storage |
| `hive_flutter` | Flutter initialization and integration for Hive |
| `go_router` | Declarative routing and stateful navigation |

### Development and Flutter SDK

| Package | Purpose |
| --- | --- |
| `flutter` | UI framework and Material widgets |
| `flutter_test` | Widget and unit testing |
| `flutter_lints` | Dart and Flutter static-analysis rules |

## Assumptions and limitations

- Headline requests use GNews general headlines for India, in English, with a
  page size of 10.
- Network access and a valid GNews API key are needed for live headline data.
- Login currently stores a local logged-in flag; it is not backed by a remote
  authentication service. The OTP screen is a placeholder.
- Bookmarks and theme preference are stored locally on the device and are not
  synced between devices or accounts.
- API credentials must remain private. Before distributing the app, wire the
  key to a secure build-time configuration and avoid embedding a reusable key in
  a client application.
