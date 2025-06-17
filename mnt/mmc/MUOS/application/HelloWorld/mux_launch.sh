#!/bin/sh
# HELP: muOS Hello World with Counter
# ICON: app
# GRID: Hello World

# muOS functions
. /opt/muos/script/var/func.sh

# Set application state
echo app >/tmp/act_go

# Set application directory
APPDIR="/mnt/mmc/MUOS/application/HelloWorld"

# Set up library path for bundled dependencies
export LD_LIBRARY_PATH="$APPDIR/bin:$LD_LIBRARY_PATH"

# Configure LÖVE2D for OpenGL ES (required for ARM devices)
export LOVE_GRAPHICS_USE_OPENGLES=1

# Enable joystick background events
export SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS=1

# Set process name for muOS integration
export PROG_NAME="HelloWorld"

# Change to application directory
cd "$APPDIR"

# Launch LÖVE2D with our source directory
"$APPDIR/bin/love" "$APPDIR/src"