#!/usr/bin/env bash
DIR="$HOME/.config/hypr/lockscreen"
export QML2_IMPORT_PATH="$DIR/imports:$QML2_IMPORT_PATH"
export QML_XHR_ALLOW_FILE_READ=1
killall -9 hyprlock 2>/dev/null || true
quickshell -p "$DIR/lock_shell.qml"
