#!/bin/bash
set -e

SCREENSHOTS_DIR="$(dirname "$0")/screenshots"

for locale_dir in "$SCREENSHOTS_DIR"/*/; do
  locale=$(basename "$locale_dir")
  [ "$locale" = "iPad" ] && continue

  png_count=$(find "$locale_dir" -maxdepth 1 -name "*.png" | wc -l | tr -d ' ')
  [ "$png_count" -eq 0 ] && continue

  echo "Resizing $locale ($png_count images)..."
  for img in "$locale_dir"*.png; do
    [ -f "$img" ] || continue
    sips -z 2715 1242 "$img" --out "$img" > /dev/null
    sips -z 2688 1242 "$img" --out "$img" > /dev/null
  done
done

echo "Done resizing iPhone screenshots."
