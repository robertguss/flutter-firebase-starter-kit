#!/bin/bash
# Configure Firebase for each flavor.
# Update the --project, --ios-bundle-id, and --android-app-id values
# to match your Firebase projects.

set -euo pipefail

for flavor in dev staging prod; do
  echo "Configuring Firebase for flavor: $flavor"
  flutterfire configure \
    --project=your-project-$flavor \
    --out=lib/firebase_options_$flavor.dart \
    --ios-bundle-id=com.example.flutterStarterKit.$flavor \
    --android-app-id=com.example.flutter_starter_kit.$flavor \
    --android-out=android/app/src/$flavor/google-services.json \
    --ios-out=ios/config/$flavor/GoogleService-Info.plist
  echo ""
done

echo "Done! Firebase configured for all flavors."
