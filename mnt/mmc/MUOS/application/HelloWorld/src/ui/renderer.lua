-- ui/renderer.lua - Core Rendering Engine
-- Main rendering system that orchestrates UI drawing

local config = require("config")
local helpers = require("utils.helpers")
local themes = require("ui.themes")
local components = require("ui.components")

local renderer = {}

-- Rendering state
renderer.debugMode = false
renderer.renderStats = {
    frameTime = 0,
    drawCalls = 0,
    lastFrameStats = {}
}

-- Initialize renderer
function renderer.initialize()
    renderer.debugMode = false
    renderer.renderStats = {
        frameTime = 0,
        drawCalls = 0,
        lastFrameStats = {}
    }
    print("Renderer initialized")
end

-- Update renderer
function renderer.update(dt)
    -- Update components (animations, etc.)
    components.update(dt)
    
    -- Update render stats
    renderer.renderStats.frameTime = renderer.renderStats.frameTime + dt
end

-- Toggle debug mode
function renderer.toggleDebugMode()
    renderer.debugMode = not renderer.debugMode
    print("Renderer debug mode: " .. tostring(renderer.debugMode))
end

-- Start frame rendering
function renderer.startFrame()
    renderer.renderStats.drawCalls = 0
    renderer.renderStats.frameStartTime = love.timer.getTime()
end

-- End frame rendering
function renderer.endFrame()
    local frameEndTime = love.timer.getTime()
    renderer.renderStats.lastFrameStats.frameTime = frameEndTime - (renderer.renderStats.frameStartTime or frameEndTime)
    renderer.renderStats.lastFrameStats.drawCalls = renderer.renderStats.drawCalls
end

-- Increment draw call counter
function renderer.incrementDrawCalls()
    renderer.renderStats.drawCalls = renderer.renderStats.drawCalls + 1
end

-- Draw debug overlay
function renderer.drawDebugOverlay(data)
    local overlayY = config.SCREEN_HEIGHT - 80
    local overlayX = 10
    
    -- Semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", overlayX - 5, overlayY - 5, 300, 75)
    
    -- Debug text
    love.graphics.setFont(config.FONTS.DEBUG or love.graphics.getFont())
    love.graphics.setColor(config.COLORS.DEBUG_TEXT or {1, 1, 0, 1})
    
    local debugText = string.format(
        "DEBUG MODE\nFrame Time: %.2fms\nDraw Calls: %d\nMemory: %.1fMB",
        (renderer.renderStats.lastFrameStats.frameTime or 0) * 1000,
        renderer.renderStats.lastFrameStats.drawCalls or 0,
        (data and data.memory or 0)
    )
    
    love.graphics.print(debugText, overlayX, overlayY)
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw Setup Screen
function renderer.drawSetupScreen(setupData)
    renderer.startFrame()
    
    -- Main setup UI
    themes.drawSetupScreen(
        setupData.step,
        setupData.total,
        setupData.instruction,
        setupData.waitingForInput,
        setupData.cooldown
    )
    
    -- Device connection status
    if setupData.joystickInfo then
        local y = config.LAYOUT.DEVICE_Y + 50
        components.DeviceConnection(20, y, setupData.joystickInfo, false)
    end
    
    -- Debug overlay
    if renderer.debugMode then
        renderer.drawDebugOverlay(setupData)
    end
    
    renderer.endFrame()
end

-- Draw Main Screen
function renderer.drawMainScreen(mainData)
    renderer.startFrame()
    
    -- Main interface
    themes.drawMainScreen(
        mainData.counter,
        mainData.fps,
        mainData.memory,
        mainData.deviceName,
        mainData.deviceConnected,
        mainData.controls
    )
    
    -- Show some mappings if available
    if mainData.deviceMapping and helpers.countTableEntries(mainData.deviceMapping) > 0 then
        local mappingY = config.LAYOUT.DEVICE_Y + 30
        components.MappingDisplay(20, mappingY, mainData.deviceMapping, 6, "Current Mappings:")
    end
    
    -- Debug overlay
    if renderer.debugMode then
        renderer.drawDebugOverlay(mainData)
    end
    
    renderer.endFrame()
end

-- Draw Debug Screen
function renderer.drawDebugScreen(debugData)
    renderer.startFrame()
    
    -- Debug screen header
    themes.drawDebugScreenHeader()
    
    -- Device information
    if debugData.joystickInfo and debugData.joystickInfo.connected then
        themes.drawDebugDeviceInfo(debugData.joystickInfo)
        
        -- Live input visualization
        local leftColumnX = 20
        local rightColumnX = 350
        local startY = config.LAYOUT.DEBUG_BUTTONS_Y
        
        -- Left column: Buttons and Hats
        local currentY = themes.drawSectionHeader("LIVE INPUTS", leftColumnX, startY)
        currentY = components.InputStatus(leftColumnX, currentY, debugData.joystick, debugData.deviceMapping)
        currentY = currentY + 10
        currentY = components.HatStatus(leftColumnX, currentY, debugData.joystick)
        
        -- Right column: Axes and Performance
        currentY = themes.drawSectionHeader("ANALOG INPUTS", rightColumnX, startY)
        currentY = components.AxisVisualizer(rightColumnX, currentY, debugData.joystick)
        currentY = currentY + 20
        currentY = components.PerformanceMonitor(rightColumnX, currentY, debugData.fps, debugData.memory)
        
        -- Bottom: Mapping information
        local bottomY = 380
        components.MappingDisplay(20, bottomY, debugData.deviceMapping, 4, 
                                 "Mapped Buttons (" .. helpers.countTableEntries(debugData.deviceMapping) .. " total):")
    else
        -- No device connected
        components.StatusBanner("No controller connected", "ERROR", 200)
    end
    
    -- Debug overlay
    if renderer.debugMode then
        renderer.drawDebugOverlay(debugData)
    end
    
    renderer.endFrame()
end

-- Draw generic screen with title and content
function renderer.drawGenericScreen(title, content, data)
    renderer.startFrame()
    
    -- Draw title
    love.graphics.setFont(config.FONTS.TITLE or love.graphics.getFont())
    love.graphics.setColor(config.COLORS.WHITE or {1, 1, 1, 1})
    love.graphics.printf(title, 0, config.LAYOUT.TITLE_Y or 50, config.SCREEN_WIDTH, "center")
    
    -- Draw content
    if type(content) == "function" then
        content(data)
    elseif type(content) == "string" then
        love.graphics.setFont(config.FONTS.INSTRUCTION or love.graphics.getFont())
        love.graphics.printf(content, 0, config.LAYOUT.COUNTER_Y or 150, config.SCREEN_WIDTH, "center")
    end
    
    -- Debug overlay
    if renderer.debugMode then
        renderer.drawDebugOverlay(data)
    end
    
    renderer.endFrame()
end

-- Get render statistics
function renderer.getStats()
    return {
        debugMode = renderer.debugMode,
        lastFrameTime = renderer.renderStats.lastFrameStats.frameTime or 0,
        lastDrawCalls = renderer.renderStats.lastFrameStats.drawCalls or 0,
        totalFrameTime = renderer.renderStats.frameTime
    }
end

-- Reset render statistics
function renderer.resetStats()
    renderer.renderStats = {
        frameTime = 0,
        drawCalls = 0,
        lastFrameStats = {}
    }
end

-- Set debug mode
function renderer.setDebugMode(enabled)
    renderer.debugMode = enabled
    print("Renderer debug mode set to: " .. tostring(enabled))
end

return renderer