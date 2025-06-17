-- states/debug.lua - Debug State Implementation
-- Live input visualization and diagnostic interface

local config = require("config")
local helpers = require("utils.helpers")
local handler = require("input.handler")
local renderer = require("ui.renderer")
local detector = require("input.detector")

local debug = {}

-- Debug state
debug.name = "Debug"
debug.isActive = false
debug.onStateChange = nil
debug.refreshRate = 60  -- Hz for input monitoring
debug.lastRefresh = 0

-- Enter debug state
function debug.enter(app, onStateChangeCallback)
    print("=== ENTERING DEBUG STATE ===")
    debug.isActive = true
    debug.onStateChange = onStateChangeCallback
    debug.lastRefresh = helpers.getCurrentTime()
    
    -- Set up input handler for debug screen
    local inputMappings = {
        button_north = function(buttonKey, mapping)
            debug.returnToMain(app)
        end,
        
        trigger_l1 = function(buttonKey, mapping)
            debug.checkAlternativeExit(app)
        end,
        
        trigger_r1 = function(buttonKey, mapping)
            debug.checkAlternativeExit(app)
        end
    }
    
    -- Create and set input handler (input-locked except for navigation)
    local stateHandler = handler.createStateHandler("Debug", inputMappings)
    handler.setStateHandler(stateHandler)
    
    -- Clear input log for fresh debug session
    detector.clearInputLog()
    
    print("Debug state entered - input monitoring active")
end

-- Exit debug state
function debug.exit()
    print("=== EXITING DEBUG STATE ===")
    debug.isActive = false
    debug.onStateChange = nil
end

-- Update debug state
function debug.update(dt, app)
    if not debug.isActive then return end
    
    -- Update input handler
    handler.update(dt)
    
    -- Update refresh timer
    debug.lastRefresh = debug.lastRefresh + dt
end

-- Draw debug state
function debug.draw(app)
    if not debug.isActive then return end
    
    -- Prepare data for renderer
    local debugData = {
        joystick = app.joystick,
        joystickInfo = app.joystickInfo,
        deviceMapping = app.deviceMapping,
        fps = app.frameRate,
        memory = app.memoryUsage,
        stateName = "Debug",
        inputStats = handler.getInputStats(),
        detectorStats = detector.getInputStats(),
        recentInputs = detector.getInputLog(10)
    }
    
    -- Draw debug screen
    renderer.drawDebugScreen(debugData)
end

-- Handle input during debug state
function debug.handleInput(inputType, inputId, extra, app)
    if not debug.isActive then
        return false
    end
    
    -- All input is logged by detector automatically
    -- Only handle navigation inputs through handler
    return handler.processInput(inputType, inputId, extra)
end

-- Navigation functions
function debug.returnToMain(app)
    print("Debug: Returning to main screen")
    
    if debug.onStateChange then
        debug.onStateChange(config.STATES.MAIN, app)
    end
end

-- Alternative exit combo (L1 + R1)
function debug.checkAlternativeExit(app)
    if not app.joystick or not app.deviceMapping then
        return false
    end
    
    local l1Mapping = app.deviceMapping.trigger_l1
    local r1Mapping = app.deviceMapping.trigger_r1
    
    if l1Mapping and r1Mapping then
        local l1Pressed = detector.isButtonPressed(app.joystick, l1Mapping)
        local r1Pressed = detector.isButtonPressed(app.joystick, r1Mapping)
        
        if l1Pressed and r1Pressed then
            print("Debug: Alternative exit combo detected - L1 + R1")
            debug.returnToMain(app)
            return true
        end
    end
    
    return false
end

-- Get current input states for real-time display
function debug.getCurrentInputStates(app)
    if not app.joystick or not app.joystick:isConnected() then
        return {
            buttons = {},
            axes = {},
            hats = {},
            connected = false
        }
    end
    
    return {
        buttons = debug.getButtonStates(app.joystick),
        axes = debug.getAxisStates(app.joystick),
        hats = debug.getHatStates(app.joystick),
        connected = true
    }
end

-- Get button states
function debug.getButtonStates(joystick)
    local states = {}
    
    for i = 1, joystick:getButtonCount() do
        states[i] = {
            id = i,
            pressed = joystick:isDown(i),
            name = "Button " .. i
        }
    end
    
    return states
end

-- Get axis states with enhanced info
function debug.getAxisStates(joystick)
    local states = {}
    
    for i = 1, joystick:getAxisCount() do
        local value = joystick:getAxis(i)
        states[i] = {
            id = i,
            value = value,
            isActive = math.abs(value) > config.AXIS_DISPLAY_THRESHOLD,
            direction = helpers.getAxisDirection(value),
            name = "Axis " .. i,
            percentage = math.floor(math.abs(value) * 100)
        }
    end
    
    return states
end

-- Get hat states
function debug.getHatStates(joystick)
    local states = {}
    
    for i = 1, joystick:getHatCount() do
        local value = joystick:getHat(i)
        states[i] = {
            id = i,
            value = value,
            isActive = value ~= "c",
            direction = helpers.getHatDirectionName(value),
            name = "Hat " .. i
        }
    end
    
    return states
end

-- Get debug statistics
function debug.getStats()
    return {
        isActive = debug.isActive,
        refreshRate = debug.refreshRate,
        inputStats = handler.getInputStats(),
        detectorStats = detector.getInputStats(),
        recentInputCount = #detector.getInputLog()
    }
end

-- Debug utilities
function debug.logDeviceInfo(app)
    if not app.joystick then
        print("Debug: No joystick connected")
        return
    end
    
    local info = app.joystickInfo
    print("=== DEVICE INFO ===")
    print("Name: " .. info.name)
    print("Connected: " .. tostring(info.connected))
    print("Buttons: " .. info.buttonCount)
    print("Axes: " .. info.axisCount)
    print("Hats: " .. info.hatCount)
    print("ID: " .. tostring(info.id))
    print("==================")
end

function debug.logMappingInfo(app)
    if not app.deviceMapping then
        print("Debug: No device mapping available")
        return
    end
    
    print("=== MAPPING INFO ===")
    print("Total mappings: " .. helpers.countTableEntries(app.deviceMapping))
    
    for key, mapping in pairs(app.deviceMapping) do
        local mapStr = key .. " = " .. mapping.type .. ":" .. tostring(mapping.id)
        if mapping.direction then
            mapStr = mapStr .. ":" .. mapping.direction
        end
        print(mapStr)
    end
    print("====================")
end

function debug.logRecentInputs(count)
    count = count or 10
    local inputs = detector.getInputLog(count)
    
    print("=== RECENT INPUTS ===")
    for i, input in ipairs(inputs) do
        print(i .. ". " .. input.description .. " (" .. 
              string.format("%.3f", input.time) .. "s ago)")
    end
    print("=====================")
end

-- Performance monitoring
function debug.getPerformanceInfo(app)
    return {
        fps = app.frameRate,
        memory = app.memoryUsage,
        inputLogSize = #detector.getInputLog(),
        renderStats = renderer.getStats(),
        detectorStats = detector.getInputStats()
    }
end

-- Input analysis functions
function debug.analyzeInputPattern(duration)
    duration = duration or 5  -- seconds
    
    print("Debug: Starting input analysis for " .. duration .. " seconds...")
    
    local startTime = helpers.getCurrentTime()
    local startInputCount = #detector.getInputLog()
    
    -- This would need a timer system for real implementation
    -- For now, just return current stats
    
    return {
        duration = duration,
        inputsDetected = #detector.getInputLog() - startInputCount,
        averageRate = 0  -- Would calculate after timer completes
    }
end

-- Diagnostic functions
function debug.runDiagnostics(app)
    print("Debug: Running system diagnostics...")
    
    local results = {
        deviceConnection = app.joystick and app.joystick:isConnected() or false,
        mappingValid = false,
        inputDetection = false,
        memoryUsage = helpers.getMemoryUsage(),
        timestamp = helpers.getCurrentTime()
    }
    
    -- Check mapping validity
    if app.deviceMapping then
        local mapperModule = require("input.mapper")
        results.mappingValid = mapperModule.validateMapping(app.deviceMapping)
    end
    
    -- Check input detection (simplified)
    results.inputDetection = #detector.getInputLog() > 0
    
    print("Diagnostics complete:")
    print("  Device: " .. (results.deviceConnection and "OK" or "FAIL"))
    print("  Mapping: " .. (results.mappingValid and "OK" or "FAIL"))
    print("  Input: " .. (results.inputDetection and "OK" or "FAIL"))
    print("  Memory: " .. results.memoryUsage .. "KB")
    
    return results
end

-- Debug screen modes (future enhancement)
debug.modes = {
    LIVE_INPUT = 1,
    MAPPING_INFO = 2,
    PERFORMANCE = 3,
    DIAGNOSTICS = 4
}

debug.currentMode = debug.modes.LIVE_INPUT

function debug.switchMode(mode)
    if debug.modes[mode] then
        debug.currentMode = mode
        print("Debug: Switched to mode " .. mode)
    end
end

-- Handle debug errors
function debug.handleError(error, app)
    print("Debug state error: " .. tostring(error))
    
    -- Could show error overlay or return to main
    -- For now, just log and continue
end

-- Cleanup debug resources
function debug.cleanup()
    if debug.isActive then
        debug.exit()
    end
    
    -- Clear input log
    detector.clearInputLog()
    
    print("Debug cleanup complete")
end

-- Export debug utilities for external access
debug.utils = {
    logDeviceInfo = debug.logDeviceInfo,
    logMappingInfo = debug.logMappingInfo,
    logRecentInputs = debug.logRecentInputs,
    runDiagnostics = debug.runDiagnostics,
    getPerformanceInfo = debug.getPerformanceInfo
}

return debug