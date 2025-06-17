-- main.lua - muOS Button Debug App Entry Point
-- Clean architecture with proper state management

-- Load configuration and utilities
local config = require("config")
local helpers = require("utils.helpers")

-- Global app state
local app = {
    currentState = config.STATES.SETUP,
    fonts = {},
    joystick = nil,
    joystickInfo = {},
    
    -- Performance tracking
    frameCount = 0,
    frameRate = 0,
    memoryUsage = 0,
    lastUpdate = 0,
    
    -- Device mapping (will be loaded or created)
    deviceMapping = {}
}

-- State modules (will be loaded after fonts are created)
local states = {}

-- Try to load existing device mapping
function loadExistingMapping()
    local persistence = require("utils.persistence")
    local mapping, error = persistence.loadDeviceMapping()
    
    if mapping then
        app.deviceMapping = mapping
        print("Loaded " .. helpers.countTableEntries(mapping) .. " button mappings")
        return true
    else
        print("No valid mapping file found: " .. (error or "unknown error"))
        return false
    end
end

-- Initialize the application
function love.load()
    print("=== muOS Button Debug App v" .. config.APP_VERSION .. " ===")
    
    -- Set background color
    love.graphics.setBackgroundColor(config.COLORS.BACKGROUND)
    
    -- Initialize fonts first
    initializeFonts()
    
    -- Initialize subsystems
    local themes = require("ui.themes")
    local components = require("ui.components")
    local renderer = require("ui.renderer")
    local handler = require("input.handler")
    
    themes.initialize()
    components.initialize()
    renderer.initialize()
    handler.initialize()
    
    -- Initialize joystick
    initializeJoystick()
    
    -- Load state modules
    loadStateModules()
    
    -- Setup global input handlers
    handler.setupDefaultGlobalHandlers(app)
    
    -- Try to load existing mapping
    if loadExistingMapping() then
        app.currentState = config.STATES.MAIN
        print("Existing mapping loaded, starting in main mode")
    else
        app.currentState = config.STATES.SETUP
        print("No mapping found, starting setup")
    end
    
    -- Initialize the current state
    changeState(app.currentState)
    
    app.lastUpdate = helpers.getCurrentTime()
    print("App initialization complete")
end

-- Initialize fonts
function initializeFonts()
    app.fonts = {
        title = love.graphics.newFont(config.FONTS.TITLE),
        counter = love.graphics.newFont(config.FONTS.COUNTER),
        instruction = love.graphics.newFont(config.FONTS.INSTRUCTION),
        debug = love.graphics.newFont(config.FONTS.DEBUG)
    }
    print("Fonts initialized")
end

-- Initialize joystick/gamepad
function initializeJoystick()
    local joysticks = love.joystick.getJoysticks()
    
    if #joysticks > 0 then
        app.joystick = joysticks[1]  -- Use first joystick
        app.joystickInfo = helpers.getJoystickInfo(app.joystick)
        print("Joystick connected: " .. app.joystickInfo.name)
        print("Buttons: " .. app.joystickInfo.buttonCount .. 
              ", Axes: " .. app.joystickInfo.axisCount .. 
              ", Hats: " .. app.joystickInfo.hatCount)
    else
        app.joystick = nil
        app.joystickInfo = helpers.getJoystickInfo(nil)
        print("WARNING: No joystick detected")
    end
end

-- Load state modules
function loadStateModules()
    -- Load real state implementations
    states[config.STATES.SETUP] = require("states.setup")
    states[config.STATES.MAIN] = require("states.main_screen") 
    states[config.STATES.DEBUG] = require("states.debug")
    print("State modules loaded (real implementations)")
end

-- Create placeholder state (temporary until we build real states)
function createPlaceholderState(name)
    return {
        name = name,
        enter = function()
            print("Entered " .. name .. " state")
        end,
        exit = function()
            print("Exited " .. name .. " state")
        end,
        update = function(dt)
            -- Placeholder update
        end,
        draw = function()
            love.graphics.setFont(app.fonts.title)
            love.graphics.setColor(config.COLORS.WHITE)
            love.graphics.printf(config.APP_NAME, 0, config.LAYOUT.TITLE_Y, config.SCREEN_WIDTH, "center")
            
            love.graphics.setFont(app.fonts.instruction)
            love.graphics.printf(name .. " State (Placeholder)", 0, config.LAYOUT.COUNTER_Y, config.SCREEN_WIDTH, "center")
            
            love.graphics.setFont(app.fonts.debug)
            love.graphics.setColor(config.COLORS.UI_TEXT)
            love.graphics.printf("Phase 1: Foundation Complete", 0, config.LAYOUT.FPS_Y, config.SCREEN_WIDTH, "center")
            love.graphics.printf("Ready for Phase 2: Input System", 0, config.LAYOUT.MEMORY_Y, config.SCREEN_WIDTH, "center")
            
            -- Show joystick status
            if app.joystick then
                love.graphics.setColor(config.COLORS.SUCCESS)
                love.graphics.printf("Device: " .. app.joystickInfo.name, 0, config.LAYOUT.DEVICE_Y, config.SCREEN_WIDTH, "center")
            else
                love.graphics.setColor(config.COLORS.ERROR)
                love.graphics.printf("No controller detected", 0, config.LAYOUT.DEVICE_Y, config.SCREEN_WIDTH, "center")
            end
        end,
        handleInput = function(inputType, inputId, extra)
            print("Input in " .. name .. ": " .. inputType .. ":" .. tostring(inputId) .. 
                  (extra and (":" .. tostring(extra)) or ""))
        end
    }
end

-- State management
function changeState(newState)
    if newState == app.currentState then
        return  -- Already in this state
    end
    
    -- Exit current state
    if states[app.currentState] and states[app.currentState].exit then
        states[app.currentState].exit()
    end
    
    local oldState = app.currentState
    app.currentState = newState
    
    -- Enter new state with state change callback
    if states[app.currentState] and states[app.currentState].enter then
        states[app.currentState].enter(app, changeState)
    end
    
    print("State changed: " .. oldState .. " -> " .. newState)
end

-- Main update loop
function love.update(dt)
    -- Update performance counters
    updatePerformanceCounters(dt)
    
    -- Check joystick connection
    checkJoystickConnection()
    
    -- Update current state
    if states[app.currentState] and states[app.currentState].update then
        states[app.currentState].update(dt, app)
    end
end

-- Update performance tracking
function updatePerformanceCounters(dt)
    app.frameCount = app.frameCount + 1
    local currentTime = helpers.getCurrentTime()
    
    if helpers.hasTimeElapsed(app.lastUpdate, config.PERFORMANCE.FPS_UPDATE_INTERVAL) then
        app.frameRate = app.frameCount
        app.frameCount = 0
        app.memoryUsage = helpers.getMemoryUsage()
        app.lastUpdate = currentTime
    end
end

-- Check if joystick is still connected
function checkJoystickConnection()
    if app.joystick and not app.joystick:isConnected() then
        print("WARNING: Joystick disconnected")
        initializeJoystick()  -- Try to reconnect
    end
end

-- Main draw loop
function love.draw()
    if states[app.currentState] and states[app.currentState].draw then
        states[app.currentState].draw(app)
    end
end

-- Input event handlers - route to current state
function love.joystickpressed(joystick, button)
    if states[app.currentState] and states[app.currentState].handleInput then
        states[app.currentState].handleInput("joystick_button", button, nil, app)
    end
end

function love.joystickreleased(joystick, button)
    -- We typically only care about button press, not release
    -- But this is here for completeness
end

function love.joystickaxis(joystick, axis, value)
    if helpers.isSignificantAxisValue(value, config.AXIS_THRESHOLD) then
        if states[app.currentState] and states[app.currentState].handleInput then
            states[app.currentState].handleInput("joystick_axis", axis, value, app)
        end
    end
end

function love.joystickhat(joystick, hat, direction)
    if direction ~= "c" then  -- Ignore centered hat
        if states[app.currentState] and states[app.currentState].handleInput then
            states[app.currentState].handleInput("joystick_hat", hat, direction, app)
        end
    end
end

-- Gamepad event handlers (for devices that support gamepad API)
function love.gamepadpressed(joystick, button)
    if states[app.currentState] and states[app.currentState].handleInput then
        states[app.currentState].handleInput("gamepad_button", button, nil, app)
    end
end

function love.gamepadreleased(joystick, button)
    -- Button release handler if needed
end

function love.gamepadaxis(joystick, axis, value)
    if helpers.isSignificantAxisValue(value, config.AXIS_THRESHOLD) then
        if states[app.currentState] and states[app.currentState].handleInput then
            states[app.currentState].handleInput("gamepad_axis", axis, value, app)
        end
    end
end

-- Quit handler
function love.quit()
    print("App shutting down...")
    return false  -- Allow quit
end

-- Error handler
function love.errhand(msg)
    print("ERROR: " .. msg)
    print(debug.traceback())
end

-- Export app state for other modules to access
return app