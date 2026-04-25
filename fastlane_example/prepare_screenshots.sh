#!/bin/bash
set -e

FASTLANE_DIR="$(dirname "$0")"
IPHONE_SRC="$FASTLANE_DIR/screenshots/iPhone"
IPAD_SRC="$FASTLANE_DIR/screenshots/iPad"
STAGED="$FASTLANE_DIR/screenshots_staged"

asc_locale_for() {
  case "$1" in
    arabic)   echo "ar-SA" ;;
    danish)   echo "da" ;;
    dutch)    echo "nl-NL" ;;
    el)       echo "el" ;;
    en-GB)    echo "en-GB" ;;
    en-US)    echo "en-US" ;;
    es)       echo "es-MX" ;;
    fr)       echo "fr-FR" ;;
    german)   echo "de-DE" ;;
    hebrew)   echo "he" ;;
    hindi)    echo "hi" ;;
    italian)  echo "it" ;;
    jp)       echo "ja" ;;
    korean)   echo "ko" ;;
    malay)    echo "ms" ;;
    pt-BR)    echo "pt-BR" ;;
    russian)  echo "ru" ;;
    thai)     echo "th" ;;
    turkish)  echo "tr" ;;
    ukrainian) echo "uk" ;;
    zh)       echo "zh-Hans" ;;
    *)        echo "" ;;
  esac
}

# Clear and recreate staging dir
rm -rf "$STAGED"
mkdir -p "$STAGED"

# Process iPhone screenshots — flat in locale folder (deliver determines device from dimensions)
for locale_dir in "$IPHONE_SRC"/*/; do
  locale=$(basename "$locale_dir")
  asc_locale=$(asc_locale_for "$locale")

  if [ -z "$asc_locale" ]; then
    echo "Warning: no ASC locale mapping for '$locale', skipping."
    continue
  fi

  # Check for any image files
  found=0
  for f in "$locale_dir"*.png "$locale_dir"*.jpg "$locale_dir"*.PNG "$locale_dir"*.JPG; do
    [ -f "$f" ] && found=1 && break
  done

  if [ "$found" -eq 0 ]; then
    echo "No images in $locale, skipping."
    continue
  fi

  dest="$STAGED/$asc_locale"
  mkdir -p "$dest"

  echo "Processing iPhone/$locale → $asc_locale ..."
  for f in "$locale_dir"*.png "$locale_dir"*.jpg "$locale_dir"*.PNG "$locale_dir"*.JPG; do
    [ -f "$f" ] || continue
    filename=$(basename "$f")
    destfile="$dest/$filename"
    cp "$f" "$destfile"
    sips -z 2715 1242 "$destfile" --out "$destfile" > /dev/null
    sips -z 2688 1242 "$destfile" --out "$destfile" > /dev/null
  done
done

# Process iPad — en-GB only, flat in locale folder
echo "Processing iPad → en-GB ..."
mkdir -p "$STAGED/en-GB"
for f in "$IPAD_SRC"/*.png "$IPAD_SRC"/*.PNG; do
  [ -f "$f" ] || continue
  cp "$f" "$STAGED/en-GB/"
done

echo ""
echo "Done. Staged screenshots in: $STAGED"
echo "Locale folders:"
ls "$STAGED"
