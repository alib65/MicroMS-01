#!/bin/zsh
set -eu
app_dir="${0:A:h}"
if [[ -x /Applications/SuperCollider.app/Contents/MacOS/sclang ]]; then
  sc_lang=/Applications/SuperCollider.app/Contents/MacOS/sclang
  sc_library=/Applications/SuperCollider.app/Contents/Resources/SCClassLibrary
elif command -v sclang >/dev/null 2>&1; then
  exec sclang "$app_dir/MicroMS-01.scd"
else
  print 'SuperCollider is required. Install the Qt build from https://supercollider.github.io/downloads'
  exit 1
fi
cd "$app_dir"
exec "$sc_lang" -D -a --include-path "$sc_library" "$app_dir/Standalone.scd"
