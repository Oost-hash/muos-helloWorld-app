-- states/main_screen.lua - Main Screen State Implementation
-- Primary app interface with counter and navigation

local config = require("config")
local helpers = require("utils.helpers")
local handler = require("input.handler")
local renderer = require("ui.renderer")

local mainScreen = {}

-- Main screen state
mainScreen.name = "Main"
mainScreen.isActive = false
mainScreen.counter = 0
mainScreen.onStateChange = nil

-- Enter main screen state
function mainScreen.enter(app, onStateChangeCallback)
    print("=== ENTERING MAIN SCREEN STATE ===")
    mainScreen.isActive = true
    mainScreen.onStateChange = onStateChangeCallback
    
    -- Set up input handler for main screen
    local inputMappings = {
        button_south = function(buttonKey, mapping)
            mainScreen.incrementCounter()
        end,
        
        button_east = function(buttonKey, mapping)
            mainScreen.resetCounter()
        end,
        
        button_west = function(buttonKey, mapping)
            mainScreen.startRemapping(app)
        end,
        
        button_north = function(buttonKey, mapping)
            mainScreen.enterDebugScreen(app)
        end,
        
        button_menu = function(buttonKey, mapping)
            mainScreen.checkExitCombo(app)
        end,
        
        button_start = function(buttonKey, mapping)
            mainScreen.checkExitCombo(app)
        end
    }
    
    -- Create and set input handler
    local stateHandler = handler.createStateHandler("Main", inputMappings)
    handler.setStateHandler(stateHandler)
    
    print("Main screen state entered")
end

-- Exit main screen state
function mainScreen.exit()
    print("=== EXITING MAIN SCREEN STATE ===")
    mainScreen.isActive = false
    mainScreen.onStateChange = nil
end

-- Update main screen state
function mainScreen.update(dt, app)
    if not mainScreen.isActive then return end
    
    -- Update input handler
    handler.update(dt)
    
    -- Could add other main screen updates here
    -- (animations, periodic tasks, etc.)
end

-- Draw main screen state
function mainScreen.draw(app)
    if not mainScreen.isActive then return end
    
    -- Prepare data for renderer
    local mainData = {
        counter = mainScreen.counter,
        fps = app.frameRate,
        memory = app.memoryUsage,
        deviceName = app.joystickInfo.name,
        deviceConnected = app.joystickInfo.connected,
        controls = config.CONTROLS.MAIN_SCREEN,
        deviceMapping = app.deviceMapping,
        stateName = "Main",
        inputStats = handler.getInputStats()
    }
    
    -- Draw main screen
    renderer.drawMainScreen(mainData)
end

-- Handle input during main screen
function mainScreen.handleInput(inputType, inputId, extra, app)
    if not mainScreen.isActive then
        return false
    end
    
    -- Route input through handler
    return handler.processInput(inputType, inputId, extra)
end

-- Counter operations
function mainScreen.incrementCounter()
    mainScreen.counter = mainScreen.counter + 1
    print("Counter incremented: " .. mainScreen.counter)
end

function mainScreen.resetCounter()
    mainScreen.counter = 0
    print("Counter reset")
end

function mainScreen.setCounter(value)
    mainScreen.counter = value or 0
    print("Counter set to: " .. mainScreen.counter)
end

function mainScreen.getCounter()
    return mainScreen.counter
end

-- Navigation functions
function mainScreen.enterDebugScreen(app)
    print("Main: Entering debug screen")
    
    if mainScreen.onStateChange then
        mainScreen.onStateChange(config.STATES.DEBUG, app)
    end
end

function mainScreen.startRemapping(app)
    print("Main: Starting remapping process")
    
    if mainScreen.onStateChange then
        mainScreen.onStateChange(config.STATES.SETUP, app)
    end
end

-- Exit combo handling
function mainScreen.checkExitCombo(app)
    if not app.joystick or not app.deviceMapping then
        return false
    end
    
    -- Check if both menu and start are pressed
    local menuMapping = app.deviceMapping.button_menu
    local startMapping = app.deviceMapping.button_start
    
    if menuMapping and startMapping then
        local detector = require("input.detector")
        local menuPressed = detector.isButtonPressed(app.joystick, menuMapping)
        local startPressed = detector.isButtonPressed(app.joystick, startMapping)
        
        if menuPressed and startPressed then
            print("Main: Exit combo detected - Menu + Start")
            love.event.quit()
            return true
        end
    end
    
    return false
end

-- Get main screen statistics
function mainScreen.getStats()
    return {
        isActive = mainScreen.isActive,
        counter = mainScreen.counter,
        inputHandler = handler.getInputStats()
    }
end

-- Handle device connection changes
function mainScreen.onDeviceChanged(app, joystickInfo)
    if not mainScreen.isActive then return end
    
    print("Main: Device changed - " .. joystickInfo.name .. 
          " (" .. (joystickInfo.connected and "connected" or "disconnected") .. ")")
    
    -- Could update UI or show notification
    -- For now, just log the change
end

-- Save/Load counter state (optional persistence)
function mainScreen.saveState()
    local state = {
        counter = mainScreen.counter,
        timestamp = os.time()
    }
    
    -- Could save to file if needed
    print("Main: State saved (counter: " .. mainScreen.counter .. ")")
    return state
end

function mainScreen.loadState(state)
    if state and state.counter then
        mainScreen.counter = state.counter
        print("Main: State loaded (counter: " .. mainScreen.counter .. ")")
        return true
    end
    
    return false
end

-- Performance testing functions
function mainScreen.stressTestCounter(iterations)
    print("Main: Running counter stress test (" .. iterations .. " iterations)")
    
    local startTime = helpers.getCurrentTime()
    
    for i = 1, iterations do
        mainScreen.incrementCounter()
    end
    
    local endTime = helpers.getCurrentTime()
    local duration = endTime - startTime
    
    print("Main: Stress test complete - " .. iterations .. " increments in " .. 
          string.format("%.3f", duration) .. "s")
    
    return duration
end

-- Debug functions
function mainScreen.debugInfo()
    return {
        state = "Main Screen",
        counter = mainScreen.counter,
        isActive = mainScreen.isActive,
        hasStateChangeCallback = mainScreen.onStateChange ~= nil
    }
end

-- Validation functions
function mainScreen.validateMappings(app)
    if not app.deviceMapping then
        return false, "No device mapping available"
    end
    
    -- Check essential buttons
    local essential = {"button_south", "button_east", "button_west", "button_north"}
    local missing = {}
    
    for _, button in ipairs(essential) do
        if not app.deviceMapping[button] then
            table.insert(missing, button)
        end
    end
    
    if #missing > 0 then
        return false, "Missing buttons: " .. table.concat(missing, ", ")
    end
    
    return true, "All essential buttons mapped"
end

-- Handle errors
function mainScreen.handleError(error, app)
    print("Main screen error: " .. tostring(error))
    
    -- Could show error overlay or reset state
    -- For now, just log and continue
end

-- Cleanup main screen resources
function mainScreen.cleanup()
    if mainScreen.isActive then
        mainScreen.exit()
    end
    
    mainScreen.counter = 0
    print("Main screen cleanup complete")
end

-- Demo/showcase functions (for development)
function mainScreen.runDemo()
    print("Main: Running demo sequence")
    
    -- Demo sequence: increment, wait, reset, wait
    mainScreen.incrementCounter()
    -- In a real implementation, you'd use a timer/coroutine for delays
    mainScreen.incrementCounter()
    mainScreen.incrementCounter()
    mainScreen.resetCounter()
    
    print("Main: Demo sequence complete")
end

-- Export key functions for external access
mainScreen.api = {
    getCounter = mainScreen.getCounter,
    setCounter = mainScreen.setCounter,
    incrementCounter = mainScreen.incrementCounter,
    resetCounter = mainScreen.resetCounter,
    validateMappings = mainScreen.validateMappings,
    debugInfo = mainScreen.debugInfo
}

return mainScreen