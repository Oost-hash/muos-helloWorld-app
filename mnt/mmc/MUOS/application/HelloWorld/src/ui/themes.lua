-- ui/themes.lua - Visual Theme System
-- Manages colors, fonts, and visual styling

local config = require("config")

local themes = {}

-- Current theme state
themes.currentTheme = "default"
themes.fonts = {}

-- Initialize theme system
function themes.initialize()
    themes.loadFonts()
    print("Theme system initialized")
end

-- Load all fonts
function themes.loadFonts()
    themes.fonts = {
        title = love.graphics.newFont(config.FONTS.TITLE),
        counter = love.graphics.newFont(config.FONTS.COUNTER),
        instruction = love.graphics.newFont(config.FONTS.INSTRUCTION),
        debug = love.graphics.newFont(config.FONTS.DEBUG)
    }
    print("Fonts loaded: " .. config.FONTS.TITLE .. "/" .. config.FONTS.COUNTER .. "/" .. 
          config.FONTS.INSTRUCTION .. "/" .. config.FONTS.DEBUG)
end

-- Set color from config
function themes.setColor(colorName)
    local color = config.COLORS[colorName]
    if color then
        love.graphics.setColor(color)
    else
        print("Warning: Unknown color: " .. tostring(colorName))
        love.graphics.setColor(config.COLORS.WHITE)
    end
end

-- Get color from config
function themes.getColor(colorName)
    return config.COLORS[colorName] or config.COLORS.WHITE
end

-- Set font from config
function themes.setFont(fontName)
    local font = themes.fonts[fontName]
    if font then
        love.graphics.setFont(font)
    else
        print("Warning: Unknown font: " .. tostring(fontName))
        love.graphics.setFont(themes.fonts.debug)
    end
end

-- Get font from config
function themes.getFont(fontName)
    return themes.fonts[fontName] or themes.fonts.debug
end

-- Draw styled text with automatic color and font
function themes.drawText(text, x, y, fontName, colorName, align, width)
    themes.setFont(fontName)
    themes.setColor(colorName)
    
    if align and width then
        love.graphics.printf(text, x, y, width, align)
    else
        love.graphics.print(text, x, y)
    end
end

-- Draw centered text
function themes.drawCenteredText(text, y, fontName, colorName)
    themes.drawText(text, 0, y, fontName, colorName, "center", config.SCREEN_WIDTH)
end

-- Draw title text (large, centered)
function themes.drawTitle(text, y)
    themes.drawCenteredText(text, y or config.LAYOUT.TITLE_Y, "title", "WHITE")
end

-- Draw instruction text
function themes.drawInstruction(text, y)
    themes.drawCenteredText(text, y, "instruction", "WHITE")
end

-- Draw debug text
function themes.drawDebugText(text, x, y, colorName)
    themes.drawText(text, x, y, "debug", colorName or "UI_TEXT")
end

-- Draw counter (big, prominent)
function themes.drawCounter(value, y)
    themes.drawCenteredText("Counter: " .. tostring(value), y or config.LAYOUT.COUNTER_Y, "counter", "SUCCESS")
end

-- Draw progress bar
function themes.drawProgressBar(x, y, width, height, progress, backgroundColor, foregroundColor)
    backgroundColor = backgroundColor or "DARK_GRAY"
    foregroundColor = foregroundColor or "SUCCESS"
    
    -- Background
    themes.setColor(backgroundColor)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Progress fill
    if progress > 0 then
        themes.setColor(foregroundColor)
        local fillWidth = width * math.min(1.0, math.max(0.0, progress))
        love.graphics.rectangle("fill", x, y, fillWidth, height)
    end
    
    -- Border
    themes.setColor("WHITE")
    love.graphics.rectangle("line", x, y, width, height)
end

-- Draw button state indicator
function themes.drawButtonState(text, x, y, isPressed, width)
    width = width or 60
    local height = 20
    
    -- Background
    themes.setColor(isPressed and "BUTTON_ON" or "BUTTON_OFF")
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Border
    themes.setColor("WHITE")
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Text
    themes.setFont("debug")
    themes.setColor("WHITE")
    local textWidth = themes.getFont("debug"):getWidth(text)
    local textX = x + (width - textWidth) / 2
    local textY = y + (height - themes.getFont("debug"):getHeight()) / 2
    love.graphics.print(text, textX, textY)
end

-- Draw axis value bar (for joystick visualization)
function themes.drawAxisBar(x, y, width, height, value, label)
    -- Background
    themes.setColor("DARK_GRAY")
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Center line
    local centerX = x + width / 2
    themes.setColor("GRAY")
    love.graphics.line(centerX, y, centerX, y + height)
    
    -- Value bar
    if math.abs(value) > 0.01 then
        themes.setColor(value > 0 and "AXIS_POSITIVE" or "AXIS_NEGATIVE")
        local barWidth = math.abs(value) * (width / 2)
        local barX = value > 0 and centerX or (centerX - barWidth)
        love.graphics.rectangle("fill", barX, y, barWidth, height)
    end
    
    -- Border
    themes.setColor("WHITE")
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Label
    if label then
        themes.drawDebugText(label, x, y - 15)
    end
    
    -- Value text
    local valueText = string.format("%.2f", value)
    themes.drawDebugText(valueText, x + width + 5, y + 2)
end

-- Draw device status indicator
function themes.drawDeviceStatus(deviceName, isConnected, x, y)
    local statusColor = isConnected and "SUCCESS" or "ERROR"
    local statusText = isConnected and "CONNECTED" or "DISCONNECTED"
    
    themes.drawDebugText("Device: " .. deviceName, x, y, statusColor)
    themes.drawDebugText("Status: " .. statusText, x, y + 15, statusColor)
end

-- Draw performance info
function themes.drawPerformanceInfo(fps, memory, x, y)
    themes.drawDebugText("FPS: " .. tostring(fps), x, y, "UI_TEXT")
    themes.drawDebugText("Memory: " .. tostring(memory) .. " KB", x, y + 15, "UI_TEXT")
end

-- Draw mapping entry (for debug display)
function themes.drawMappingEntry(key, mapping, x, y, maxWidth)
    maxWidth = maxWidth or 200
    
    local text = key .. " = " .. mapping.type .. ":" .. tostring(mapping.id)
    if mapping.direction then
        text = text .. ":" .. mapping.direction
    end
    
    -- Truncate if too long
    local font = themes.getFont("debug")
    if font:getWidth(text) > maxWidth then
        text = text:sub(1, 30) .. "..."
    end
    
    themes.drawDebugText(text, x, y, "LIGHT_GRAY")
end

-- Draw setup screen layout
function themes.drawSetupScreen(step, total, instruction, waitingForInput, cooldown)
    -- Title
    themes.drawTitle(config.APP_NAME)
    
    -- Progress
    local progressY = config.LAYOUT.SETUP_PROGRESS_Y
    themes.drawCenteredText("Setup Progress", progressY - 30, "instruction", "UI_TEXT")
    
    local progressBarX = (config.SCREEN_WIDTH - 300) / 2
    local progress = (step - 1) / total
    themes.drawProgressBar(progressBarX, progressY, 300, 20, progress)
    
    -- Step counter
    themes.drawCenteredText(step .. " / " .. total, progressY + 30, "debug", "UI_TEXT")
    
    -- Current instruction
    themes.drawCenteredText(instruction, config.LAYOUT.SETUP_INSTRUCTION_Y, "instruction", "WARNING")
    
    -- Status
    local statusY = config.LAYOUT.SETUP_WAIT_Y
    if cooldown > 0 then
        themes.drawCenteredText("Processing... (" .. string.format("%.1f", cooldown) .. "s)", 
                               statusY, "debug", "WARNING")
    elseif waitingForInput then
        themes.drawCenteredText("Waiting for input...", statusY, "debug", "SUCCESS")
    else
        themes.drawCenteredText("Ready", statusY, "debug", "UI_TEXT")
    end
end

-- Draw main screen layout
function themes.drawMainScreen(counter, fps, memory, deviceName, deviceConnected, controls)
    -- Title
    themes.drawTitle(config.APP_NAME)
    
    -- Counter (main feature)
    themes.drawCounter(counter)
    
    -- Performance info
    themes.drawCenteredText("FPS: " .. tostring(fps), config.LAYOUT.FPS_Y, "instruction", "WHITE")
    themes.drawCenteredText("Memory: " .. tostring(memory) .. " KB", config.LAYOUT.MEMORY_Y, "instruction", "WHITE")
    
    -- Controls
    themes.drawCenteredText(controls, config.LAYOUT.CONTROLS_Y, "debug", "UI_TEXT")
    
    -- Device status
    local deviceColor = deviceConnected and "SUCCESS" or "ERROR"
    themes.drawCenteredText("Device: " .. deviceName, config.LAYOUT.DEVICE_Y, "instruction", deviceColor)
end

-- Draw debug screen header
function themes.drawDebugScreenHeader()
    themes.drawTitle("=== DEBUG SCREEN ===")
    themes.drawCenteredText("Press North (Y) to return to main screen", 
                           config.LAYOUT.DEBUG_EXIT_Y, "instruction", "WARNING")
end

-- Draw debug device info
function themes.drawDebugDeviceInfo(deviceInfo, y)
    local startY = y or config.LAYOUT.DEBUG_INFO_Y
    
    themes.drawCenteredText("Device: " .. deviceInfo.name, startY, "debug", "INFO")
    themes.drawCenteredText("Buttons: " .. deviceInfo.buttonCount .. 
                           " | Axes: " .. deviceInfo.axisCount .. 
                           " | Hats: " .. deviceInfo.hatCount, 
                           startY + 20, "debug", "UI_TEXT")
end

-- Draw section header
function themes.drawSectionHeader(title, x, y)
    themes.drawDebugText("=== " .. title .. " ===", x, y, "WHITE")
    return y + 20  -- Return next Y position
end

-- Animation and effects
function themes.pulseColor(baseColor, time, speed)
    speed = speed or 2
    local pulse = (math.sin(time * speed) + 1) / 2  -- 0 to 1
    local color = themes.getColor(baseColor)
    return {
        color[1] * (0.5 + pulse * 0.5),
        color[2] * (0.5 + pulse * 0.5),
        color[3] * (0.5 + pulse * 0.5)
    }
end

-- Get theme info
function themes.getThemeInfo()
    return {
        name = themes.currentTheme,
        fonts = {
            title = config.FONTS.TITLE,
            counter = config.FONTS.COUNTER,
            instruction = config.FONTS.INSTRUCTION,
            debug = config.FONTS.DEBUG
        },
        colors = config.COLORS
    }
end

return themes