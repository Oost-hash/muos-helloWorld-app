-- input/handler.lua - Input Routing System
-- Routes input to appropriate state handlers and manages input flow

local config = require("config")
local helpers = require("utils.helpers")
local detector = require("input.detector")
local mapper = require("input.mapper")

local handler = {}

-- Input routing state
handler.currentStateHandler = nil
handler.globalInputHandlers = {}

-- Initialize input handler
function handler.initialize()
    handler.currentStateHandler = nil
    handler.globalInputHandlers = {}
    print("Input handler initialized")
end

-- Set current state handler
function handler.setStateHandler(stateHandler)
    handler.currentStateHandler = stateHandler
    print("Input handler set for state: " .. (stateHandler.name or "unknown"))
end

-- Add global input handler (for app-wide shortcuts)
function handler.addGlobalHandler(name, handlerFunc)
    handler.globalInputHandlers[name] = handlerFunc
    print("Global input handler added: " .. name)
end

-- Remove global input handler
function handler.removeGlobalHandler(name)
    handler.globalInputHandlers[name] = nil
    print("Global input handler removed: " .. name)
end

-- Process raw input and route it appropriately
function handler.processInput(inputType, inputId, extra)
    -- Log the input for debugging
    detector.logInput(inputType, inputId, extra)
    
    -- Validate input
    local isValid, reason = detector.isValidForMapping(inputType, inputId, extra)
    if not isValid then
        print("Invalid input ignored: " .. reason)
        return false
    end
    
    -- Check if mapper should handle this input (during setup/remapping)
    if mapper.isInMappingMode then
        local handled = mapper.processInput(inputType, inputId, extra)
        if handled then
            return true  -- Input consumed by mapper
        end
    end
    
    -- Process global handlers first (app-wide shortcuts)
    for name, handlerFunc in pairs(handler.globalInputHandlers) do
        local handled = handlerFunc(inputType, inputId, extra)
        if handled then
            print("Input handled by global handler: " .. name)
            return true
        end
    end
    
    -- Route to current state handler
    if handler.currentStateHandler and handler.currentStateHandler.handleInput then
        local handled = handler.currentStateHandler.handleInput(inputType, inputId, extra)
        if handled then
            return true
        end
    end
    
    -- Input not handled
    print("Unhandled input: " .. detector.getInputDescription(inputType, inputId, extra))
    return false
end

-- Check for exit combinations (global handler)
function handler.checkExitCombos(joystick, deviceMapping)
    if not joystick or not deviceMapping then
        return false
    end
    
    -- Check main exit combo (Menu + Start)
    local menuMapping = deviceMapping[config.EXIT_COMBOS.MAIN[1]]
    local startMapping = deviceMapping[config.EXIT_COMBOS.MAIN[2]]
    
    if menuMapping and startMapping then
        if detector.isButtonPressed(joystick, menuMapping) and 
           detector.isButtonPressed(joystick, startMapping) then
            print("Exit combo detected: Menu + Start")
            love.event.quit()
            return true
        end
    end
    
    -- Check alternative exit combo (L1 + R1) for debug screen
    local l1Mapping = deviceMapping[config.EXIT_COMBOS.DEBUG_ALT[1]]
    local r1Mapping = deviceMapping[config.EXIT_COMBOS.DEBUG_ALT[2]]
    
    if l1Mapping and r1Mapping then
        if detector.isButtonPressed(joystick, l1Mapping) and 
           detector.isButtonPressed(joystick, r1Mapping) then
            print("Alternative exit combo detected: L1 + R1")
            -- This could trigger state change instead of quit
            return "debug_exit"
        end
    end
    
    return false
end

-- Find mapped button from input
function handler.findMappedButton(inputType, inputId, extra, deviceMapping)
    deviceMapping = deviceMapping or mapper.getDeviceMapping()
    return mapper.findMappedButton(inputType, inputId, extra, deviceMapping)
end

-- Create state-specific input handler
function handler.createStateHandler(stateName, inputMappings)
    local stateHandler = {
        name = stateName,
        inputMappings = inputMappings or {},
        
        handleInput = function(inputType, inputId, extra)
            -- Find mapped button
            local buttonKey, mapping = handler.findMappedButton(inputType, inputId, extra)
            
            if buttonKey and stateHandler.inputMappings[buttonKey] then
                local action = stateHandler.inputMappings[buttonKey]
                if type(action) == "function" then
                    print("Executing action for: " .. buttonKey)
                    action(buttonKey, mapping)
                    return true
                elseif type(action) == "string" then
                    print("Action string for " .. buttonKey .. ": " .. action)
                    return true
                end
            end
            
            return false  -- Input not handled
        end
    }
    
    return stateHandler
end

-- Update input handler (called from main update loop)
function handler.update(dt)
    -- Update mapper if active
    if mapper.isInMappingMode then
        mapper.update(dt)
    end
    
    -- Update current state handler if it has an update function
    if handler.currentStateHandler and handler.currentStateHandler.update then
        handler.currentStateHandler.update(dt)
    end
end

-- Get input statistics for debugging
function handler.getInputStats()
    local stats = detector.getInputStats()
    local mapperStats = mapper.getMappingStats()
    
    return {
        detector = stats,
        mapper = mapperStats,
        currentState = handler.currentStateHandler and handler.currentStateHandler.name or "none",
        globalHandlers = helpers.countTableEntries(handler.globalInputHandlers),
        mappingMode = mapper.isInMappingMode
    }
end

-- Get recent input log for debugging
function handler.getRecentInputs(count)
    return detector.getInputLog(count)
end

-- Clear input log
function handler.clearInputLog()
    detector.clearInputLog()
end

-- Setup default global handlers
function handler.setupDefaultGlobalHandlers(app)
    -- Exit combo handler
    handler.addGlobalHandler("exit_combo", function(inputType, inputId, extra)
        local exitResult = handler.checkExitCombos(app.joystick, app.deviceMapping)
        if exitResult == true then
            return true  -- App quit handled
        elseif exitResult == "debug_exit" then
            -- Could trigger state change here
            return false  -- Let state handle it
        end
        return false
    end)
    
    -- Debug input logger (optional)
    handler.addGlobalHandler("debug_logger", function(inputType, inputId, extra)
        -- This could log all inputs for debugging purposes
        -- For now, just return false to not consume input
        return false
    end)
end

-- Utility functions for states
handler.utils = {}

-- Check if button is currently pressed
function handler.utils.isButtonPressed(buttonKey, joystick, deviceMapping)
    if not joystick or not deviceMapping or not deviceMapping[buttonKey] then
        return false
    end
    
    return detector.isButtonPressed(joystick, deviceMapping[buttonKey])
end

-- Check if multiple buttons are pressed
function handler.utils.areButtonsPressed(buttonKeys, joystick, deviceMapping)
    if not joystick or not deviceMapping then
        return false
    end
    
    for _, buttonKey in ipairs(buttonKeys) do
        if not handler.utils.isButtonPressed(buttonKey, joystick, deviceMapping) then
            return false
        end
    end
    
    return true
end

-- Get current input states for display
function handler.utils.getCurrentInputStates(joystick)
    return detector.getCurrentInputStates(joystick)
end

-- Validate that essential buttons are mapped
function handler.utils.validateEssentialMappings(deviceMapping)
    local essential = {"button_south", "button_east", "button_west", "button_north"}
    for _, button in ipairs(essential) do
        if not deviceMapping[button] then
            return false, "Missing essential button: " .. button
        end
    end
    return true, "All essential buttons mapped"
end

return handler