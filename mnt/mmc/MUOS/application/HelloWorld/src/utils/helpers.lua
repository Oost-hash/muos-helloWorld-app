-- utils/helpers.lua - Common utility functions
-- Reusable helper functions used throughout the app

local helpers = {}

-- Count entries in a table (for deviceMapping)
function helpers.countTableEntries(tbl)
    if not tbl then return 0 end
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- Format a number to specified decimal places
function helpers.formatNumber(num, decimals)
    decimals = decimals or 2
    local format = "%." .. decimals .. "f"
    return string.format(format, num)
end

-- Clamp a value between min and max
function helpers.clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

-- Check if a value is within threshold (for axis detection)
function helpers.isSignificantAxisValue(value, threshold)
    threshold = threshold or 0.05
    return math.abs(value) > threshold
end

-- Get axis direction string (positive/negative)
function helpers.getAxisDirection(value)
    if value > 0 then
        return "positive"
    elseif value < 0 then
        return "negative"
    else
        return "neutral"
    end
end

-- Convert hat direction to readable string
function helpers.getHatDirectionName(hatValue)
    local hatNames = {
        c = "center",
        u = "up",
        d = "down", 
        l = "left",
        r = "right",
        lu = "up-left",
        ru = "up-right",
        ld = "down-left",
        rd = "down-right"
    }
    return hatNames[hatValue] or "unknown"
end

-- Safe string formatting (prevents crashes on nil values)
function helpers.safeFormat(format, ...)
    local args = {...}
    for i, arg in ipairs(args) do
        if arg == nil then
            args[i] = "nil"
        end
    end
    return string.format(format, unpack(args))
end

-- Get memory usage in KB
function helpers.getMemoryUsage()
    return math.floor(collectgarbage("count"))
end

-- Time-based helpers
function helpers.getCurrentTime()
    return love.timer.getTime()
end

-- Check if enough time has passed (for cooldowns)
function helpers.hasTimeElapsed(startTime, duration)
    return (helpers.getCurrentTime() - startTime) >= duration
end

-- Input validation helpers
function helpers.isValidInputType(inputType)
    local validTypes = {
        "joystick_button",
        "joystick_axis", 
        "joystick_hat",
        "gamepad_button",
        "gamepad_axis"
    }
    
    for _, validType in ipairs(validTypes) do
        if inputType == validType then
            return true
        end
    end
    return false
end

-- Device information helpers
function helpers.getJoystickInfo(joystick)
    if not joystick then
        return {
            connected = false,
            name = "No controller",
            buttonCount = 0,
            axisCount = 0,
            hatCount = 0
        }
    end
    
    return {
        connected = joystick:isConnected(),
        name = joystick:getName(),
        buttonCount = joystick:getButtonCount(),
        axisCount = joystick:getAxisCount(),
        hatCount = joystick:getHatCount(),
        id = joystick:getID()
    }
end

-- Mapping helpers
function helpers.createMapping(inputType, inputId, extra)
    local mapping = {
        type = inputType,
        id = inputId
    }
    
    -- Add extra data for axes and hats
    if extra then
        if inputType == "joystick_axis" or inputType == "gamepad_axis" then
            mapping.direction = helpers.getAxisDirection(tonumber(extra))
        elseif inputType == "joystick_hat" then
            mapping.direction = extra
        end
    end
    
    return mapping
end

-- Mapping comparison (for input detection)
function helpers.doesMappingMatch(mapping, inputType, inputId, extra)
    if not mapping or mapping.type ~= inputType or mapping.id ~= inputId then
        return false
    end
    
    -- For axes, check direction if specified
    if mapping.direction and extra then
        if inputType:find("axis") then
            local inputDirection = helpers.getAxisDirection(tonumber(extra))
            return mapping.direction == inputDirection
        elseif inputType:find("hat") then
            return mapping.direction == extra
        end
    end
    
    return true
end

-- String helpers
function helpers.capitalizeFirst(str)
    if not str or str == "" then return str end
    return str:sub(1, 1):upper() .. str:sub(2):lower()
end

-- Debug helpers
function helpers.printTable(tbl, name)
    name = name or "Table"
    print("=== " .. name .. " ===")
    if not tbl then
        print("nil")
        return
    end
    
    for key, value in pairs(tbl) do
        if type(value) == "table" then
            print(key .. " = {table}")
        else
            print(key .. " = " .. tostring(value))
        end
    end
    print("=== End " .. name .. " ===")
end

-- Performance helpers
function helpers.getBenchmarkTime()
    return love.timer.getTime() * 1000  -- Convert to milliseconds
end

return helpers