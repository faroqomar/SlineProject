# 📘 SLine App - Project Log

This file documents every step taken in building the SLine app.

---

## ✅ Setup & Initialization

- Initialized Flutter project: `sline_app`
- Setup Git and pushed to private GitHub repo
- Created folder structure: `lib/features`, `core/models`, `core/services`, etc.

---

## 🔐 Authentication (Supabase)

- Set up Supabase project and added it to Flutter
- Created `auth_controller.dart` for sign-up and sign-in
- Implemented email/password sign-up and login
- Handled Supabase errors and user session checks
- Fixed async context usage warnings (`BuildContext`)
- Implemented logout functionality and routing to login/home

---

## 🖼️ UI Customization

- Replaced Flutter default logo with custom app logo
- Created login and signup UI with proper input validation
- Connected auth UI with controller logic

---

## 🔄 Supabase Database

- Created `users` table with necessary fields
- Set up row-level security (RLS) and auth policies
- Wrote SQL script to initialize table and rules

---

## 👤 Profile Screen

- Designed profile UI: avatar, name, email, editable fields
- Integrated image_picker for profile photo
- Fixed issues with context use after async gaps
- Added loading indicators and success messages
- Connected all profile widgets (avatar, role toggle, form, logout) to `ProfileController`
- Fixed null controllers and made all fields editable
- Pulled existing user data from Supabase into form fields (name, email, bio)
- Synced changes back to Supabase with update logic

---

## 🛠️ Project Config & Packages

- Added dependencies: `image_picker`, `supabase_flutter`, etc.
- Organized assets (logo) under `assets/images/` and declared in `pubspec.yaml`
