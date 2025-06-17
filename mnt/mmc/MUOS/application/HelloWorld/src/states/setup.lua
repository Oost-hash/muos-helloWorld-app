-- states/setup.lua - Setup State Implementation
-- Handles the button mapping setup process

local config = require("config")
local helpers = require("utils.helpers")
local mapper = require("input.mapper")
local persistence = require("utils.persistence")
local renderer = require("ui.renderer")

local setup = {}

-- Setup state
setup.name = "Setup"
setup.isActive = false
setup.onComplete = nil

-- Enter setup state
function setup.enter(app, onCompleteCallback)
    print("=== ENTERING SETUP STATE ===")
    setup.isActive = true
    setup.onComplete = onCompleteCallback
    
    -- Initialize mapper
    mapper.initialize()
    
    -- Start mapping process
    mapper.startMapping(function(deviceMapping)
        setup.onMappingComplete(app, deviceMapping)
    end)
    
    print("Setup state entered - mapping process started")
end

-- Exit setup state
function setup.exit()
    print("=== EXITING SETUP STATE ===")
    setup.isActive = false
    mapper.stopMapping()
    setup.onComplete = nil
end

-- Update setup state
function setup.update(dt, app)
    if not setup.isActive then return end
    
    -- Update mapper (handles cooldowns)
    mapper.update(dt)
end

-- Draw setup state
function setup.draw(app)
    if not setup.isActive then return end
    
    -- Get current mapping step info
    local stepInfo = mapper.getCurrentStep()
    
    if stepInfo then
        -- Prepare data for renderer
        local setupData = {
            step = stepInfo.step,
            total = stepInfo.total,
            instruction = stepInfo.instruction,
            waitingForInput = stepInfo.waitingForInput,
            cooldown = stepInfo.cooldown,
            joystickInfo = app.joystickInfo,
            stateName = "Setup",
            fps = app.frameRate,
            memory = app.memoryUsage
        }
        
        -- Draw setup screen
        renderer.drawSetupScreen(setupData)
    else
        -- Fallback if no step info available
        local setupData = {
            step = 1,
            total = #config.MAPPING_SEQUENCE,
            instruction = "Initializing mapping...",
            waitingForInput = false,
            cooldown = 0,
            joystickInfo = app.joystickInfo,
            stateName = "Setup",
            fps = app.frameRate,
            memory = app.memoryUsage
        }
        
        renderer.drawSetupScreen(setupData)
    end
end

-- Handle input during setup
function setup.handleInput(inputType, inputId, extra, app)
    if not setup.isActive then
        return false
    end
    
    -- Check if we have a joystick connected
    if not app.joystick or not app.joystick:isConnected() then
        print("Setup: No joystick connected, ignoring input")
        return false
    end
    
    -- Validate input
    local isValid, reason = require("input.detector").isValidForMapping(inputType, inputId, extra)
    if not isValid then
        print("Setup: Invalid input - " .. reason)
        return false
    end
    
    -- Process input through mapper
    local handled = mapper.processInput(inputType, inputId, extra)
    
    if handled then
        print("Setup: Input processed - " .. inputType .. ":" .. tostring(inputId) .. 
              (extra and (":" .. tostring(extra)) or ""))
    end
    
    return handled
end

-- Handle mapping completion
function setup.onMappingComplete(app, deviceMapping)
    print("=== MAPPING COMPLETE ===")
    print("Mapped " .. helpers.countTableEntries(deviceMapping) .. " inputs")
    
    -- Store mapping in app
    app.deviceMapping = deviceMapping
    
    -- Validate mapping
    local isValid, issues = mapper.validateMapping(deviceMapping)
    if not isValid then
        print("Mapping validation failed:")
        for _, issue in ipairs(issues) do
            print("  - " .. issue)
        end
    else
        print("Mapping validation passed")
    end
    
    -- Save mapping to file
    local saveSuccess = persistence.saveDeviceMapping(deviceMapping)
    if saveSuccess then
        print("Mapping saved successfully")
    else
        print("Warning: Failed to save mapping")
    end
    
    -- Call completion callback
    if setup.onComplete then
        setup.onComplete(app, deviceMapping)
    end
    
    -- Exit setup state
    setup.exit()
end

-- Get setup progress
function setup.getProgress()
    if not setup.isActive then
        return 1.0  -- Complete if not active
    end
    
    return mapper.getProgress()
end

-- Get current step info
function setup.getCurrentStepInfo()
    if not setup.isActive then
        return nil
    end
    
    return mapper.getCurrentStep()
end

-- Check if setup is waiting for input
function setup.isWaitingForInput()
    if not setup.isActive then
        return false
    end
    
    local stepInfo = mapper.getCurrentStep()
    return stepInfo and stepInfo.waitingForInput or false
end

-- Get setup statistics
function setup.getStats()
    return {
        isActive = setup.isActive,
        progress = setup.getProgress(),
        currentStep = setup.getCurrentStepInfo(),
        mapperStats = mapper.getMappingStats()
    }
end

-- Force complete setup (for testing)
function setup.forceComplete(app)
    print("Setup: Force completing with minimal mapping")
    
    -- Create minimal mapping for testing
    local minimalMapping = {
        button_south = {type = "joystick_button", id = 1},
        button_east = {type = "joystick_button", id = 2},
        button_west = {type = "joystick_button", id = 3},
        button_north = {type = "joystick_button", id = 4}
    }
    
    setup.onMappingComplete(app, minimalMapping)
end

-- Skip current step (for testing/debugging)
function setup.skipCurrentStep()
    if not setup.isActive then
        return false
    end
    
    print("Setup: Skipping current step")
    
    -- Create a dummy mapping for current step
    local stepInfo = mapper.getCurrentStep()
    if stepInfo then
        local dummyMapping = {
            type = "joystick_button",
            id = stepInfo.step  -- Use step number as dummy ID
        }
        
        -- Manually advance mapper
        mapper.deviceMapping[stepInfo.key] = dummyMapping
        mapper.currentMappingStep = mapper.currentMappingStep + 1
        
        if mapper.currentMappingStep > #config.MAPPING_SEQUENCE then
            mapper.completeMapping()
        else
            mapper.waitingForInput = true
        end
        
        return true
    end
    
    return false
end

-- Reset setup
function setup.reset(app)
    print("Setup: Resetting mapping process")
    
    if setup.isActive then
        mapper.stopMapping()
        mapper.initialize()
        mapper.startMapping(function(deviceMapping)
            setup.onMappingComplete(app, deviceMapping)
        end)
    end
end

-- Check if essential buttons are mapped
function setup.hasEssentialMappings(deviceMapping)
    local essential = {"button_south", "button_east", "button_west", "button_north"}
    
    for _, button in ipairs(essential) do
        if not deviceMapping[button] then
            return false, "Missing: " .. button
        end
    end
    
    return true, "All essential buttons mapped"
end

-- Get mapping summary for display
function setup.getMappingSummary()
    if not setup.isActive then
        return {}
    end
    
    local mapping = mapper.getDeviceMapping()
    local summary = {}
    
    -- Group by type
    local buttons = {}
    local axes = {}
    local hats = {}
    
    for key, map in pairs(mapping) do
        if map.type:find("button") then
            table.insert(buttons, {key = key, mapping = map})
        elseif map.type:find("axis") then
            table.insert(axes, {key = key, mapping = map})
        elseif map.type:find("hat") then
            table.insert(hats, {key = key, mapping = map})
        end
    end
    
    return {
        buttons = buttons,
        axes = axes,
        hats = hats,
        total = helpers.countTableEntries(mapping)
    }
end

-- Handle setup errors
function setup.handleError(error, app)
    print("Setup error: " .. tostring(error))
    
    -- Could show error screen or reset
    -- For now, just log and continue
end

-- Cleanup setup resources
function setup.cleanup()
    if setup.isActive then
        setup.exit()
    end
    
    mapper.stopMapping()
    print("Setup cleanup complete")
end

return setup