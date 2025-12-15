---
description: Steps to deploy SLine to iOS (TestFlight/AppStore)
---

# iOS Deployment Workflow

## Prerequisites
- [ ] Xcode installed & updated.
- [ ] Apple Developer Account active.
- [ ] Certificates and Profiles installed.

## 1. Prepare Environment
- [ ] Run `flutter clean`.
- [ ] Run `flutter pub get`.
- [ ] Update version in `pubspec.yaml` (increment `version: x.y.z+BuildNumber`).

## 2. Build Settings
- [ ] Open `ios/Runner.xcworkspace`.
- [ ] Check **Signing & Capabilities**:
    - [ ] Team selected.
    - [ ] Bundle Identifier matches App Store Connect.
- [ ] Check **Info.plist**:
    - [ ] Permissions descriptions present (Camera, Photo Library, etc.).

## 3. Build Archive
```bash
# Build IPA
flutter build ipa --export-options-plist=ios/ExportOptions.plist
```
*Note: If no export plist exists, open Xcode -> Product -> Archive.*

## 4. Upload
- [ ] Use **Transporter** app or Xcode Organizer to upload the `.ipa`.
- [ ] Wait for processing in App Store Connect.

## 5. Verify
- [ ] Check TestFlight for the new build.
- [ ] Test critical flows (Auth, Push Notifications, Payments).
