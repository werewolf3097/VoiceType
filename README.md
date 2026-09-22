# VoiceType — Multiplatform Repository

VoiceType is a voice-to-text application. This repository is structured by platform so each target can be built and developed independently.

```
VoiceType/
├── macos/          # macOS app (Swift / SwiftUI / Xcode)
├── android/        # Android app (Kotlin / Gradle)
└── README.md       # this file
```

---

## macos/

**Language:** Swift + SwiftUI  
**Build tool:** Xcode (`.xcodeproj`) via XcodeGen (`project.yml`)  
**Entry point:** `macos/VoiceType/VoiceType.xcodeproj`

### What's inside

| Path | Description |
|------|-------------|
| `macos/VoiceType/` | Xcode project root (sources, resources, project file) |
| `macos/VoiceType/VoiceType/Sources/` | Swift source files |
| `macos/VoiceType/VoiceType/Resources/` | `Info.plist` and other assets |
| `macos/VoiceType.app/` | Pre-built `.app` bundle (for reference/testing) |
| `macos/DOCUMENTATION.md` | Architecture and feature documentation |

### How to build

Requires macOS with Xcode installed (or GitHub Actions `macos-latest` runner).

```bash
# Option 1 — open in Xcode
open macos/VoiceType/VoiceType.xcodeproj

# Option 2 — build from CLI (macOS only)
cd macos/VoiceType
xcodebuild -scheme VoiceType -configuration Debug build
```

> **Note:** This project cannot be compiled on Linux or Windows because it depends on Apple-only frameworks (AppKit, AVFoundation, Carbon).

---

## android/

**Language:** Kotlin  
**Build tool:** Gradle (Kotlin DSL)  
**Min SDK:** 26 | **Target/Compile SDK:** 35

### What's inside

| Path | Description |
|------|-------------|
| `android/app/src/main/kotlin/` | Kotlin source files |
| `android/app/src/main/res/` | Layouts, drawables, values |
| `android/app/src/main/AndroidManifest.xml` | App manifest |
| `android/app/build.gradle.kts` | App-level Gradle config |
| `android/build.gradle.kts` | Root Gradle config |
| `android/settings.gradle.kts` | Project settings |
| `android/gradle.properties` | Gradle / AndroidX flags |

### How to build

Requires JDK 17+ and Android SDK (set `ANDROID_HOME`).  
Works on **Linux, Windows, and macOS**.

```bash
cd android

# Build debug APK
./gradlew assembleDebug          # macOS / Linux
gradlew.bat assembleDebug        # Windows

# Output: app/build/outputs/apk/debug/app-debug.apk
```

---

## Adding a new platform

1. Create a top-level folder named after the platform (e.g., `windows/`, `linux/`, `web/`).
2. Place all platform-specific build files and sources inside it.
3. Add a section to this README describing the toolchain and build commands.
4. Keep cross-platform business logic (if any) in a shared `core/` module and reference it from each platform target.

---

## CI / GitHub Actions sketch

```yaml
# .github/workflows/android.yml  — runs on any OS
- uses: actions/checkout@v4
- uses: actions/setup-java@v4
  with: { java-version: '17', distribution: 'temurin' }
- run: cd android && ./gradlew assembleDebug

# .github/workflows/macos.yml  — must use macos-latest
- uses: actions/checkout@v4
- run: cd macos/VoiceType && xcodebuild -scheme VoiceType build
```
