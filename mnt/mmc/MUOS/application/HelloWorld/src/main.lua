-- Hello World Development Tool with Button Mapping
-- State machine: FIRST_TIME_SETUP -> NORMAL_MODE -> REMAPPING_MODE

-- App States
local STATE_FIRST_TIME_SETUP = "first_time_setup"
local STATE_NORMAL_MODE = "normal_mode" 
local STATE_REMAPPING_MODE = "remapping_mode"

-- Current state
local currentState = STATE_FIRST_TIME_SETUP
local counter = 0
local frameRate = 0
local memoryUsage = 0

-- Mapping setup
local mappingFile = "/mnt/mmc/MUOS/application/HelloWorld/device_mapping.lua"
local currentJoystick = nil
local deviceMapping = {}
local mappingSequence = {
    {key = "button_a", instruction = "Press the A button\n(usually bottom face button)"},
    {key = "button_b", instruction = "Press the B button\n(usually right face button)"},
    {key = "button_x", instruction = "Press the X button\n(usually left face button)"},
    {key = "button_y", instruction = "Press the Y button\n(usually top face button)"},
    {key = "dpad_up", instruction = "Press D-PAD UP"},
    {key = "dpad_down", instruction = "Press D-PAD DOWN"},
    {key = "dpad_left", instruction = "Press D-PAD LEFT"},
    {key = "dpad_right", instruction = "Press D-PAD RIGHT"},
    {key = "trigger_l1", instruction = "Press L1 (left shoulder)"},
    {key = "trigger_l2", instruction = "Press L2 (left trigger)"},
    {key = "trigger_r1", instruction = "Press R1 (right shoulder)"},
    {key = "trigger_r2", instruction = "Press R2 (right trigger)"},
    {key = "button_start", instruction = "Press START button"},
    {key = "button_menu", instruction = "Press MENU button\n(or SELECT if no menu)"},
    {key = "joystick_left_click", instruction = "Press LEFT JOYSTICK\n(push stick down)"},
    {key = "joystick_right_click", instruction = "Press RIGHT JOYSTICK\n(push stick down)"}
}

local currentMappingStep = 1
local waitingForInput = false
local setupComplete = false

-- Visual elements
local titleFont = nil
local counterFont = nil
local instructionFont = nil
local debugFont = nil

-- Performance tracking
local frameCount = 0
local lastSecond = 0

function love.load()
    -- Setup fonts
    titleFont = love.graphics.newFont(24)
    counterFont = love.graphics.newFont(48)
    instructionFont = love.graphics.newFont(18)
    debugFont = love.graphics.newFont(12)
    
    love.graphics.setBackgroundColor(0.1, 0.1, 0.2)
    
    -- Initialize joystick
    initializeJoystick()
    
    -- Check if mapping already exists
    if loadExistingMapping() then
        currentState = STATE_NORMAL_MODE
        print("Existing mapping loaded, starting in normal mode")
    else
        currentState = STATE_FIRST_TIME_SETUP
        waitingForInput = true
        print("No mapping found, starting first-time setup")
    end
    
    lastSecond = love.timer.getTime()
end

function love.conf(t)
    t.title = "Hello World Development Tool"
    t.window.width = 640
    t.window.height = 480
    t.window.vsync = true
    t.window.resizable = false
end

function initializeJoystick()
    local joysticks = love.joystick.getJoysticks()
    if #joysticks > 0 then
        currentJoystick = joysticks[1]
        print("Joystick detected: " .. currentJoystick:getName())
    else
        print("WARNING: No joystick detected!")
    end
end

function loadExistingMapping()
    local file = io.open(mappingFile, "r")
    if file then
        local content = file:read("*all")
        file:close()
        
        -- Simple parsing of the mapping file
        -- Look for deviceMapping = { ... }
        local mappingStart = content:find("deviceMapping%s*=%s*{")
        if mappingStart then
            print("Found existing device mapping")
            -- Load the mapping (simplified - you might want more robust parsing)
            local chunk, err = load("local " .. content .. "\nreturn deviceMapping")
            if chunk then
                deviceMapping = chunk() or {}
                return true
            else
                print("Error loading mapping: " .. (err or "unknown"))
            end
        end
    end
    return false
end

function saveMappingToFile()
    local file = io.open(mappingFile, "w")
    if not file then
        print("ERROR: Cannot write mapping file")
        return false
    end
    
    file:write("-- Generated Device Mapping for muOS\n")
    file:write("-- Device: " .. (currentJoystick and currentJoystick:getName() or "Unknown") .. "\n")
    file:write("-- Generated: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n")
    file:write("local deviceMapping = {\n")
    
    for key, mapping in pairs(deviceMapping) do
        file:write(string.format("    %s = {type = \"%s\", id = %s},\n", 
            key, mapping.type, tostring(mapping.id)))
    end
    
    file:write("}\n\nreturn deviceMapping\n")
    file:close()
    
    print("Mapping saved to: " .. mappingFile)
    return true
end

function recordMapping(inputType, inputId)
    if waitingForInput and currentMappingStep <= #mappingSequence then
        local currentMapping = mappingSequence[currentMappingStep]
        deviceMapping[currentMapping.key] = {
            type = inputType,
            id = inputId
        }
        
        print("Mapped " .. currentMapping.key .. " to " .. inputType .. ":" .. tostring(inputId))
        
        currentMappingStep = currentMappingStep + 1
        
        if currentMappingStep > #mappingSequence then
            -- Setup complete
            setupComplete = true
            waitingForInput = false
            saveMappingToFile()
            currentState = STATE_NORMAL_MODE
            print("Mapping setup complete!")
        else
            -- Continue with next mapping
            waitingForInput = true
        end
    end
end

function isButtonPressed(buttonKey)
    local mapping = deviceMapping[buttonKey]
    if not mapping or not currentJoystick then
        return false
    end
    
    if mapping.type == "gamepad_button" then
        return currentJoystick:isGamepadDown(mapping.id)
    elseif mapping.type == "joystick_button" then
        return currentJoystick:isDown(mapping.id)
    elseif mapping.type == "joystick_hat" then
        return currentJoystick:getHat(mapping.id) == mapping.direction
    end
    
    return false
end

-- Input callbacks for mapping setup
function love.gamepadpressed(joystick, button)
    if currentState == STATE_FIRST_TIME_SETUP or currentState == STATE_REMAPPING_MODE then
        recordMapping("gamepad_button", button)
    elseif currentState == STATE_NORMAL_MODE then
        handleNormalModeInput("gamepad_button", button)
    end
end

function love.joystickpressed(joystick, button)
    if currentState == STATE_FIRST_TIME_SETUP or currentState == STATE_REMAPPING_MODE then
        recordMapping("joystick_button", button)
    elseif currentState == STATE_NORMAL_MODE then
        handleNormalModeInput("joystick_button", button)
    end
end

function love.joystickhat(joystick, hat, direction)
    if direction ~= "c" then -- Not centered
        if currentState == STATE_FIRST_TIME_SETUP or currentState == STATE_REMAPPING_MODE then
            recordMapping("joystick_hat", hat, direction)
        elseif currentState == STATE_NORMAL_MODE then
            handleNormalModeInput("joystick_hat", hat, direction)
        end
    end
end

function love.keypressed(key, scancode, isrepeat)
    if not isrepeat then
        if currentState == STATE_FIRST_TIME_SETUP or currentState == STATE_REMAPPING_MODE then
            recordMapping("keyboard", key)
        elseif currentState == STATE_NORMAL_MODE then
            handleNormalModeInput("keyboard", key)
        end
    end
end

function handleNormalModeInput(inputType, inputId, extra)
    -- Check if this input matches any of our mapped buttons
    for buttonKey, mapping in pairs(deviceMapping) do
        if mapping.type == inputType and mapping.id == inputId then
            if extra and mapping.direction and mapping.direction ~= extra then
                goto continue
            end
            
            -- Handle the mapped button
            if buttonKey == "button_a" then
                counter = counter + 1
                print("A pressed: Counter = " .. counter)
            elseif buttonKey == "button_b" then
                counter = 0
                print("B pressed: Counter reset")
            elseif buttonKey == "button_x" then
                print("X pressed: Starting remapping...")
                startRemapping()
            elseif buttonKey == "button_start" or buttonKey == "button_menu" then
                -- Check if both start and menu are pressed for exit
                if isButtonPressed("button_start") and isButtonPressed("button_menu") then
                    print("Menu + Start: Exiting...")
                    love.event.quit()
                end
            end
            
            ::continue::
        end
    end
end

function startRemapping()
    currentState = STATE_REMAPPING_MODE
    currentMappingStep = 1
    waitingForInput = true
    deviceMapping = {} -- Clear existing mapping
    print("Remapping started - press buttons as instructed")
end

function love.update(dt)
    -- Update frame rate
    frameCount = frameCount + 1
    local currentTime = love.timer.getTime()
    if currentTime - lastSecond >= 1.0 then
        frameRate = frameCount
        frameCount = 0
        lastSecond = currentTime
        
        -- Update memory usage (approximate)
        memoryUsage = math.floor(collectgarbage("count"))
    end
    
    -- Check joystick connection
    if currentJoystick and not currentJoystick:isConnected() then
        print("WARNING: Joystick disconnected")
        initializeJoystick()
    end
end

function love.draw()
    love.graphics.setColor(1, 1, 1)
    
    if currentState == STATE_FIRST_TIME_SETUP or currentState == STATE_REMAPPING_MODE then
        drawSetupScreen()
    elseif currentState == STATE_NORMAL_MODE then
        drawNormalScreen()
    end
end

function drawSetupScreen()
    love.graphics.setFont(titleFont)
    local title = (currentState == STATE_FIRST_TIME_SETUP) and "First-Time Button Setup" or "Button Remapping"
    love.graphics.printf(title, 0, 50, 640, "center")
    
    if currentMappingStep <= #mappingSequence then
        local currentMapping = mappingSequence[currentMappingStep]
        
        -- Progress
        love.graphics.setFont(debugFont)
        love.graphics.setColor(1, 1, 0)
        love.graphics.printf("Step " .. currentMappingStep .. " of " .. #mappingSequence, 0, 100, 640, "center")
        
        -- Current instruction
        love.graphics.setFont(instructionFont)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(currentMapping.instruction, 0, 200, 640, "center")
        
        -- Waiting indicator
        if waitingForInput then
            love.graphics.setColor(0, 1, 0)
            love.graphics.printf("Waiting for input...", 0, 300, 640, "center")
        end
        
        -- Progress bar
        local progress = (currentMappingStep - 1) / #mappingSequence
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", 120, 350, 400, 20)
        love.graphics.setColor(0, 1, 0)
        love.graphics.rectangle("fill", 120, 350, 400 * progress, 20)
    else
        love.graphics.setFont(instructionFont)
        love.graphics.setColor(0, 1, 0)
        love.graphics.printf("Setup Complete!\nSwitching to normal mode...", 0, 200, 640, "center")
    end
    
    -- Show detected mappings so far
    love.graphics.setFont(debugFont)
    love.graphics.setColor(0.8, 0.8, 0.8)
    local y = 400
    local count = 0
    for key, mapping in pairs(deviceMapping) do
        if count >= 5 then break end -- Show only first 5
        love.graphics.print(key .. " = " .. mapping.type .. ":" .. tostring(mapping.id), 20, y)
        y = y + 15
        count = count + 1
    end
end

function drawNormalScreen()
    -- Title
    love.graphics.setFont(titleFont)
    love.graphics.printf("Hello World Development Tool", 0, 20, 640, "center")
    
    -- Counter (main feature)
    love.graphics.setFont(counterFont)
    love.graphics.setColor(0, 1, 0) -- Green
    love.graphics.printf("Counter: " .. tostring(counter), 0, 100, 640, "center")
    
    -- Performance info
    love.graphics.setFont(instructionFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("FPS: " .. frameRate, 0, 180, 640, "center")
    love.graphics.printf("Memory: " .. memoryUsage .. " KB", 0, 200, 640, "center")
    
    -- Controls
    love.graphics.setFont(debugFont)
    love.graphics.setColor(0.8, 0.8, 1)
    love.graphics.printf("A = Counter+1 | B = Reset | X = Remap | Menu+Start = Exit", 0, 250, 640, "center")
    
    -- Joystick status
    if currentJoystick then
        love.graphics.setColor(0, 1, 0)
        love.graphics.printf("Device: " .. currentJoystick:getName(), 0, 280, 640, "center")
    else
        love.graphics.setColor(1, 0, 0)
        love.graphics.printf("No controller detected", 0, 280, 640, "center")
    end
    
    -- Show some current mappings
    love.graphics.setFont(debugFont)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Current Button Mappings:", 20, 320)
    local y = 340
    local count = 0
    for key, mapping in pairs(deviceMapping) do
        if count >= 8 then break end
        love.graphics.print(key .. " = " .. mapping.type .. ":" .. tostring(mapping.id), 20, y)
        y = y + 15
        count = count + 1
    end
end