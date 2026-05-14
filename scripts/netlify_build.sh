#!/usr/bin/env bash

# Builds the Flutter web bundle for Netlify deploy previews.
#
# Netlify does not provide Flutter by default, so this script installs the same
# Flutter version used by GitHub Actions into the build cache before running the
# normal web build. Keeping this in the repo avoids hidden Netlify UI state.
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.41.9}"
FLUTTER_HOME="${FLUTTER_HOME:-${HOME}/.cache/flutter-${FLUTTER_VERSION}}"

if [ ! -x "${FLUTTER_HOME}/bin/flutter" ]; then
  rm -rf "${FLUTTER_HOME}"
  git clone \
    --depth 1 \
    --branch "${FLUTTER_VERSION}" \
    https://github.com/flutter/flutter.git \
    "${FLUTTER_HOME}"
fi

export PATH="${FLUTTER_HOME}/bin:${PATH}"

flutter config --enable-web
flutter pub get
flutter build web --release
