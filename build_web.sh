#!/bin/bash
set -e

echo "=== Make It Exist — Vercel Flutter Web Build ==="

FLUTTER_VERSION="3.24.5"
FLUTTER_DIR="$HOME/flutter-sdk"

# ── Install Flutter SDK ──────────────────────────────────────
if [ ! -d "$FLUTTER_DIR" ]; then
  echo "📦 Downloading Flutter $FLUTTER_VERSION ..."
  curl -sL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" -o /tmp/flutter.tar.xz
  mkdir -p "$FLUTTER_DIR"
  tar xf /tmp/flutter.tar.xz -C "$HOME/flutter-sdk" --strip-components=1
  rm /tmp/flutter.tar.xz
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

echo "🔧 Flutter version:"
flutter --version

# ── Disable analytics / telemetry ────────────────────────────
flutter config --no-analytics 2>/dev/null || true
dart --disable-analytics 2>/dev/null || true

# ── Build Frontend ───────────────────────────────────────────
cd frontend

echo "📥 Getting dependencies..."
flutter pub get

echo "🏗️  Building Flutter web (release)..."
flutter build web \
  --release \
  --no-web-resources-cdn \
  --dart-define=API_BASE_URL=${API_BASE_URL:-http://localhost:8080/api/v1}

echo "✅ Build complete! Output at frontend/build/web/"
ls -la build/web/
