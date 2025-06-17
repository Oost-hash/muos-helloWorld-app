-- input/mapper.lua - Button Mapping System
-- Handles the mapping process and mapping storage

local config = require("config")
local helpers = require("utils.helpers")

local mapper = {}

-- Mapping state
mapper.deviceMapping = {}
mapper.isInMappingMode = false
mapper.currentMappingStep = 1
mapper.waitingForInput = false
mapper.inputCooldown = 0
mapper.onMappingComplete = nil  -- Callback function

-- Initialize mapper
function mapper.initialize()
    mapper.deviceMapping = {}
    mapper.isInMappingMode = false
    mapper.currentMappingStep = 1
    mapper.waitingForInput = false
    mapper.inputCooldown = 0
    print("Button mapper initialized")
end

-- Start mapping process
function mapper.startMapping(onCompleteCallback)
    print("Starting button mapping process...")
    mapper.deviceMapping = {}
    mapper.isInMappingMode = true
    mapper.currentMappingStep = 1
    mapper.waitingForInput = true
    mapper.inputCooldown = 0
    mapper.onMappingComplete = onCompleteCallback
    
    print("Mapping step 1/" .. #config.MAPPING_SEQUENCE .. ": " .. 
          config.MAPPING_SEQUENCE[1].instruction)
end

-- Stop mapping process
function mapper.stopMapping()
    print("Stopping button mapping process")
    mapper.isInMappingMode = false
    mapper.waitingForInput = false
    mapper.inputCooldown = 0
    mapper.onMappingComplete = nil
end

-- Update mapper (called from main update loop)
function mapper.update(dt)
    if mapper.inputCooldown > 0 then
        mapper.inputCooldown = mapper.inputCooldown - dt
        if mapper.inputCooldown <= 0 then
            mapper.inputCooldown = 0
            -- Resume waiting for input if still in mapping mode
            if mapper.isInMappingMode and mapper.currentMappingStep <= #config.MAPPING_SEQUENCE then
                mapper.waitingForInput = true
                print("Ready for next input...")
            end
        end
    end
end

-- Process input during mapping
function mapper.processInput(inputType, inputId, extra)
    -- Only process if we're in mapping mode and waiting for input
    if not mapper.isInMappingMode or not mapper.waitingForInput or mapper.inputCooldown > 0 then
        return false
    end
    
    -- Validate current mapping step
    if mapper.currentMappingStep > #config.MAPPING_SEQUENCE then
        print("ERROR: Mapping step out of bounds")
        return false
    end
    
    local currentMapping = config.MAPPING_SEQUENCE[mapper.currentMappingStep]
    
    -- Create mapping entry
    local mapping = helpers.createMapping(inputType, inputId, extra)
    mapper.deviceMapping[currentMapping.key] = mapping
    
    print("Mapped " .. currentMapping.key .. " to " .. 
          inputType .. ":" .. tostring(inputId) .. 
          (extra and (":" .. tostring(extra)) or ""))
    
    -- Set cooldown to prevent double input
    mapper.inputCooldown = config.INPUT_COOLDOWN
    mapper.waitingForInput = false
    
    -- Move to next step
    mapper.currentMappingStep = mapper.currentMappingStep + 1
    
    if mapper.currentMappingStep > #config.MAPPING_SEQUENCE then
        -- Mapping complete!
        mapper.completeMapping()
    else
        -- Continue with next mapping
        local nextMapping = config.MAPPING_SEQUENCE[mapper.currentMappingStep]
        print("Mapping step " .. mapper.currentMappingStep .. "/" .. #config.MAPPING_SEQUENCE .. 
              ": " .. nextMapping.instruction)
    end
    
    return true
end

-- Complete the mapping process
function mapper.completeMapping()
    print("Button mapping complete! Mapped " .. helpers.countTableEntries(mapper.deviceMapping) .. " inputs")
    mapper.isInMappingMode = false
    mapper.waitingForInput = false
    
    -- Save mapping to file
    mapper.saveMapping()
    
    -- Call completion callback
    if mapper.onMappingComplete then
        mapper.onMappingComplete(mapper.deviceMapping)
    end
end

-- Get current mapping step info
function mapper.getCurrentStep()
    if not mapper.isInMappingMode or mapper.currentMappingStep > #config.MAPPING_SEQUENCE then
        return nil
    end
    
    return {
        step = mapper.currentMappingStep,
        total = #config.MAPPING_SEQUENCE,
        instruction = config.MAPPING_SEQUENCE[mapper.currentMappingStep].instruction,
        key = config.MAPPING_SEQUENCE[mapper.currentMappingStep].key,
        waitingForInput = mapper.waitingForInput,
        cooldown = mapper.inputCooldown
    }
end

-- Get mapping progress (0.0 to 1.0)
function mapper.getProgress()
    if not mapper.isInMappingMode then
        return mapper.deviceMapping and helpers.countTableEntries(mapper.deviceMapping) > 0 and 1.0 or 0.0
    end
    
    return (mapper.currentMappingStep - 1) / #config.MAPPING_SEQUENCE
end

-- Check if input matches a mapped button
function mapper.findMappedButton(inputType, inputId, extra)
    for buttonKey, mapping in pairs(mapper.deviceMapping) do
        if helpers.doesMappingMatch(mapping, inputType, inputId, extra) then
            return buttonKey, mapping
        end
    end
    return nil, nil
end

-- Get all mappings for a specific input type
function mapper.getMappingsByType(inputType)
    local result = {}
    for buttonKey, mapping in pairs(mapper.deviceMapping) do
        if mapping.type == inputType then
            result[buttonKey] = mapping
        end
    end
    return result
end

-- Load mapping from device mapping table
function mapper.loadMapping(mappingTable)
    if mappingTable and type(mappingTable) == "table" then
        mapper.deviceMapping = mappingTable
        print("Loaded " .. helpers.countTableEntries(mappingTable) .. " button mappings")
        return true
    else
        print("Invalid mapping table provided")
        return false
    end
end

-- Get current device mapping
function mapper.getDeviceMapping()
    return mapper.deviceMapping
end

-- Save mapping to file
function mapper.saveMapping()
    local success, error = mapper.saveMappingToFile(config.MAPPING_FILE, mapper.deviceMapping)
    if success then
        print("Mapping saved to " .. config.MAPPING_FILE)
    else
        print("Failed to save mapping: " .. (error or "unknown error"))
    end
    return success
end

-- Save mapping to file (actual file I/O)
function mapper.saveMappingToFile(filename, mapping)
    local file, error = io.open(filename, "w")
    if not file then
        return false, "Could not open file for writing: " .. (error or "unknown error")
    end
    
    -- Write mapping as Lua table
    file:write("-- Device mapping generated by Button Debug Tool v" .. config.APP_VERSION .. "\n")
    file:write("-- Generated on: " .. os.date() .. "\n\n")
    file:write("local deviceMapping = {\n")
    
    for key, value in pairs(mapping) do
        file:write("    " .. key .. " = {")
        file:write("type = \"" .. value.type .. "\", ")
        file:write("id = " .. tostring(value.id))
        
        if value.direction then
            file:write(", direction = \"" .. value.direction .. "\"")
        end
        
        file:write("},\n")
    end
    
    file:write("}\n\n")
    file:write("return deviceMapping\n")
    file:close()
    
    return true
end

-- Load mapping from file
function mapper.loadMappingFromFile(filename)
    local success, result = pcall(function()
        return dofile(filename)
    end)
    
    if success and result and type(result) == "table" then
        return mapper.loadMapping(result)
    else
        print("Could not load mapping from " .. filename .. ": " .. (result or "file not found"))
        return false
    end
end

-- Validate mapping completeness
function mapper.validateMapping(mapping)
    mapping = mapping or mapper.deviceMapping
    local issues = {}
    
    -- Check if we have basic face buttons
    local essentialButtons = {"button_south", "button_east", "button_west", "button_north"}
    for _, button in ipairs(essentialButtons) do
        if not mapping[button] then
            table.insert(issues, "Missing essential button: " .. button)
        end
    end
    
    -- Check for duplicate mappings
    local usedMappings = {}
    for key, map in pairs(mapping) do
        local mapString = map.type .. ":" .. tostring(map.id) .. ":" .. (map.direction or "")
        if usedMappings[mapString] then
            table.insert(issues, "Duplicate mapping: " .. key .. " and " .. usedMappings[mapString])
        else
            usedMappings[mapString] = key
        end
    end
    
    return #issues == 0, issues
end

-- Get mapping statistics
function mapper.getMappingStats()
    local stats = {
        totalMappings = helpers.countTableEntries(mapper.deviceMapping),
        buttonMappings = 0,
        axisMappings = 0,
        hatMappings = 0,
        isComplete = mapper.getProgress() >= 1.0,
        isValid = false,
        validationIssues = {}
    }
    
    -- Count by type
    for _, mapping in pairs(mapper.deviceMapping) do
        if mapping.type:find("button") then
            stats.buttonMappings = stats.buttonMappings + 1
        elseif mapping.type:find("axis") then
            stats.axisMappings = stats.axisMappings + 1
        elseif mapping.type:find("hat") then
            stats.hatMappings = stats.hatMappings + 1
        end
    end
    
    -- Validate
    stats.isValid, stats.validationIssues = mapper.validateMapping()
    
    return stats
end

return mapper