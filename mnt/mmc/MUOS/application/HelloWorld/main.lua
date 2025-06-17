-- muOS Hello World with Counter
-- main.lua

function love.load()
    -- Gamepad setup
    local joysticks = love.joystick.getJoysticks()
    gamepad = joysticks[1]
    
    -- Counter
    counter = 0
    
    -- Font setup voor 640x480 display
    font = love.graphics.newFont(24)
    smallFont = love.graphics.newFont(16)
    love.graphics.setFont(font)
    
    -- Screen info
    screenWidth = 640
    screenHeight = 480
    
    -- Button press timing
    buttonTimer = 0
    buttonCooldown = 0.2  -- Voorkom dubbele registratie
    
    print("muOS Hello World started!")
end

function love.update(dt)
    -- Button cooldown timer
    if buttonTimer > 0 then
        buttonTimer = buttonTimer - dt
    end
end

function love.draw()
    -- Achtergrond
    love.graphics.clear(0.1, 0.1, 0.2)
    
    -- Title
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)
    local title = "Hello muOS World!"
    local titleWidth = font:getWidth(title)
    love.graphics.print(title, (screenWidth - titleWidth) / 2, 80)
    
    -- Counter
    love.graphics.setColor(0, 1, 0)  -- Groen
    local counterText = "Counter: " .. counter
    local counterWidth = font:getWidth(counterText)
    love.graphics.print(counterText, (screenWidth - counterWidth) / 2, 180)
    
    -- Instructions
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("B Button: Counter +1", 50, 280)
    love.graphics.print("A Button: Reset Counter", 50, 310)
    love.graphics.print("Start: Exit", 50, 340)
    
    -- Status
    love.graphics.setColor(0.5, 0.5, 0.5)
    if gamepad then
        love.graphics.print("Gamepad: Connected", 10, screenHeight - 30)
    else
        love.graphics.print("No gamepad detected", 10, screenHeight - 30)
    end
end

function love.gamepadpressed(joystick, button)
    -- Check cooldown
    if buttonTimer > 0 then
        return
    end
    
    if button == "b" then
        counter = counter + 1
        buttonTimer = buttonCooldown
        print("B pressed, counter: " .. counter)
    elseif button == "a" then
        counter = 0
        buttonTimer = buttonCooldown
        print("Counter reset")
    elseif button == "start" then
        print("Exiting...")
        love.event.quit()
    end
end

-- Keyboard fallback voor development
function love.keypressed(key)
    if key == "space" then
        love.gamepadpressed(nil, "b")
    elseif key == "r" then
        love.gamepadpressed(nil, "a")
    elseif key == "escape" then
        love.event.quit()
    end
end

-- Gamepad connection handlers
function love.joystickadded(joystick)
    gamepad = joystick
    print("Gamepad connected: " .. joystick:getName())
end

function love.joystickremoved(joystick)
    if gamepad == joystick then
        gamepad = nil
        print("Gamepad disconnected")
    end
end