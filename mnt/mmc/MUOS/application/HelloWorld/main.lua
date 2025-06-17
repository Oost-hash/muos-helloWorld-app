-- main.lua - Enhanced with comprehensive joystick debugging
local counter = 0
local lastButtonTime = 0
local buttonCooldown = 0.2

-- Debug info storage
local debugLines = {}
local maxDebugLines = 8

-- Add debug line with timestamp
function addDebug(text)
    local timestamp = string.format("%.2f", love.timer.getTime())
    table.insert(debugLines, 1, timestamp .. ": " .. text)
    if #debugLines > maxDebugLines then
        table.remove(debugLines)
    end
    
    -- Also try to write to file
    pcall(function()
        local file = io.open("/mnt/mmc/MUOS/application/HelloWorld/debug.log", "a")
        if file then
            file:write(os.date("%Y-%m-%d %H:%M:%S ") .. text .. "\n")
            file:close()
        end
    end)
end

function love.load()
    love.window.setTitle("Hello World - muOS")
    
    -- Screen dimensions for RG40XX-H
    screenWidth = 640
    screenHeight = 480
    
    -- Create fonts
    largeFont = love.graphics.newFont(48)
    mediumFont = love.graphics.newFont(24)
    smallFont = love.graphics.newFont(16)
    debugFont = love.graphics.newFont(12)
    
    addDebug("=== App Started ===")
    addDebug("LÖVE2D Version: " .. love.getVersion())
    
    -- Comprehensive joystick/gamepad debugging
    local joystickCount = love.joystick.getJoystickCount()
    addDebug("Total joysticks found: " .. joystickCount)
    
    if joystickCount > 0 then
        local joysticks = love.joystick.getJoysticks()
        for i, joystick in ipairs(joysticks) do
            addDebug("Joystick " .. i .. ":")
            addDebug("  Name: " .. (joystick:getName() or "Unknown"))
            addDebug("  GUID: " .. (joystick:getGUID() or "No GUID"))
            addDebug("  Is Gamepad: " .. tostring(joystick:isGamepad()))
            addDebug("  Button Count: " .. joystick:getButtonCount())
            addDebug("  Axis Count: " .. joystick:getAxisCount())
            addDebug("  Hat Count: " .. joystick:getHatCount())
            
            -- Check if it's recognized as a gamepad
            if joystick:isGamepad() then
                addDebug("  Gamepad Type: " .. (joystick:getGamepadType() or "Unknown"))
            end
        end
    else
        addDebug("ERROR: No joysticks detected!")
    end
    
    -- Check environment variables
    addDebug("ENV SDL_GAMECONTROLLER: " .. (os.getenv("SDL_GAMECONTROLLERCONFIG_FILE") or "Not set"))
    addDebug("ENV LD_LIBRARY_PATH: " .. (os.getenv("LD_LIBRARY_PATH") and "Set" or "Not set"))
    addDebug("ENV LOVE_GRAPHICS_OPENGLES: " .. (os.getenv("LOVE_GRAPHICS_USE_OPENGLES") or "Not set"))
    
    addDebug("=== Debug Complete ===")
end

function love.update(dt)
    -- Test polling method as backup
    local joysticks = love.joystick.getJoysticks()
    if #joysticks > 0 then
        local joystick = joysticks[1]
        
        -- Check all buttons by polling
        for i = 1, joystick:getButtonCount() do
            if joystick:isDown(i) then
                local currentTime = love.timer.getTime()
                if currentTime - lastButtonTime > buttonCooldown then
                    addDebug("POLLING: Button " .. i .. " pressed!")
                    
                    -- Map some common buttons
                    if i == 1 then  -- Usually B button
                        counter = counter + 1
                        addDebug("Counter incremented by polling: " .. counter)
                    elseif i == 2 then  -- Usually A button  
                        counter = 0
                        addDebug("Counter reset by polling")
                    end
                    
                    lastButtonTime = currentTime
                end
            end
        end
        
        -- Check gamepad buttons if it's a gamepad
        if joystick:isGamepad() then
            if joystick:isGamepadDown("b") then
                local currentTime = love.timer.getTime()
                if currentTime - lastButtonTime > buttonCooldown then
                    addDebug("GAMEPAD POLLING: B button pressed!")
                    counter = counter + 1
                    lastButtonTime = currentTime
                end
            end
            
            if joystick:isGamepadDown("a") then
                local currentTime = love.timer.getTime()
                if currentTime - lastButtonTime > buttonCooldown then
                    addDebug("GAMEPAD POLLING: A button pressed!")
                    counter = 0
                    lastButtonTime = currentTime
                end
            end
            
            if joystick:isGamepadDown("start") then
                addDebug("GAMEPAD POLLING: Start pressed - exiting")
                love.event.quit()
            end
        end
    end
end

-- Callback-based input (what should work but doesn't)
function love.gamepadpressed(joystick, button)
    addDebug("CALLBACK: Gamepad button pressed: " .. button)
    local currentTime = love.timer.getTime()
    
    if currentTime - lastButtonTime > buttonCooldown then
        if button == "b" then
            counter = counter + 1
            addDebug("Counter incremented by callback: " .. counter)
        elseif button == "a" then
            counter = 0
            addDebug("Counter reset by callback")
        elseif button == "start" then
            addDebug("Start pressed by callback - exiting")
            love.event.quit()
        end
        lastButtonTime = currentTime
    end
end

function love.joystickpressed(joystick, button)
    addDebug("CALLBACK: Joystick button pressed: " .. button)
    local currentTime = love.timer.getTime()
    
    if currentTime - lastButtonTime > buttonCooldown then
        -- Map raw button numbers to actions
        if button == 1 then  -- Usually B
            counter = counter + 1
            addDebug("Counter incremented by joystick callback: " .. counter)
        elseif button == 2 then  -- Usually A
            counter = 0
            addDebug("Counter reset by joystick callback")
        elseif button == 8 then  -- Usually Start
            addDebug("Start pressed by joystick callback - exiting")
            love.event.quit()
        end
        lastButtonTime = currentTime
    end
end

-- Keyboard fallback for PC testing
function love.keypressed(key)
    addDebug("KEYBOARD: Key pressed: " .. key)
    local currentTime = love.timer.getTime()
    
    if currentTime - lastButtonTime > buttonCooldown then
        if key == "space" then  -- B button equivalent
            counter = counter + 1
            addDebug("Counter incremented by keyboard: " .. counter)
        elseif key == "r" then  -- A button equivalent
            counter = 0
            addDebug("Counter reset by keyboard")
        elseif key == "escape" then  -- Start equivalent
            addDebug("Escape pressed - exiting")
            love.event.quit()
        end
        lastButtonTime = currentTime
    end
end

function love.draw()
    -- Clear with dark background
    love.graphics.clear(0.1, 0.1, 0.2)
    
    -- Title
    love.graphics.setFont(largeFont)
    love.graphics.setColor(1, 1, 1)
    local title = "Hello muOS!"
    local titleWidth = largeFont:getWidth(title)
    love.graphics.print(title, (screenWidth - titleWidth) / 2, 50)
    
    -- Counter display
    love.graphics.setFont(mediumFont)
    love.graphics.setColor(0.4, 1, 0.4)
    local counterText = "Counter: " .. counter
    local counterWidth = mediumFont:getWidth(counterText)
    love.graphics.print(counterText, (screenWidth - counterWidth) / 2, 150)
    
    -- Instructions
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0.8, 0.8, 0.8)
    local instructions = {
        "B Button: Increment (+1)",
        "A Button: Reset to 0", 
        "Start: Exit to muOS",
        "",
        "Keyboard: SPACE=B, R=A, ESC=Start"
    }
    
    for i, instruction in ipairs(instructions) do
        local textWidth = smallFont:getWidth(instruction)
        love.graphics.print(instruction, (screenWidth - textWidth) / 2, 220 + (i-1) * 20)
    end
    
    -- Gamepad status
    local joysticks = love.joystick.getJoysticks()
    local status = "Gamepad: " .. (#joysticks > 0 and "Connected (" .. #joysticks .. ")" or "Not Found")
    love.graphics.setColor(0.6, 0.6, 1)
    local statusWidth = smallFont:getWidth(status)
    love.graphics.print(status, (screenWidth - statusWidth) / 2, 350)
    
    -- Debug output (most important!)
    love.graphics.setFont(debugFont)
    love.graphics.setColor(1, 1, 0)  -- Yellow for visibility
    love.graphics.print("=== DEBUG OUTPUT ===", 10, 10)
    
    for i, line in ipairs(debugLines) do
        love.graphics.print(line, 10, 25 + (i-1) * 14)
    end
    
    -- Show FPS and memory
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("FPS: " .. love.timer.getFPS(), screenWidth - 80, screenHeight - 40)
    love.graphics.print("MEM: " .. math.floor(collectgarbage("count")) .. "KB", screenWidth - 80, screenHeight - 25)
end