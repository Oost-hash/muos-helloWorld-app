-- input/detector.lua - Raw Input Detection Engine
-- Handles all raw input detection and filtering

local config = require("config")
local helpers = require("utils.helpers")

local detector = {}

-- Input log for debugging
detector.inputLog = {}
detector.maxLogEntries = 50

-- Add input to log (for debugging purposes)
function detector.logInput(inputType, inputId, extra, timestamp)
    local entry = {
        type = inputType,
        id = inputId,
        extra = extra,
        time = timestamp or helpers.getCurrentTime(),
        description = detector.getInputDescription(inputType, inputId, extra)
    }
    
    table.insert(detector.inputLog, 1, entry)  -- Insert at beginning
    
    -- Keep log size manageable
    if #detector.inputLog > detector.maxLogEntries then
        table.remove(detector.inputLog, detector.maxLogEntries + 1)
    end
    
    return entry
end

-- Get human-readable description of input
function detector.getInputDescription(inputType, inputId, extra)
    local desc = inputType .. ":" .. tostring(inputId)
    
    if extra then
        if inputType:find("axis") then
            desc = desc .. ":" .. helpers.getAxisDirection(tonumber(extra))
        elseif inputType:find("hat") then
            desc = desc .. ":" .. helpers.getHatDirectionName(extra)
        else
            desc = desc .. ":" .. tostring(extra)
        end
    end
    
    return desc
end

-- Check if input should be processed (filtering)
function detector.shouldProcessInput(inputType, inputId, extra)
    -- Always process button presses
    if inputType:find("button") then
        return true
    end
    
    -- For axes, check if movement is significant
    if inputType:find("axis") then
        if extra and math.abs(tonumber(extra)) > config.AXIS_THRESHOLD then
            return true
        end
        return false
    end
    
    -- For hats, ignore center position
    if inputType:find("hat") then
        return extra ~= "c"
    end
    
    return true
end

-- Process joystick button input
function detector.processJoystickButton(joystick, button, pressed)
    if pressed then  -- Only process button press, not release
        local entry = detector.logInput("joystick_button", button, nil)
        print("Input detected: " .. entry.description)
        return "joystick_button", button, nil
    end
    return nil
end

-- Process joystick axis input
function detector.processJoystickAxis(joystick, axis, value)
    if detector.shouldProcessInput("joystick_axis", axis, value) then
        local entry = detector.logInput("joystick_axis", axis, value)
        print("Input detected: " .. entry.description)
        return "joystick_axis", axis, value
    end
    return nil
end

-- Process joystick hat input  
function detector.processJoystickHat(joystick, hat, direction)
    if detector.shouldProcessInput("joystick_hat", hat, direction) then
        local entry = detector.logInput("joystick_hat", hat, direction)
        print("Input detected: " .. entry.description)
        return "joystick_hat", hat, direction
    end
    return nil
end

-- Process gamepad button input (for devices that support gamepad API)
function detector.processGamepadButton(joystick, button, pressed)
    if pressed then
        local entry = detector.logInput("gamepad_button", button, nil)
        print("Input detected: " .. entry.description)
        return "gamepad_button", button, nil
    end
    return nil
end

-- Process gamepad axis input
function detector.processGamepadAxis(joystick, axis, value)
    if detector.shouldProcessInput("gamepad_axis", axis, value) then
        local entry = detector.logInput("gamepad_axis", axis, value)
        print("Input detected: " .. entry.description)
        return "gamepad_axis", axis, value
    end
    return nil
end

-- Get current input states (for real-time display)
function detector.getCurrentInputStates(joystick)
    if not joystick or not joystick:isConnected() then
        return {
            buttons = {},
            axes = {},
            hats = {}
        }
    end
    
    local states = {
        buttons = {},
        axes = {},
        hats = {}
    }
    
    -- Get current button states
    for i = 1, joystick:getButtonCount() do
        states.buttons[i] = joystick:isDown(i)
    end
    
    -- Get current axis values
    for i = 1, joystick:getAxisCount() do
        states.axes[i] = joystick:getAxis(i)
    end
    
    -- Get current hat states
    for i = 1, joystick:getHatCount() do
        states.hats[i] = joystick:getHat(i)
    end
    
    return states
end

-- Check if specific button is currently pressed (for combo detection)
function detector.isButtonPressed(joystick, mapping)
    if not joystick or not joystick:isConnected() or not mapping then
        return false
    end
    
    if mapping.type == "joystick_button" then
        return joystick:isDown(mapping.id)
    elseif mapping.type == "gamepad_button" then
        -- For gamepad buttons, we'd need to check if joystick is a gamepad
        if joystick:isGamepad() then
            return joystick:isGamepadDown(mapping.id)
        end
    end
    
    return false
end

-- Check if multiple buttons are pressed (for exit combos)
function detector.areButtonsPressed(joystick, mappings)
    if not joystick or not mappings then
        return false
    end
    
    for _, mapping in ipairs(mappings) do
        if not detector.isButtonPressed(joystick, mapping) then
            return false
        end
    end
    
    return true
end

-- Get input log for debugging display
function detector.getInputLog(count)
    count = count or 10
    local result = {}
    
    for i = 1, math.min(count, #detector.inputLog) do
        table.insert(result, detector.inputLog[i])
    end
    
    return result
end

-- Clear input log
function detector.clearInputLog()
    detector.inputLog = {}
    print("Input log cleared")
end

-- Get input statistics
function detector.getInputStats()
    local stats = {
        totalInputs = #detector.inputLog,
        buttonInputs = 0,
        axisInputs = 0,
        hatInputs = 0
    }
    
    for _, entry in ipairs(detector.inputLog) do
        if entry.type:find("button") then
            stats.buttonInputs = stats.buttonInputs + 1
        elseif entry.type:find("axis") then
            stats.axisInputs = stats.axisInputs + 1
        elseif entry.type:find("hat") then
            stats.hatInputs = stats.hatInputs + 1
        end
    end
    
    return stats
end

-- Validate input for mapping (used during setup)
function detector.isValidForMapping(inputType, inputId, extra)
    -- Check if input type is valid
    if not helpers.isValidInputType(inputType) then
        return false, "Invalid input type: " .. tostring(inputType)
    end
    
    -- Check if input ID is valid
    if not inputId or inputId < 1 then
        return false, "Invalid input ID: " .. tostring(inputId)
    end
    
    -- For axis inputs, check if extra value is significant
    if inputType:find("axis") then
        if not extra or math.abs(tonumber(extra)) < config.AXIS_THRESHOLD then
            return false, "Axis movement too small: " .. tostring(extra)
        end
    end
    
    return true, "Valid input"
end

return detector