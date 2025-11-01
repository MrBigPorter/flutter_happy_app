#!/usr/bin/env bash
set -e
flutter run --dart-define-from-file=lib/env/dev.json "$@"