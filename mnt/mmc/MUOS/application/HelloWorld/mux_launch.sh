#!/bin/sh
# HELP: muOS Button Debug Tool  
# ICON: app
# GRID: Button Debug

# muOS functions
. /opt/muos/script/var/func.sh

# Set application state
echo app >/tmp/act_go

# Button Debug Tool Launcher - Module Structure Support
# Updated for clean modular architecture

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

# IMPORTANT: Set Lua module search path for require() to work
export LUA_PATH="$APPDIR/src/?.lua;$APPDIR/src/?/init.lua;;"

# Change to application directory
cd "$APPDIR"

# Launch LÖVE2D with our source directory
"$APPDIR/bin/love" "$APPDIR/src"