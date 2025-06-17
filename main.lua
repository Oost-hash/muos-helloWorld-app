-- main.lua - muOS Hello World App (Native LÖVE2D Input)

local gamepad = nil

function love.load()
    -- Basis font voor de tekst
    font = love.graphics.newFont(32)
    
    -- Zoek naar een aangesloten gamepad
    local joysticks = love.joystick.getJoysticks()
    for i, joystick in ipairs(joysticks) do
        if joystick:isGamepad() then
            gamepad = joystick
            print("Gamepad gevonden: " .. joystick:getName())
            break
        end
    end
    
    if not gamepad then
        print("Geen gamepad gedetecteerd")
    end
end

function love.update(dt)
    -- Check gamepad input direct (polling methode)
    if gamepad then
        -- Start/Menu knop om af te sluiten
        if gamepad:isGamepadDown("start") then
            love.event.quit()
        end
    end
end

function love.draw()
    -- Donkere achtergrond
    love.graphics.clear(0.1, 0.1, 0.1, 1)
    
    -- Stel font en kleur in
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1, 1) -- Wit
    
    -- "Hello World" exact in het midden van het scherm (640x480)
    love.graphics.printf("Hello World", 0, 240 - 16, 640, "center")
    
    -- Status info
    love.graphics.setColor(0.7, 0.7, 0.7, 1) -- Grijs
    local smallFont = love.graphics.newFont(16)
    love.graphics.setFont(smallFont)
    
    if gamepad then
        love.graphics.printf("Gamepad: " .. gamepad:getName(), 0, 400, 640, "center")
        love.graphics.printf("Druk Start om af te sluiten", 0, 420, 640, "center")
    else
        love.graphics.printf("Geen gamepad - druk Escape om af te sluiten", 0, 420, 640, "center")
    end
end

-- LÖVE2D native gamepad callbacks
function love.gamepadpressed(joystick, button)
    if button == "start" then
        love.event.quit()
    end
end

-- Gamepad hotplug ondersteuning
function love.joystickadded(joystick)
    if joystick:isGamepad() and not gamepad then
        gamepad = joystick
        print("Gamepad aangesloten: " .. joystick:getName())
    end
end

function love.joystickremoved(joystick)
    if joystick == gamepad then
        gamepad = nil
        print("Gamepad losgekoppeld")
    end
end

-- Keyboard fallback voor testen op PC
function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end