# SLine

SLine is a freelance marketplace. Clients post project briefs and review proposals or book a service. Freelancers browse open work and respond to listings in the same Flutter app.

**Private commercial project under NDA.** This README and its captures are for authorized readers.

## App demos

[Browse open work](#browse-open-work) · [Draft a proposal](#draft-a-proposal) · [Compare booking packages](#compare-booking-packages) · [Run the app](#run-the-app)

These clips show SLine running on an iPhone 18 Pro simulator with a fictional account and listings from a local mock API.

### Browse open work

On Home, select **Tasks** to show open projects. Open **Design a brand identity** to see the budget, deadline, and full brief.

<img src="docs/assets/readme/marketplace-discovery.gif" width="440" alt="SLine switches from All to Tasks, reducing the feed from three posts to two, then opens the brand identity brief.">

### Draft a proposal

From the task details, choose **Apply Now** and enter an amount, delivery time, and cover letter. The clip ends on the completed form before submission.

<img src="docs/assets/readme/proposal-draft.gif" width="440" alt="A freelancer opens the proposal form and enters 225,000 IQD, seven days, and a cover letter.">

### Compare booking packages

On Home, select **Bookings** and open the product photo session. Switch between **Basic**, **Standard**, and **Premium** to compare prices, delivery times, and revisions before booking.

<img src="docs/assets/readme/booking-packages.gif" width="440" alt="SLine opens the product photo session and changes package tiers, updating the price, delivery time, and revision count.">

<details>
<summary>Still screenshots of the three workflows</summary>

**Home feed.** Browse tasks and bookings, or filter by listing type.

<img src="docs/assets/readme/marketplace-feed.png" width="320" alt="SLine Home feed with the All, Bookings, and Tasks filters above sample listings.">

**Task details.** Read the project brief, budget, and time left before applying.

<img src="docs/assets/readme/task-details.png" width="320" alt="The brand identity task shows the full brief, a 250,000 IQD budget, and 13 days left.">

**Proposal form.** Review the amount, delivery time, and cover letter before sending an offer.

<img src="docs/assets/readme/proposal-draft.png" width="320" alt="The filled proposal form for a 225,000 IQD offer with a seven-day delivery time.">

**Booking packages.** The Premium tier shows the price, package contents, delivery time, and revisions.

<img src="docs/assets/readme/booking-packages.png" width="320" alt="The Premium photo session shows 260,000 IQD, seven days, and three revisions.">

</details>

## Beyond the demos

The Dashboard has tabs for bookings, work, wallet activity, and the inbox. The dashboard settings let users switch between client and freelancer roles. Users can also search their conversations in Messages and show portfolio items on their profile. See the [developer guide](Sline_everything/DEVELOPER_GUIDE.md).

## Run the app

Use a complete checkout and Flutter **3.41.9**, the version pinned in CI. The package requires Dart **3.11 or later in the 3.x series**. For iOS, install Xcode and CocoaPods and start a simulator. For Android, install the Android SDK and start an emulator. See the [package manifest](pubspec.yaml) and [CI configuration](.github/workflows/ci.yml).

Ask the maintainer for an approved development Supabase project, its client key, and a test account. Confirm the URL and client key in [Supabase configuration](lib/core/services/supabase_config.dart) target that development project before you launch. The [backend setup](Sline_everything/SUPABASE_SETUP.md) documents the required schema and policies.

```sh
flutter pub get
flutter gen-l10n
flutter devices
flutter run -d <device_id>
```

Replace `<device_id>` with an ID from `flutter devices`. A fresh simulator install should open the sign-in screen. Sign in with your test account to reach Home. To follow the discovery example, use a development project with at least one open task.

Follow [Browse open work](#browse-open-work) to try the same workflow after signing in.

## Architecture and contribution

Flutter views read ViewModel state through Provider. ViewModels call services and repositories for Supabase access. The backend uses PostgreSQL, Row-Level Security, database functions, and Edge Functions. Supabase also provides authentication, storage, and realtime updates.

My six-month contract covered backend development and Supabase integration with the Flutter client and companion administration dashboard. UI/UX design was outside my role. The [dashboard repository](https://github.com/faroqomar/SlineDashbord) has its own setup.

## Development checks

```sh
flutter analyze --no-fatal-infos
flutter test --coverage
```

CI also runs formatting, MVVM boundary checks, and Android and web builds. Use the [developer guide](Sline_everything/DEVELOPER_GUIDE.md) for backend and integration test prerequisites.

- [Repository rules](AGENTS.md)
- [Contribution workflow](CONTRIBUTING.md)
- [Project structure](Sline_everything/STRUCTURE.md)
- [Source map](Sline_everything/DOC_SOURCE_MAP.md)

Rights and disclosure are governed by the project owner's agreements.
