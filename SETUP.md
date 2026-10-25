# Memora development setup

This guide prepares a Windows workstation for the current T01 baseline. Run commands in PowerShell unless stated otherwise.

## Required software

| Tool | Required version or component | Used for |
| --- | --- | --- |
| Git | Current supported release | Repository and task branches |
| Python | 3.12.x | FastAPI backend, tests and documentation tools |
| Docker Desktop | Current supported release with WSL 2 | PostgreSQL/pgvector and the backend container |
| Flutter | 3.47.5 | Android and iOS application |
| Microsoft OpenJDK | 21 LTS | Android Gradle builds |
| Android Studio | Current stable release | Android SDK, emulator and SDK Manager |
| Android SDK | Platform 36 and Build-Tools 36.0.0 | Android compilation |
| Android SDK Command-line Tools | Latest | Flutter Android tooling |
| Android NDK | 28.2.13676358, side by side | Flutter's Android native components |

PostgreSQL does not need to be installed separately; Docker Compose supplies PostgreSQL 16 with pgvector. Visual Studio and Chrome are not required because this repository targets Android and iOS, not Windows desktop or Flutter web.

## 1. Install Git

Download Git for Windows from the [official Git installer page](https://git-scm.com/install/windows), then open a new terminal and verify:

```powershell
git --version
```

## 2. Install Python 3.12

Install a Python 3.12 release using the [official Python Windows instructions](https://docs.python.org/3.12/using/windows.html). Enable the installer option that makes Python available from the terminal.

```powershell
python --version
python -m pip --version
```

The Python version must begin with `3.12` because the checked-in dependency locks were generated for Python 3.12.

## 3. Install Docker Desktop

Follow [Docker's Windows installation guide](https://docs.docker.com/desktop/setup/install/windows-install/) and use the WSL 2 backend. If WSL is missing, run these commands from an administrator PowerShell window and restart when requested:

```powershell
wsl --install
wsl --update
```

Start Docker Desktop and verify:

```powershell
docker --version
docker compose version
docker run --rm hello-world
```

## 4. Install JDK 21

Install Microsoft's supported OpenJDK 21 build:

```powershell
winget install --exact --id Microsoft.OpenJDK.21
```

The installer and manual downloads are also available from [Microsoft's OpenJDK page](https://learn.microsoft.com/en-us/java/openjdk/download). Open a new terminal and verify:

```powershell
java -version
javac -version
```

Both commands should report Java 21.

## 5. Install Flutter 3.47.5

Use Flutter's [manual installation guide](https://docs.flutter.dev/install/manual) and download the 3.47.5 Windows bundle. Extract it to a stable development folder, for example:

```text
C:\src\flutter
```

Do not place the Flutter SDK in `Program Files` or another protected directory. Add its `bin` directory to your user `PATH`, open a new terminal and verify:

```powershell
flutter --version
dart --version
```

The Flutter version must be `3.47.5` and its bundled Dart version must satisfy the constraint in `mobile/pubspec.yaml`.

## 6. Install Android Studio and Android SDK components

Download the current stable Android Studio from the [official Android Studio page](https://developer.android.com/studio). During installation, include the Android SDK, Android SDK Platform and Android Virtual Device components.

Keep the SDK in a path without spaces, such as:

```text
D:\AndroidSdk
```

In Android Studio, open **Settings → Languages & Frameworks → Android SDK**.

Under **SDK Platforms**, install:

- Android SDK Platform 36.

Under **SDK Tools**, enable **Show Package Details** and install:

- Android SDK Build-Tools 36.0.0.
- Android SDK Command-line Tools (latest).
- Android SDK Platform-Tools.
- Android Emulator.
- NDK (Side by side) version 28.2.13676358.

Android's official guide explains how to install a [specific side-by-side NDK version](https://developer.android.com/studio/projects/install-ndk).

Point Flutter at the SDK and JDK, replacing the JDK folder if your installed patch version differs:

```powershell
flutter config --android-sdk "D:\AndroidSdk"
flutter config --jdk-dir "C:\Program Files\Microsoft\jdk-21.0.12.101-hotspot"
flutter doctor --android-licenses
flutter doctor -v
```

The Android toolchain section must be green. Warnings about Chrome, Visual Studio or unavailable iOS tooling on Windows do not block Android development.

## 7. Avoid Windows paths containing spaces

Flutter package resolution and Android native tools can fail when cache or SDK paths contain spaces. Configure a space-free Pub cache:

```powershell
$env:PUB_CACHE = 'D:\FlutterPubCache'
[Environment]::SetEnvironmentVariable('PUB_CACHE', 'D:\FlutterPubCache', 'User')
```

Open a new terminal after changing persistent environment variables.

## 8. Clone and create the task branch

```powershell
git clone https://github.com/Kavee-ginty/Memora.git D:\Memora
cd D:\Memora
git switch develop
git pull --ff-only
git switch -c task/Txx-exact-name
```

Replace `task/Txx-exact-name` with the exact branch listed for a Ready task in `docs/project-management/Memora_Development_Task_Table.md`. Before creating the branch, claim the task by setting its Owner and status to **In Progress**.

## 9. Install Python dependencies

The root `requirements.txt` installs the hashed backend development dependencies and pinned documentation-tool dependencies:

```powershell
cd D:\Memora
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --require-hashes -r requirements.txt
python -m pip install --no-deps -e backend
```

Verify the backend:

```powershell
python -m ruff format --check backend
python -m ruff check backend
python -m pytest backend\tests
```

## 10. Configure and start local services

```powershell
cd D:\Memora
Copy-Item .env.example .env
docker compose --env-file .env -f infra\compose.yaml up --build
```

The local endpoints are:

- API: `http://127.0.0.1:8000`
- Interactive API documentation: `http://127.0.0.1:8000/docs`
- PostgreSQL: `127.0.0.1:5432`

Stop the services without deleting the database volume:

```powershell
docker compose --env-file .env -f infra\compose.yaml down
```

## 11. Prepare and verify the Flutter application

```powershell
cd D:\Memora\mobile
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

The APK should be created at:

```text
mobile\build\app\outputs\flutter-apk\app-debug.apk
```

To run on an emulator, open Android Studio's Device Manager, create a device using a current stable Android system image, start it, then run:

```powershell
flutter devices
flutter run
```

## 12. iOS development

iOS compilation cannot run on Windows. An iOS developer needs a supported macOS system with the current Xcode version, Xcode command-line tools and an iOS Simulator. Follow Flutter's [official iOS setup guide](https://docs.flutter.dev/platform-integration/ios/setup), then run the same `flutter pub get`, `flutter analyze` and `flutter test` checks before building in Xcode.

## Final verification checklist

```powershell
git --version
python --version
docker compose version
java -version
flutter --version
flutter doctor -v
```

Before starting a development task, also confirm its dependencies are **Done** and use its exact branch from the task table.
