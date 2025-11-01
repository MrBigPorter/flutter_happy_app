#!/usr/bin/env bash
set -e
flutter build apk --release  --dart-define-from-file=lib/env/prod.json
flutter build ios --release  --dart-define-from-file=lib/env/prod.json