-- LÖVE2D Configuration for muOS
-- conf.lua

function love.conf(t)
    t.identity = "muos_hello_world"
    t.version = "11.4"
    t.console = false
    
    -- Window settings voor RG40XX-H
    t.window.title = "Hello muOS World"
    t.window.width = 640
    t.window.height = 480
    t.window.borderless = true
    t.window.resizable = false
    t.window.fullscreen = false
    t.window.vsync = 1
    
    -- Performance settings voor handheld
    t.window.msaa = 0
    t.window.display = 1
    t.window.highdpi = false
    
    -- Modules (alleen wat we nodig hebben)
    t.modules.audio = false      -- Geen audio nodig
    t.modules.data = true
    t.modules.event = true
    t.modules.font = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.joystick = true    -- Voor gamepad
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = false      -- Geen muis op handheld
    t.modules.physics = false    -- Niet nodig
    t.modules.sound = false      -- Geen audio
    t.modules.system = true
    t.modules.thread = false
    t.modules.timer = true
    t.modules.touch = false
    t.modules.video = false
    t.modules.window = true
end