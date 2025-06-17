#!/bin/sh
# HELP: muOS Hello World with Counter
# ICON: app
# GRID: Hello World

# muOS functions
. /opt/muos/script/var/func.sh

# Set application state
echo app >/tmp/act_go

# Application directory
APPDIR="$(GET_VAR "device" "storage/rom/mount")/MUOS/application/HelloWorld"
BINDIR="$APPDIR/bin"
GPTOKEYB="$(GET_VAR "device" "storage/rom/mount")/MUOS/emulator/gptokeyb/gptokeyb2"

# Set library path
LD_LIBRARY_PATH="$APPDIR/libs.aarch64:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH

# OpenGL ES for ARM64
export LOVE_GRAPHICS_USE_OPENGLES=1

# Change to app directory
cd "$APPDIR" || exit

# Set foreground process
SET_VAR "system" "foreground_process" "love"

# Start gptokeyb2 for input
$GPTOKEYB "love" -c "$APPDIR/controls.gptk" &
GPTOKEYB_PID=$!

# Run LÖVE2D application
"$BINDIR/love" .

# Cleanup
kill -9 $GPTOKEYB_PID 2>/dev/null

# Return to muOS
exit 0