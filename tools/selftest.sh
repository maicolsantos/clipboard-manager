#!/bin/zsh
# Runs the in-app self-test against a fresh store in /tmp. Exit code 0 when every check passed.
set -u
rm -rf ~/Library/Saved\ Application\ State/com.maicolsantos.clips.savedState
store=/tmp/Clips-self.store
rm -f $store $store-shm $store-wal
app="/Applications/Clips.app/Contents/MacOS/Clips"
[[ -x "$app" ]] || app="$HOME/Applications/Clips.app/Contents/MacOS/Clips"
APP_STORE=$store "$app" --selftest
