#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="BeatBerry"
BINARY_NAME="BeatBerryMacOS"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
DMG_PATH="$DIST_DIR/beatberry.dmg"
DMG_STAGE_DIR="$DIST_DIR/dmg-root"
ICON_ASSET_CATALOG="$ROOT_DIR/Sources/App/Resources/Assets.xcassets"
ICON_NAME="AppIcon.icns"
FRAMEWORKS_DIR="$APP_DIR/Contents/Frameworks"
THIRD_PARTY_NOTICES_SOURCE="$ROOT_DIR/../THIRD_PARTY_NOTICES.md"

FFMPEG_SOURCE="${BEATBERRY_FFMPEG_SOURCE:-}"
SIGN_IDENTITY="${BEATBERRY_CODESIGN_IDENTITY:-}"
NOTARY_PROFILE="${BEATBERRY_NOTARY_PROFILE:-}"

if [[ -z "$FFMPEG_SOURCE" ]]; then
  if command -v ffmpeg >/dev/null 2>&1; then
    FFMPEG_SOURCE="$(command -v ffmpeg)"
  elif [[ -x "/opt/homebrew/bin/ffmpeg" ]]; then
    FFMPEG_SOURCE="/opt/homebrew/bin/ffmpeg"
  elif [[ -x "/usr/local/bin/ffmpeg" ]]; then
    FFMPEG_SOURCE="/usr/local/bin/ffmpeg"
  fi
fi

if [[ -z "$FFMPEG_SOURCE" || ! -x "$FFMPEG_SOURCE" ]]; then
  echo "[ERROR] Unable to find ffmpeg executable."
  echo "        Set BEATBERRY_FFMPEG_SOURCE=/path/to/ffmpeg."
  exit 1
fi

bundle_ffmpeg_dependencies() {
  local ffmpeg_bin="$APP_DIR/Contents/Resources/ffmpeg"
  mkdir -p "$FRAMEWORKS_DIR"

  local -a queue=("$ffmpeg_bin")
  local index=0
  local seen_file
  seen_file="$(mktemp)"

  while [[ $index -lt ${#queue[@]} ]]; do
    local current="${queue[$index]}"
    index=$((index + 1))

    [[ -z "$current" ]] && continue
    if grep -Fqx "$current" "$seen_file"; then
      continue
    fi
    printf '%s\n' "$current" >> "$seen_file"

    while IFS= read -r dep; do
      [[ -z "$dep" ]] && continue
      case "$dep" in
        /System/*|/usr/lib/*|@executable_path/*|@loader_path/*|@rpath/*)
          continue
          ;;
      esac
      if [[ ! -f "$dep" ]]; then
        echo "      warning: unresolved dependency: $dep"
        continue
      fi

      local dep_name dep_target new_ref
      dep_name="$(basename "$dep")"
      dep_target="$FRAMEWORKS_DIR/$dep_name"

      if [[ ! -f "$dep_target" ]]; then
        cp "$dep" "$dep_target"
        chmod u+w "$dep_target" || true
      fi

      if [[ "$current" == "$ffmpeg_bin" ]]; then
        new_ref="@executable_path/../Frameworks/$dep_name"
      else
        new_ref="@loader_path/$dep_name"
      fi

      install_name_tool -change "$dep" "$new_ref" "$current" 2>/dev/null || true
      queue+=("$dep_target")
    done < <(otool -L "$current" | awk 'NR>1 {print $1}')

  done

  rm -f "$seen_file"
}

echo "[1/7] Swift release build"
cd "$ROOT_DIR"
swift build -c release

echo "[2/7] Create .app bundle"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$ROOT_DIR/.build/release/$BINARY_NAME" "$APP_DIR/Contents/MacOS/$BINARY_NAME"
cp "$ROOT_DIR/packaging/Info.plist" "$APP_DIR/Contents/Info.plist"

if [[ -d "$ICON_ASSET_CATALOG" ]] && command -v xcrun >/dev/null 2>&1; then
  ACTOOL_TMP_DIR="$(mktemp -d "$DIST_DIR/actool.XXXXXX")"
  if xcrun actool "$ICON_ASSET_CATALOG" \
    --compile "$ACTOOL_TMP_DIR" \
    --platform macosx \
    --minimum-deployment-target 13.0 \
    --app-icon AppIcon \
    --output-partial-info-plist "$ACTOOL_TMP_DIR/asset-info.plist" \
    >/dev/null 2>&1; then
    if [[ -f "$ACTOOL_TMP_DIR/$ICON_NAME" ]]; then
      cp "$ACTOOL_TMP_DIR/$ICON_NAME" "$APP_DIR/Contents/Resources/$ICON_NAME"
    fi
    if [[ -f "$ACTOOL_TMP_DIR/Assets.car" ]]; then
      cp "$ACTOOL_TMP_DIR/Assets.car" "$APP_DIR/Contents/Resources/Assets.car"
    fi
    echo "      icon bundled: $ICON_NAME"
  else
    echo "      icon bundle skipped (actool failed)"
  fi
  rm -rf "$ACTOOL_TMP_DIR"
else
  echo "      icon bundle skipped (missing AppIcons or xcrun)"
fi

echo "[3/7] Bundle ffmpeg"
cp "$FFMPEG_SOURCE" "$APP_DIR/Contents/Resources/ffmpeg"
chmod +x "$APP_DIR/Contents/MacOS/$BINARY_NAME" "$APP_DIR/Contents/Resources/ffmpeg"
if [[ -f "$THIRD_PARTY_NOTICES_SOURCE" ]]; then
  cp "$THIRD_PARTY_NOTICES_SOURCE" "$APP_DIR/Contents/Resources/THIRD_PARTY_NOTICES.md"
fi
bundle_ffmpeg_dependencies

if [[ -n "$SIGN_IDENTITY" ]]; then
  echo "[4/7] Codesign app with identity: $SIGN_IDENTITY"
  if [[ -d "$FRAMEWORKS_DIR" ]]; then
    while IFS= read -r dylib; do
      codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$dylib"
    done < <(find "$FRAMEWORKS_DIR" -type f -name "*.dylib" | sort)
  fi
  codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP_DIR/Contents/Resources/ffmpeg"
  codesign --force --deep --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP_DIR"
else
  echo "[4/7] Codesign app skipped (BEATBERRY_CODESIGN_IDENTITY not set)"
fi

echo "[5/7] Build DMG"
rm -f "$DMG_PATH"
rm -rf "$DMG_STAGE_DIR"
mkdir -p "$DMG_STAGE_DIR"
cp -R "$APP_DIR" "$DMG_STAGE_DIR/$APP_NAME.app"
ln -s /Applications "$DMG_STAGE_DIR/Applications"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_STAGE_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"
rm -rf "$DMG_STAGE_DIR"

if [[ -n "$SIGN_IDENTITY" ]]; then
  echo "[6/7] Codesign DMG"
  codesign --force --timestamp --sign "$SIGN_IDENTITY" "$DMG_PATH"
else
  echo "[6/7] DMG codesign skipped (BEATBERRY_CODESIGN_IDENTITY not set)"
fi

if [[ -n "$NOTARY_PROFILE" ]]; then
  if [[ -z "$SIGN_IDENTITY" ]]; then
    echo "[ERROR] Notarization requires BEATBERRY_CODESIGN_IDENTITY."
    exit 1
  fi
  echo "[7/7] Notarize and staple DMG with profile: $NOTARY_PROFILE"
  xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG_PATH"
  xcrun stapler validate "$DMG_PATH"
else
  echo "[7/7] Notarization skipped (BEATBERRY_NOTARY_PROFILE not set)"
fi

echo ""
echo "Done."
echo "APP: $APP_DIR"
echo "DMG: $DMG_PATH"
