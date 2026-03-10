# Sweetspot

Sweetspot is an audiophile-focused speaker placement and room optimization tool built with Flutter.

## Features

- Acoustic-focused tooling for speaker placement decisions
- Room design and optimization workflows
- Cross-platform desktop targets: Linux, Windows, and macOS

## Tech Stack

- Flutter
- Dart (SDK `>=3.3.0 <4.0.0`)
- Riverpod (`flutter_riverpod`)

## Prerequisites

- Flutter SDK (stable channel)
- A configured desktop toolchain for your OS:
    - Linux: GTK 3, CMake, Ninja, Clang
    - macOS: Xcode command line tools
    - Windows: Visual Studio with Desktop development with C++

## Getting Started

```bash
flutter pub get
flutter run
```

## Run on Desktop

Enable and run a specific desktop target:

```bash
flutter config --enable-linux-desktop
flutter run -d linux
```

```bash
flutter config --enable-windows-desktop
flutter run -d windows
```

```bash
flutter config --enable-macos-desktop
flutter run -d macos
```

## Tests

```bash
flutter test
```

## Build Release Binaries

```bash
flutter build linux --release
flutter build windows --release
flutter build macos --release
```

Default Flutter output directories:

- Linux: `build/linux/x64/release/bundle`
- Windows: `build/windows/x64/runner/Release`
- macOS: `build/macos/Build/Products/Release`

## GitHub Actions Desktop Release

Desktop workflow behavior:

- Push to `development` runs `.github/workflows/ci-development.yml` (dependency install + `flutter analyze`)
- Pull request from `development` to `main` runs `.github/workflows/build-desktop.yml` and builds Linux/Windows/macOS
  artifacts
- Publishing a GitHub Release is manual via **Run workflow** on `Build Desktop (Linux, Windows, macOS)`
- `release_version` is required before release (for example `1.2.3` or `v1.2.3`)
- Archives are published as:
    - `sweetspot-linux.tar.gz`
    - `sweetspot-windows.zip`
    - `sweetspot-macos.zip`

## Version

Current app version in `pubspec.yaml`: `1.0.0+1`
