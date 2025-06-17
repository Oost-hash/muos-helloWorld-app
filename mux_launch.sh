#!/bin/bash
# HELP: Hello World
# ICON: helloworld
# GRID: helloworld

. /opt/muos/script/var/func.sh

echo app >/tmp/act_go

# Environment setup
export LD_LIBRARY_PATH="$APPDIR/bin/libs.aarch64:$LD_LIBRARY_PATH"
export LOVE_GRAPHICS_USE_OPENGLES=1

# SDL gamepad ondersteuning
export SDL_GAMECONTROLLERCONFIG_FILE="/usr/lib/gamecontrollerdb.txt"
export SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS=1

# Launch app direct (geen gptokeyb2 nodig)
cd "$APPDIR"
"$APPDIR/bin/love" "$APPDIR/src"