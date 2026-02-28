#!/usr/bin/env bash
set -euo pipefail
FLUTTER_VERSION="3.38.7"
echo "📦 Installing Flutter ${FLUTTER_VERSION}..."
curl -sSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" | tar -xJ -C "$HOME"
export PATH="$HOME/flutter/bin:$HOME/flutter/bin/cache/dart-sdk/bin:$PATH"
flutter --version
flutter config --no-analytics
flutter precache --web
flutter pub get
flutter build web --release
echo "✅ Build complete!"