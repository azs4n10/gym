# gym

A Flutter app that keeps strength training, cardio, body measurements and meals on the device. The palette is the same soft Beige Rose used by flipclock. The interface is English by default and can switch to Japanese in settings.

Live: https://azs4n10.github.io/gym/

## Features

- **Strength log**: exercise × weight × reps × sets, with the previous session and the personal best shown while you type. Cardio (type, duration, distance, calories) goes into the same session.
- **Calendar**: gym days are filled in, meal and body days get a dot. Day streak, weekly-goal streak and monthly count.
- **Body**: weight and body fat with a 30-day / 90-day / 1-year trend chart and a 7-day average.
- **Meals**: calories and macros per breakfast, lunch, dinner and snack. Targets come from height, weight, age and activity level via Mifflin-St Jeor, and can be overridden by hand.
- **Suggestions**: the muscle group you have trained least recently, plus weight and reps based on the last session (+2.5 kg when every set hit 10 reps, +5 kg for lower body). Meals are suggested from the macros you still have left.
- **Health sync**: workouts, weight and meals are written to Apple Health on iOS and Health Connect on Android through the `health` package. Disabled on the web.
- **Themes**: nine skins carried over from flipclock (Beige Rose, Yumekawa, Lavender, Mint Peach, Sugar Pink, Night Star, Midnight Plum, Cocoa Night, Charcoal Rose).

## Layout

```
lib/
  main.dart              startup, provider wiring, centred column on wide screens
  l10n/strings.dart      interface strings (en / ja)
  theme/                 Skin definitions and ThemeData
  models/                enums and UserProfile (shared_preferences)
  data/database.dart     drift table definitions (sqlite)
  data/seed/             built-in exercises and foods (English names + Japanese display map)
  state/                 WorkoutState / BodyState / MealState / AppState
  services/              nutrition maths, streaks, suggestions, health sync
  screens/               home / workouts / calendar / body / meals / settings
  widgets/               cards, rings, stepper inputs, icons
```

## Development

```
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # only after a schema change
flutter run -d chrome
flutter test
```

On the web, sqlite runs through `web/sqlite3.wasm` and `web/drift_worker.js`, both taken from the official drift releases.

## iPhone / iPad (GitHub Pages)

The app ships as a web app rather than a native build, and is meant to be added to the home screen from Safari. Both orientations are supported; in landscape the tab bar moves to a rail on the left.

1. Make this folder its own repository and push it. The repository name does not matter — the workflow derives `--base-href` from it.
   ```
   git init && git add -A && git commit -m "Initial commit"
   gh repo create gym --private --source=. --push
   ```
2. In the repository settings, set Pages → Source to "GitHub Actions".
3. Every push to `main` runs `.github/workflows/deploy.yml`, which tests, builds and deploys. The URL is `https://<user>.github.io/<repo>/`.
4. Open that URL in Safari on the iPhone or iPad and choose "Add to Home Screen" from the share menu.

If GitHub Actions is unavailable, set Pages → Source to "Deploy from a branch → gh-pages" and run `tool/deploy_pages.sh` locally. It builds, pushes to the `gh-pages` branch and requests a Pages build. Git Bash on Windows rewrites `--base-href /gym/` into a drive path, so the script sets `MSYS_NO_PATHCONV=1`.

Builds use `--pwa-strategy=none`, and `web/flutter_service_worker.js` is a kill switch that unregisters the service worker installed by earlier builds, so an updated deploy reaches devices on the next load.

Records live in the browser's IndexedDB on the device. Clearing Safari's site data clears them too.

## Icons

No emoji anywhere. Decorative icons come from [Phosphor Icons](https://phosphoricons.com/) (MIT License): the duotone font `assets/fonts/Phosphor-Duotone.ttf` is bundled and drawn in two layers tinted by the current skin (`Ic` and `AppIcon` in `lib/widgets/app_icon.dart`). To add one, register the two duotone code points (primary and secondary) in `Ic`. The `phosphor_flutter` package is not used because it does not compile on Flutter 3.44.

## Notes

- Nutrition values in the built-in food list are per-serving estimates. Prefer the package label and replace them with your own entries.
- Health sync on Android needs the Health Connect app. `minSdk 26`, `FlutterFragmentActivity` and the manifest permissions are already configured.
- On iOS the HealthKit capability still has to be enabled in Xcode; the Info.plist descriptions are in place. iOS builds are not possible on Windows.

## Health integration

Apple Health and Health Connect are wired through `lib/services/health_sync.dart`.
The integration is disabled on the web build, because the platform APIs are not
reachable from a browser: `isSupported` returns false and the Settings toggle
is greyed out. Use a native build to exercise it.

What is written: workouts (strength and each cardio type mapped to its own
activity type), weight, body fat percentage, and meals with their slot and
macros. Step count is read back.

### Android

`minSdk` is 26, `MainActivity` extends `FlutterFragmentActivity`, and the nine
Health Connect permissions plus the rationale intent filters are declared in
`android/app/src/main/AndroidManifest.xml`. Build with `flutter build apk`.
Health Connect must be installed on the device.

### iOS

`ios/Runner/Runner.entitlements` declares the HealthKit entitlement and is
referenced from all three build configurations. The usage descriptions are in
`Info.plist`, and the deployment target is 15.0 as the plugin requires. Enable
the HealthKit capability on the App ID in the developer portal before signing.

## Food composition data

Searching for a food in the meal picker also searches the Standard Tables of
Food Composition in Japan (8th revised edition, 2023 supplement), bundled as
`assets/data/mext_foods.json` (2,538 entries, per 100 g of the edible part:
energy, protein, fat, carbohydrate by difference). An entry is copied into the
local food library the first time it is logged, so it can then be found,
weighed and deleted like any other food.

The data is published by the Ministry of Education, Culture, Sports, Science
and Technology under the Government of Japan Standard Terms of Use (compatible
with CC BY 4.0). Attribution, as required: 日本食品標準成分表（八訂）増補2023年
から引用. The conversion reads the main table (第2章) Excel file and keeps only
those four values; `tool/` does not include the converter, as it is a one-off.

## Building the Android APK locally

The Android toolchain on the development PC lives outside the project:
JDK 17 (Temurin) at `C:\dev\jdk17` and the Android SDK at
`C:\dev\android-sdk` (platform 36, build-tools 36.0.0, platform-tools),
registered with `flutter config --android-sdk ... --jdk-dir ...`. With that,
`flutter build apk --release` writes `build/app/outputs/flutter-apk/app-release.apk`,
signed with the debug key, which installs by sideloading. The Gradle plugin is
AGP 9 with `android.newDsl=false`, as the Flutter template sets.

## Run companion and calendar export

The Run screen (Today, the Workout tab, or an open session) is something to
look at on the treadmill or the road. A figure runs at your pace, hops at
every kilometre, and calls out landmarks; a road (three fictional routes of
42.2, 100 and 300 km) is covered across sessions and each landmark reached
leaves a stamp; a wheel spins every lap (200 m, 400 m or 1 km) and calls the
next minute; three small quests are drawn per outing. Distance comes from the
speed you set to match the machine, or from the phone's location when GPS is
switched on (web only). Finish writes a cardio entry into today's session.
Progress and stamps live in local preferences (`lib/models/run_play.dart`).

A finished session's menu offers "Add to Google Calendar" (a prefilled event
link) and, on the web, a calendar file (.ics) that any calendar app imports.
Nothing is sent anywhere; the data stays in the link or the file.

## Load time

A cold start downloads the engine (CanvasKit, about 2.9 MB gzipped), the app
code (about 1.1 MB gzipped), sqlite (0.35 MB) and the two bundled weights of
M PLUS Rounded 1c (about 0.5 MB each; subset to the glyphs the app shows,
with the system font as fallback for anything else). The rounded font is no
longer fetched from Google Fonts, which used to pull four full 3.4 MB files
before the first frame.

Flutter 3.44 no longer generates a caching service worker (its
`--pwa-strategy=offline-first` only emits a worker that unregisters itself),
so the app ships its own in `web/sw.js`. It caches everything the page loads
from its own origin under a cache named after a version that
`tool/deploy_pages.sh` stamps into `flutter_bootstrap.js`; later launches read
from the device. Only `index.html` and `flutter_bootstrap.js` are fetched from
the network first (falling back to the cache when offline), which is how a new
deploy gets noticed: it installs as a new worker with its own cache, takes over
once the app has been closed, and the next launch runs on the new files. Plain
`flutter run` leaves the version placeholder in place, so no worker is
registered during development.
