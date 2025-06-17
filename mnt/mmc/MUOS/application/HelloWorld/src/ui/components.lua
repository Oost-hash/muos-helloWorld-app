-- ui/components.lua - Reusable UI Components
-- High-level UI widgets and components for consistent interface

local config = require("config")
local helpers = require("utils.helpers")
local themes = require("ui.themes")

local components = {}

-- Component state
components.animations = {}

-- Initialize components system
function components.initialize()
    components.animations = {}
    print("UI components initialized")
end

-- Update animations
function components.update(dt)
    for name, animation in pairs(components.animations) do
        animation.time = animation.time + dt
        if animation.duration > 0 and animation.time >= animation.duration then
            components.animations[name] = nil  -- Remove completed animations
        end
    end
end

-- Start animation
function components.startAnimation(name, duration)
    components.animations[name] = {
        time = 0,
        duration = duration or 0  -- 0 = infinite
    }
end

-- Get animation progress (0 to 1)
function components.getAnimationProgress(name)
    local animation = components.animations[name]
    if not animation then return 0 end
    if animation.duration <= 0 then return animation.time end  -- Infinite animation
    return math.min(1, animation.time / animation.duration)
end

-- Input Status Component
function components.InputStatus(x, y, joystick, deviceMapping)
    if not joystick or not joystick:isConnected() then
        themes.drawDebugText("No controller connected", x, y, "ERROR")
        return y + 20
    end
    
    local currentY = y
    
    -- Device info header
    themes.drawDebugText("Device: " .. joystick:getName(), x, currentY, "INFO")
    currentY = currentY + 20
    
    -- Button states (2 columns)
    local buttonCount = joystick:getButtonCount()
    if buttonCount > 0 then
        themes.drawDebugText("BUTTONS:", x, currentY, "WHITE")
        currentY = currentY + 20
        
        local col1X = x
        local col2X = x + 120
        local maxPerColumn = math.ceil(buttonCount / 2)
        
        for i = 1, buttonCount do
            local isPressed = joystick:isDown(i)
            local drawX = (i <= maxPerColumn) and col1X or col2X
            local drawY = currentY + ((i - 1) % maxPerColumn) * 15
            
            local buttonText = "Btn" .. i
            themes.drawButtonState(buttonText, drawX, drawY, isPressed, 50)
        end
        
        currentY = currentY + maxPerColumn * 15 + 10
    end
    
    return currentY
end

-- Axis Visualizer Component
function components.AxisVisualizer(x, y, joystick, showLabels)
    showLabels = showLabels ~= false  -- Default true
    
    if not joystick or not joystick:isConnected() then
        return y
    end
    
    local currentY = y
    local axisCount = joystick:getAxisCount()
    
    if axisCount > 0 and showLabels then
        themes.drawDebugText("AXES:", x, currentY, "WHITE")
        currentY = currentY + 20
    end
    
    for i = 1, axisCount do
        local value = joystick:getAxis(i)
        local label = showLabels and ("Axis" .. i) or nil
        themes.drawAxisBar(x, currentY, config.DEBUG_LAYOUT.AXES_BAR_WIDTH, 
                          config.DEBUG_LAYOUT.AXES_BAR_HEIGHT, value, label)
        currentY = currentY + config.DEBUG_LAYOUT.AXIS_LINE_HEIGHT
    end
    
    return currentY
end

-- Hat Status Component
function components.HatStatus(x, y, joystick)
    if not joystick or not joystick:isConnected() then
        return y
    end
    
    local currentY = y
    local hatCount = joystick:getHatCount()
    
    if hatCount > 0 then
        themes.drawDebugText("HATS (D-PAD):", x, currentY, "WHITE")
        currentY = currentY + 20
        
        for i = 1, hatCount do
            local hatValue = joystick:getHat(i)
            local color = (hatValue ~= "c") and "SUCCESS" or "BUTTON_OFF"
            local displayValue = helpers.getHatDirectionName(hatValue)
            
            themes.drawDebugText("Hat" .. i .. ": " .. displayValue, x, currentY, color)
            currentY = currentY + 15
        end
    end
    
    return currentY
end

-- Progress Indicator Component
function components.ProgressIndicator(x, y, width, current, total, label)
    local height = 25
    
    -- Label
    if label then
        themes.drawDebugText(label, x, y - 20, "UI_TEXT")
    end
    
    -- Progress bar
    local progress = total > 0 and (current / total) or 0
    themes.drawProgressBar(x, y, width, height, progress)
    
    -- Progress text
    local progressText = current .. " / " .. total
    themes.setFont("debug")
    themes.setColor("WHITE")
    local textWidth = themes.getFont("debug"):getWidth(progressText)
    love.graphics.print(progressText, x + (width - textWidth) / 2, y + 5)
    
    return y + height + 10
end

-- Mapping Display Component
function components.MappingDisplay(x, y, mappings, maxEntries, title)
    maxEntries = maxEntries or 8
    
    local currentY = y
    
    -- Title
    if title then
        themes.drawDebugText(title, x, currentY, "WHITE")
        currentY = currentY + 20
    end
    
    -- Mappings
    local count = 0
    for key, mapping in pairs(mappings) do
        if count >= maxEntries then
            themes.drawDebugText("... (" .. (helpers.countTableEntries(mappings) - maxEntries) .. " more)", 
                                x, currentY, "GRAY")
            break
        end
        
        themes.drawMappingEntry(key, mapping, x, currentY)
        currentY = currentY + 15
        count = count + 1
    end
    
    if count == 0 then
        themes.drawDebugText("No mappings", x, currentY, "GRAY")
        currentY = currentY + 15
    end
    
    return currentY
end

-- Performance Monitor Component
function components.PerformanceMonitor(x, y, fps, memory, showGraph)
    local currentY = y
    
    -- Performance text
    themes.drawDebugText("PERFORMANCE:", x, currentY, "WHITE")
    currentY = currentY + 20
    
    themes.drawDebugText("FPS: " .. tostring(fps), x, currentY, "SUCCESS")
    themes.drawDebugText("Memory: " .. tostring(memory) .. " KB", x + 100, currentY, "INFO")
    currentY = currentY + 20
    
    -- Simple performance indicator
    local fpsColor = "SUCCESS"
    if fps < 30 then fpsColor = "ERROR"
    elseif fps < 50 then fpsColor = "WARNING" end
    
    local memColor = "SUCCESS"
    if memory > 50000 then memColor = "ERROR"
    elseif memory > 25000 then memColor = "WARNING" end
    
    -- Performance bars
    local barWidth = 80
    local barHeight = 8
    
    themes.drawDebugText("FPS", x, currentY, "UI_TEXT")
    themes.drawProgressBar(x + 40, currentY + 2, barWidth, barHeight, fps / 60, "DARK_GRAY", fpsColor)
    
    themes.drawDebugText("MEM", x, currentY + 15, "UI_TEXT")
    themes.drawProgressBar(x + 40, currentY + 17, barWidth, barHeight, math.min(memory / 25000, 1), "DARK_GRAY", memColor)
    
    return currentY + 35
end

-- Status Banner Component
function components.StatusBanner(message, messageType, y)
    y = y or 50
    messageType = messageType or "INFO"
    
    local bannerHeight = 40
    local bannerY = y - bannerHeight / 2
    
    -- Background
    themes.setColor(messageType)
    love.graphics.rectangle("fill", 0, bannerY, config.SCREEN_WIDTH, bannerHeight)
    
    -- Border
    themes.setColor("WHITE")
    love.graphics.rectangle("line", 0, bannerY, config.SCREEN_WIDTH, bannerHeight)
    
    -- Text
    themes.setFont("instruction")
    themes.setColor("WHITE")
    love.graphics.printf(message, 0, bannerY + 10, config.SCREEN_WIDTH, "center")
    
    return bannerY + bannerHeight + 10
end

-- Device Connection Component
function components.DeviceConnection(x, y, joystickInfo, showDetails)
    local currentY = y
    showDetails = showDetails ~= false  -- Default true
    
    -- Connection status
    local statusColor = joystickInfo.connected and "SUCCESS" or "ERROR"
    local statusText = joystickInfo.connected and "CONNECTED" or "DISCONNECTED"
    
    themes.drawDebugText("DEVICE STATUS:", x, currentY, "WHITE")
    currentY = currentY + 20
    
    themes.drawDebugText("Name: " .. joystickInfo.name, x, currentY, statusColor)
    currentY = currentY + 15
    
    themes.drawDebugText("Status: " .. statusText, x, currentY, statusColor)
    currentY = currentY + 15
    
    if showDetails and joystickInfo.connected then
        themes.drawDebugText("Buttons: " .. joystickInfo.buttonCount, x, currentY, "UI_TEXT")
        themes.drawDebugText("Axes: " .. joystickInfo.axisCount, x + 100, currentY, "UI_TEXT")
        themes.drawDebugText("Hats: " .. joystickInfo.hatCount, x + 180, currentY, "UI_TEXT")
        currentY = currentY + 15
        
        if joystickInfo.id then
            themes.drawDebugText("ID: " .. tostring(joystickInfo.id), x, currentY, "GRAY")
            currentY = currentY + 15
        end
    end
    
    return currentY + 10
end

-- Control Hints Component
function components.ControlHints(controls, y)
    y = y or config.LAYOUT.CONTROLS_Y
    
    -- Background bar
    local barHeight = 30
    themes.setColor("DARK_GRAY")
    love.graphics.rectangle("fill", 0, y - 5, config.SCREEN_WIDTH, barHeight)
    
    -- Border
    themes.setColor("GRAY")
    love.graphics.rectangle("line", 0, y - 5, config.SCREEN_WIDTH, barHeight)
    
    -- Control text
    themes.drawCenteredText(controls, y + 5, "debug", "UI_TEXT")
    
    return y + barHeight + 5
end

-- Animated Counter Component
function components.AnimatedCounter(value, x, y, animationName)
    animationName = animationName or "counter"
    
    -- Start pulse animation on value change
    if not components.animations[animationName] then
        components.startAnimation(animationName, 0.5)
    end
    
    -- Get pulse effect
    local time = components.animations[animationName] and components.animations[animationName].time or 0
    local pulse = math.sin(time * 10) * 0.1 + 1  -- Subtle pulse
    
    -- Draw with pulse effect
    love.graphics.push()
    love.graphics.translate(x + config.SCREEN_WIDTH / 2, y)
    love.graphics.scale(pulse, pulse)
    love.graphics.translate(-config.SCREEN_WIDTH / 2, 0)
    
    themes.drawCenteredText("Counter: " .. tostring(value), 0, "counter", "SUCCESS")
    
    love.graphics.pop()
end

-- Cooldown Indicator Component
function components.CooldownIndicator(x, y, remainingTime, totalTime, label)
    if remainingTime <= 0 then return y end
    
    local width = 200
    local height = 20
    
    -- Label
    if label then
        themes.drawDebugText(label, x, y - 20, "WARNING")
    end
    
    -- Progress bar (countdown)
    local progress = 1 - (remainingTime / totalTime)
    themes.drawProgressBar(x, y, width, height, progress, "DARK_GRAY", "WARNING")
    
    -- Time text
    local timeText = string.format("%.1fs", remainingTime)
    themes.setFont("debug")
    themes.setColor("WHITE")
    local textWidth = themes.getFont("debug"):getWidth(timeText)
    love.graphics.print(timeText, x + (width - textWidth) / 2, y + 2)
    
    return y + height + 10
end

-- Get component statistics
function components.getStats()
    return {
        activeAnimations = helpers.countTableEntries(components.animations),
        animationNames = {}
    }
end

return components