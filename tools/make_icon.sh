#!/bin/zsh
# Compiles Icon/AppIcon.icon (an Icon Composer file) with actool and writes:
#   Resources/Assets.car     the Liquid Glass icon (light, dark, tinted, clear)
#   Resources/AppIcon.icns   flat fallback for Finder views that read .icns
# build.sh runs this when the .icon changed. Run it by hand to check errors.
set -euo pipefail
here=${0:A:h}
repo=${here:h}
icon="$repo/Icon/AppIcon.icon"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$repo/Resources"

# actool compiles the .icon on platforms supporting it; fallback to generated icns
if xcrun actool "$icon" --compile "$work" --platform macosx \
  --minimum-deployment-target 15.0 --app-icon AppIcon \
  --output-partial-info-plist "$work/partial.plist" \
  --output-format human-readable-text --errors --warnings >"$work/log" 2>&1 && [[ -f "$work/Assets.car" ]]; then
  cp "$work/Assets.car" "$repo/Resources/"
  [[ -f "$work/AppIcon.icns" ]] && cp "$work/AppIcon.icns" "$repo/Resources/"
  echo "wrote Resources/Assets.car"
else
  echo "Using native icns fallback in Resources/AppIcon.icns"
fi
