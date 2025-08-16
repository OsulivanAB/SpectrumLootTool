local ADDON_NAME, SLH = ...

-- ============================================================================
-- Database Management Module (Beta Version)
-- ============================================================================
-- Purpose: Manage addon's database with player-specific equipment tracking
-- Keys: PlayerName-ServerName-WoWVersion (major.minor)
-- Version: 0.2.0 Beta - Simple structure aligned with WoW addon best practices
-- ============================================================================

SLH.Database = SLH.Database or {}
local Database = SLH.Database

-- ============================================================================
-- CONSTANTS AND CONFIGURATION
-- ============================================================================

-- Database version for future migration support
Database.DB_VERSION = "1.0.0"

-- Equipment slot definitions for tracking
Database.EQUIPMENT_SLOTS = {
    "Head", "Neck", "Shoulder", "Back", "Chest", "Wrist", 
    "Gloves", "Belt", "Legs", "Feet",
    "Ring1", "Ring2", "Trinket1", "Trinket2",
    "MainHand", "OffHand"
}

-- ============================================================================
-- DATABASE INITIALIZATION
-- ============================================================================

-- ============================================================================
-- ERROR HANDLING UTILITIES (Task 9)
-- ============================================================================

-- Safe function execution wrapper with error handling
-- Uses pcall to catch errors and log them appropriately
local function SafeExecute(operation, funcName, ...)
    local success, result = pcall(operation, ...)
    if not success then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Error in " .. funcName, {
                error = result,
                function_name = funcName
            })
        end
        return false, result
    end
    return true, result
end

-- Initialize database and saved variables
-- Sets up SpectrumLootHelperDB.playerData table structure
-- Handles first-time setup and ensures proper database structure
function Database:Init()
    if SLH.Debug then
        SLH.Debug:LogDebug("Database", "Database:Init() called", {})
    end
    
    -- Wrap the entire initialization in error handling
    local success, result = SafeExecute(function()
        return Database:_InitInternal()
    end, "Init")
    
    if not success then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Database initialization failed", {
                error = result
            })
        end
        return false
    end
    
    return result
end

-- Internal initialization logic (separated for error handling)
function Database:_InitInternal()
    
    -- Ensure SpectrumLootHelperDB exists (should be initialized by Core.lua)
    if not SpectrumLootHelperDB then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "SpectrumLootHelperDB not found during Database:Init()", {})
        end
        return false
    end
    
    -- Initialize playerData table if it doesn't exist
    if not SpectrumLootHelperDB.playerData then
        SpectrumLootHelperDB.playerData = {}
        if SLH.Debug then
            SLH.Debug:LogInfo("Database", "Created new playerData table", {})
        end
    end
    
    -- Set up database version tracking
    if not SpectrumLootHelperDB.databaseVersion then
        SpectrumLootHelperDB.databaseVersion = Database.DB_VERSION
        if SLH.Debug then
            SLH.Debug:LogInfo("Database", "Set initial database version", { 
                version = Database.DB_VERSION 
            })
        end
    end
    
    -- Validate saved variables are available and writable (Task 2 requirement)
    local testKey = "__database_write_test__"
    local writeTestSuccess = false
    
    -- Test write capability
    SpectrumLootHelperDB.playerData[testKey] = true
    if SpectrumLootHelperDB.playerData[testKey] == true then
        writeTestSuccess = true
        -- Clean up test
        SpectrumLootHelperDB.playerData[testKey] = nil
        if SLH.Debug then
            SLH.Debug:LogDebug("Database", "Saved variables write test successful", {})
        end
    else
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Saved variables write test failed", {})
        end
    end
    
    -- Handle addon reload/logout persistence validation (Task 2 requirement)
    if not SpectrumLootHelperDB.lastDatabaseAccess then
        SpectrumLootHelperDB.lastDatabaseAccess = time()
        if SLH.Debug then
            SLH.Debug:LogInfo("Database", "First database access recorded", {
                timestamp = SpectrumLootHelperDB.lastDatabaseAccess
            })
        end
    else
        local timeSinceLastAccess = time() - SpectrumLootHelperDB.lastDatabaseAccess
        SpectrumLootHelperDB.lastDatabaseAccess = time()
        if SLH.Debug then
            SLH.Debug:LogInfo("Database", "Database persistence validated", {
                timeSinceLastAccess = timeSinceLastAccess,
                timestamp = SpectrumLootHelperDB.lastDatabaseAccess
            })
        end
    end
    
    -- Verify saved variables structure is correct
    local structureValid = true
    if type(SpectrumLootHelperDB.playerData) ~= "table" then
        structureValid = false
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Invalid playerData structure - not a table", {
                actualType = type(SpectrumLootHelperDB.playerData)
            })
        end
    end
    
    if not structureValid then
        -- Reset to correct structure if corrupted
        SpectrumLootHelperDB.playerData = {}
        if SLH.Debug then
            SLH.Debug:LogWarn("Database", "Reset corrupted playerData structure", {})
        end
    end
    
    -- Log successful initialization completion
    if SLH.Debug then
        SLH.Debug:LogInfo("Database", "Database initialization completed", {
            dbVersion = Database.DB_VERSION,
            equipmentSlots = #Database.EQUIPMENT_SLOTS,
            playerDataExists = SpectrumLootHelperDB.playerData ~= nil,
            structureValid = structureValid,
            savedVariablesWritable = writeTestSuccess,
            persistenceValidated = SpectrumLootHelperDB.lastDatabaseAccess ~= nil
        })
    end
    
    return writeTestSuccess and structureValid
end

-- ============================================================================
-- SCHEMA DEFINITION
-- ============================================================================

-- Define and validate database entry structure
-- Returns template structure for new database entries
-- Each entry contains: LastUpdate timestamp, VenariiCharges (>=0), Equipment (16 slots as booleans)
function Database:GetEntrySchema()
    if SLH.Debug then
        SLH.Debug:LogDebug("Database", "GetEntrySchema() called", {})
    end
    
    -- Wrap schema generation in error handling
    local success, result = SafeExecute(function()
        return Database:_GetEntrySchemaInternal()
    end, "GetEntrySchema")
    
    if not success then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Schema generation failed", {
                error = result
            })
        end
        return nil
    end
    
    return result
end

-- Internal schema generation logic (separated for error handling)
function Database:_GetEntrySchemaInternal()
    
    -- Create equipment structure with all slots defaulting to false
    local equipment = {}
    for i, slotName in ipairs(Database.EQUIPMENT_SLOTS) do
        equipment[slotName] = false
    end
    
    -- Create complete entry schema with defaults
    local schema = {
        LastUpdate = time(), -- Current timestamp
        VenariiCharges = 0,  -- Default to 0 charges
        Equipment = equipment -- All equipment slots default to false
    }
    
    if SLH.Debug then
        SLH.Debug:LogInfo("Database", "Entry schema created", {
            equipmentSlots = #Database.EQUIPMENT_SLOTS,
            defaultVenariiCharges = schema.VenariiCharges,
            hasTimestamp = schema.LastUpdate ~= nil
        })
    end
    
    return schema
end

-- ============================================================================
-- KEY GENERATION
-- ============================================================================

-- Generate unique database keys from player info
-- Format: "PlayerName-ServerName-WoWVersion"
-- Example: "Osulivan-Garona-10.2"
function Database:GenerateKey(playerName, serverName, wowVersion)
    if SLH.Debug then
        SLH.Debug:LogDebug("Database", "GenerateKey() called", {
            playerName = playerName,
            serverName = serverName,
            wowVersion = wowVersion
        })
    end
    
    -- Wrap key generation in error handling
    local success, result = SafeExecute(function()
        return Database:_GenerateKeyInternal(playerName, serverName, wowVersion)
    end, "GenerateKey")
    
    if not success then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Key generation failed", {
                playerName = playerName,
                serverName = serverName,
                wowVersion = wowVersion,
                error = result
            })
        end
        return nil
    end
    
    return result
end

-- Internal key generation logic (separated for error handling)
function Database:_GenerateKeyInternal(playerName, serverName, wowVersion)
    
    -- Validate input parameters are not nil/empty
    if not playerName or playerName == "" then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Invalid playerName parameter", { 
                playerName = playerName 
            })
        end
        return nil
    end
    
    if not serverName or serverName == "" then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Invalid serverName parameter", { 
                serverName = serverName 
            })
        end
        return nil
    end
    
    if not wowVersion or wowVersion == "" then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Invalid wowVersion parameter", { 
                wowVersion = wowVersion 
            })
        end
        return nil
    end
    
    -- Clean and normalize player/server names
    local cleanPlayerName = playerName:gsub("%s+", ""):gsub("[^%w%-]", "")
    local cleanServerName = serverName:gsub("%s+", ""):gsub("[^%w%-]", "")
    
    -- Extract major.minor from WoW version if needed (e.g., "10.2.5" -> "10.2")
    local majorMinor = wowVersion:match("(%d+%.%d+)")
    if not majorMinor then
        majorMinor = wowVersion -- Use as-is if pattern doesn't match
    end
    
    -- Return formatted key string
    local key = cleanPlayerName .. "-" .. cleanServerName .. "-" .. majorMinor
    
    -- Log key generation for debugging
    if SLH.Debug then
        SLH.Debug:LogInfo("Database", "Generated database key", {
            originalPlayerName = playerName,
            cleanPlayerName = cleanPlayerName,
            originalServerName = serverName,
            cleanServerName = cleanServerName,
            originalWowVersion = wowVersion,
            extractedVersion = majorMinor,
            generatedKey = key
        })
    end
    
    return key
end

-- Get current player's database key
-- Uses WoW APIs to get player name, server name, and WoW version
-- Handles loading states gracefully and returns generated key
function Database:GetCurrentPlayerKey()
    if SLH.Debug then
        SLH.Debug:LogDebug("Database", "GetCurrentPlayerKey() called", {})
    end
    
    -- Wrap current player key generation in error handling
    local success, result = SafeExecute(function()
        return Database:_GetCurrentPlayerKeyInternal()
    end, "GetCurrentPlayerKey")
    
    if not success then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Current player key generation failed", {
                error = result
            })
        end
        return nil
    end
    
    return result
end

-- Internal current player key logic (separated for error handling)
function Database:_GetCurrentPlayerKeyInternal()
    
    -- Get current player name from WoW API
    local playerName = UnitName("player")
    if not playerName or playerName == "" then
        if SLH.Debug then
            SLH.Debug:LogWarn("Database", "Player name not available yet", {
                playerName = playerName,
                loading = true
            })
        end
        return nil -- Handle loading state gracefully
    end
    
    -- Get current server name from WoW API
    local serverName = GetRealmName()
    if not serverName or serverName == "" then
        if SLH.Debug then
            SLH.Debug:LogWarn("Database", "Server name not available yet", {
                serverName = serverName,
                loading = true
            })
        end
        return nil -- Handle loading state gracefully
    end
    
    -- Get current WoW version from WoW API
    local wowVersion, buildNumber, buildDate, gameVersion = GetBuildInfo()
    if not wowVersion or wowVersion == "" then
        if SLH.Debug then
            SLH.Debug:LogWarn("Database", "WoW version not available yet", {
                wowVersion = wowVersion,
                loading = true
            })
        end
        return nil -- Handle loading state gracefully
    end
    
    -- Call GenerateKey() with current player info
    local key = self:GenerateKey(playerName, serverName, wowVersion)
    
    if SLH.Debug then
        SLH.Debug:LogInfo("Database", "Current player key generated", {
            playerName = playerName,
            serverName = serverName,
            wowVersion = wowVersion,
            buildNumber = buildNumber,
            gameVersion = gameVersion,
            generatedKey = key,
            success = key ~= nil
        })
    end
    
    -- Return generated key
    return key
end

-- ============================================================================
-- DATA ACCESS METHODS
-- ============================================================================

-- Add new player entry to database
-- Checks for duplicates, applies schema template, validates, and saves
-- Returns success status and entry key or error message
function Database:AddEntry(playerName, serverName, wowVersion, initialData)
    if SLH.Debug then
        SLH.Debug:LogDebug("Database", "AddEntry() called", {
            playerName = playerName,
            serverName = serverName,
            wowVersion = wowVersion,
            hasInitialData = initialData ~= nil
        })
    end
    
    -- Wrap entry addition in error handling
    local success, result, key = SafeExecute(function()
        return Database:_AddEntryInternal(playerName, serverName, wowVersion, initialData)
    end, "AddEntry")
    
    if not success then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Entry addition failed", {
                playerName = playerName,
                serverName = serverName,
                wowVersion = wowVersion,
                error = result
            })
        end
        return false, result
    end
    
    return result, key
end

-- Internal entry addition logic (separated for error handling)
function Database:_AddEntryInternal(playerName, serverName, wowVersion, initialData)
    
    -- Generate key using GenerateKey()
    local key = self:GenerateKey(playerName, serverName, wowVersion)
    if not key then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Failed to generate key for new entry", {
                playerName = playerName,
                serverName = serverName,
                wowVersion = wowVersion
            })
        end
        return false, "Failed to generate player key"
    end
    
    -- Check if entry already exists (duplicate check)
    if not SpectrumLootHelperDB then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "SpectrumLootHelperDB not available for AddEntry", {})
        end
        return false, "Database not initialized"
    end
    
    if not SpectrumLootHelperDB.playerData then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "playerData table not available for AddEntry", {})
        end
        return false, "Player data table not initialized"
    end
    
    if SpectrumLootHelperDB.playerData[key] then
        if SLH.Debug then
            SLH.Debug:LogWarn("Database", "Entry already exists - duplicate detected", {
                key = key,
                playerName = playerName,
                serverName = serverName,
                wowVersion = wowVersion
            })
        end
        return false, "Entry already exists for this player"
    end
    
    -- Create new entry using schema template
    local newEntry = self:GetEntrySchema()
    if not newEntry then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Failed to get entry schema for new entry", {
                key = key
            })
        end
        return false, "Failed to create entry schema"
    end
    
    -- Apply initial data if provided
    if initialData and type(initialData) == "table" then
        if SLH.Debug then
            SLH.Debug:LogDebug("Database", "Applying initial data to new entry", {
                key = key,
                initialDataKeys = {}
            })
        end
        
        -- Log initial data keys for debugging
        for k, _ in pairs(initialData) do
            table.insert(SLH.Debug and {} or {}, k)
        end
        
        -- Apply VenariiCharges if provided
        if initialData.VenariiCharges ~= nil then
            local chargesValid, chargesError = self:ValidateVenariiCharges(initialData.VenariiCharges)
            if chargesValid then
                newEntry.VenariiCharges = initialData.VenariiCharges
                if SLH.Debug then
                    SLH.Debug:LogDebug("Database", "Applied initial VenariiCharges", {
                        key = key,
                        charges = initialData.VenariiCharges
                    })
                end
            else
                if SLH.Debug then
                    SLH.Debug:LogWarn("Database", "Invalid initial VenariiCharges ignored", {
                        key = key,
                        charges = initialData.VenariiCharges,
                        error = chargesError
                    })
                end
            end
        end
        
        -- Apply Equipment if provided
        if initialData.Equipment ~= nil then
            local equipmentValid, equipmentError = self:ValidateEquipment(initialData.Equipment)
            if equipmentValid then
                newEntry.Equipment = initialData.Equipment
                if SLH.Debug then
                    SLH.Debug:LogDebug("Database", "Applied initial Equipment data", {
                        key = key,
                        equipmentSlots = {}
                    })
                end
                
                -- Log applied equipment slots for debugging
                for slotName, value in pairs(initialData.Equipment) do
                    if SLH.Debug then
                        table.insert({}, slotName .. "=" .. tostring(value))
                    end
                end
            else
                if SLH.Debug then
                    SLH.Debug:LogWarn("Database", "Invalid initial Equipment ignored", {
                        key = key,
                        equipment = initialData.Equipment,
                        error = equipmentError
                    })
                end
            end
        end
    end
    
    -- Set LastUpdate timestamp (always current time for new entries)
    newEntry.LastUpdate = time()
    
    -- Validate entry before saving
    local entryValid, entryError = self:ValidateEntry(newEntry)
    if not entryValid then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "New entry failed validation", {
                key = key,
                entry = newEntry,
                error = entryError
            })
        end
        return false, "Entry validation failed: " .. (entryError or "unknown error")
    end
    
    -- Save to SpectrumLootHelperDB.playerData
    SpectrumLootHelperDB.playerData[key] = newEntry
    
    -- Log successful addition
    if SLH.Debug then
        SLH.Debug:LogInfo("Database", "Successfully added new entry", {
            key = key,
            playerName = playerName,
            serverName = serverName,
            wowVersion = wowVersion,
            venariiCharges = newEntry.VenariiCharges,
            lastUpdate = newEntry.LastUpdate,
            hasInitialData = initialData ~= nil,
            totalEntries = 0 -- Will be calculated below
        })
    end
    
    -- Count total entries for logging
    local totalEntries = 0
    for _ in pairs(SpectrumLootHelperDB.playerData) do
        totalEntries = totalEntries + 1
    end
    
    if SLH.Debug then
        SLH.Debug:LogInfo("Database", "Database now contains entries", {
            totalEntries = totalEntries,
            newEntryKey = key
        })
    end
    
    return true, key
end

-- Update existing player entry
-- Supports partial updates, validates changes before applying, and updates timestamp
-- Returns success status and updated entry data or error message
function Database:UpdateEntry(playerName, serverName, wowVersion, updateData)
    if SLH.Debug then
        SLH.Debug:LogDebug("Database", "UpdateEntry() called", {
            playerName = playerName,
            serverName = serverName,
            wowVersion = wowVersion,
            hasUpdateData = updateData ~= nil
        })
    end
    
    -- Wrap entry update in error handling
    local success, result, updatedEntry = SafeExecute(function()
        return Database:_UpdateEntryInternal(playerName, serverName, wowVersion, updateData)
    end, "UpdateEntry")
    
    if not success then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Entry update failed", {
                playerName = playerName,
                serverName = serverName,
                wowVersion = wowVersion,
                error = result
            })
        end
        return false, result
    end
    
    return result, updatedEntry
end

-- Internal entry update logic (separated for error handling)
function Database:_UpdateEntryInternal(playerName, serverName, wowVersion, updateData)
    
    -- Generate key and check if entry exists
    local key = self:GenerateKey(playerName, serverName, wowVersion)
    if not key then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Failed to generate key for entry update", {
                playerName = playerName,
                serverName = serverName,
                wowVersion = wowVersion
            })
        end
        return false, "Failed to generate player key"
    end
    
    -- Check if database structures exist
    if not SpectrumLootHelperDB then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "SpectrumLootHelperDB not available for UpdateEntry", {})
        end
        return false, "Database not initialized"
    end
    
    if not SpectrumLootHelperDB.playerData then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "playerData table not available for UpdateEntry", {})
        end
        return false, "Player data table not initialized"
    end
    
    -- Check if entry exists before updating
    local existingEntry = SpectrumLootHelperDB.playerData[key]
    if not existingEntry then
        if SLH.Debug then
            SLH.Debug:LogWarn("Database", "Entry not found for update", {
                key = key,
                playerName = playerName,
                serverName = serverName,
                wowVersion = wowVersion
            })
        end
        return false, "Entry not found - cannot update non-existent entry"
    end
    
    -- Validate update data structure
    if not updateData or type(updateData) ~= "table" then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Invalid updateData for entry update", {
                key = key,
                updateData = updateData,
                updateDataType = type(updateData)
            })
        end
        return false, "Update data must be a non-empty table"
    end
    
    -- Create a deep copy of existing entry for safe updates
    local updatedEntry = {}
    for field, value in pairs(existingEntry) do
        if type(value) == "table" then
            -- Deep copy tables (like Equipment)
            updatedEntry[field] = {}
            for k, v in pairs(value) do
                updatedEntry[field][k] = v
            end
        else
            updatedEntry[field] = value
        end
    end
    
    -- Track changed fields for logging
    local changedFields = {}
    
    -- Apply updates to existing entry (partial updates supported)
    if updateData.VenariiCharges ~= nil then
        -- Validate VenariiCharges before applying
        local chargesValid, chargesError = self:ValidateVenariiCharges(updateData.VenariiCharges)
        if chargesValid then
            local oldValue = updatedEntry.VenariiCharges
            updatedEntry.VenariiCharges = updateData.VenariiCharges
            table.insert(changedFields, {
                field = "VenariiCharges",
                oldValue = oldValue,
                newValue = updateData.VenariiCharges
            })
            if SLH.Debug then
                SLH.Debug:LogDebug("Database", "Updated VenariiCharges", {
                    key = key,
                    oldValue = oldValue,
                    newValue = updateData.VenariiCharges
                })
            end
        else
            if SLH.Debug then
                SLH.Debug:LogWarn("Database", "Invalid VenariiCharges update ignored", {
                    key = key,
                    charges = updateData.VenariiCharges,
                    error = chargesError
                })
            end
            return false, "VenariiCharges validation failed: " .. (chargesError or "unknown error")
        end
    end
    
    -- Apply Equipment updates (partial equipment updates supported)
    if updateData.Equipment ~= nil then
        -- Validate Equipment before applying
        local equipmentValid, equipmentError = self:ValidateEquipment(updateData.Equipment)
        if equipmentValid then
            local oldEquipment = {}
            for k, v in pairs(updatedEntry.Equipment) do
                oldEquipment[k] = v
            end
            
            -- Apply equipment slot updates (partial updates within Equipment)
            for slotName, slotValue in pairs(updateData.Equipment) do
                if updatedEntry.Equipment[slotName] ~= nil then
                    local oldValue = updatedEntry.Equipment[slotName]
                    updatedEntry.Equipment[slotName] = slotValue
                    table.insert(changedFields, {
                        field = "Equipment." .. slotName,
                        oldValue = oldValue,
                        newValue = slotValue
                    })
                else
                    if SLH.Debug then
                        SLH.Debug:LogWarn("Database", "Unknown equipment slot ignored", {
                            key = key,
                            slotName = slotName,
                            slotValue = slotValue
                        })
                    end
                end
            end
            
            if SLH.Debug then
                SLH.Debug:LogDebug("Database", "Updated Equipment slots", {
                    key = key,
                    updatedSlots = {}
                })
            end
            
            -- Log updated slots for debugging
            for _, change in ipairs(changedFields) do
                if change.field:match("^Equipment%.") then
                    if SLH.Debug then
                        table.insert({}, change.field .. ": " .. tostring(change.oldValue) .. " -> " .. tostring(change.newValue))
                    end
                end
            end
        else
            if SLH.Debug then
                SLH.Debug:LogWarn("Database", "Invalid Equipment update ignored", {
                    key = key,
                    equipment = updateData.Equipment,
                    error = equipmentError
                })
            end
            return false, "Equipment validation failed: " .. (equipmentError or "unknown error")
        end
    end
    
    -- Check if any changes were actually made
    if #changedFields == 0 then
        if SLH.Debug then
            SLH.Debug:LogInfo("Database", "No valid changes found in update data", {
                key = key,
                updateData = updateData
            })
        end
        return false, "No valid changes to apply"
    end
    
    -- Update LastUpdate timestamp
    local oldTimestamp = updatedEntry.LastUpdate
    updatedEntry.LastUpdate = time()
    table.insert(changedFields, {
        field = "LastUpdate",
        oldValue = oldTimestamp,
        newValue = updatedEntry.LastUpdate
    })
    
    -- Validate updated entry before saving
    local entryValid, entryError = self:ValidateEntry(updatedEntry)
    if not entryValid then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Updated entry failed validation", {
                key = key,
                entry = updatedEntry,
                error = entryError
            })
        end
        return false, "Updated entry validation failed: " .. (entryError or "unknown error")
    end
    
    -- Save changes to database
    SpectrumLootHelperDB.playerData[key] = updatedEntry
    
    -- Log successful update with changed fields
    if SLH.Debug then
        SLH.Debug:LogInfo("Database", "Successfully updated entry", {
            key = key,
            playerName = playerName,
            serverName = serverName,
            wowVersion = wowVersion,
            changedFields = #changedFields,
            changes = {}
        })
    end
    
    -- Log individual field changes for debugging
    for _, change in ipairs(changedFields) do
        if SLH.Debug then
            table.insert({}, change.field .. ": " .. tostring(change.oldValue) .. " -> " .. tostring(change.newValue))
        end
    end
    
    return true, updatedEntry
end

-- Retrieve player entry from database
-- Returns entry data or nil if not found with safe null handling
-- Provides comprehensive logging for retrieval attempts and results
function Database:GetEntry(playerName, serverName, wowVersion)
    if SLH.Debug then
        SLH.Debug:LogDebug("Database", "GetEntry() called", {
            playerName = playerName,
            serverName = serverName,
            wowVersion = wowVersion
        })
    end
    
    -- Wrap entry retrieval in error handling
    local success, result = SafeExecute(function()
        return Database:_GetEntryInternal(playerName, serverName, wowVersion)
    end, "GetEntry")
    
    if not success then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Entry retrieval failed", {
                playerName = playerName,
                serverName = serverName,
                wowVersion = wowVersion,
                error = result
            })
        end
        return nil -- Safe null handling on error
    end
    
    return result
end

-- Internal entry retrieval logic (separated for error handling)
function Database:_GetEntryInternal(playerName, serverName, wowVersion)
    
    -- Generate key for lookup
    local key = self:GenerateKey(playerName, serverName, wowVersion)
    if not key then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Failed to generate key for entry lookup", {
                playerName = playerName,
                serverName = serverName,
                wowVersion = wowVersion
            })
        end
        return nil -- Safe null handling for invalid key
    end
    
    -- Safe null handling - check if database structures exist
    if not SpectrumLootHelperDB then
        if SLH.Debug then
            SLH.Debug:LogWarn("Database", "SpectrumLootHelperDB not available for GetEntry", {
                key = key,
                playerName = playerName
            })
        end
        return nil -- Safe null handling for missing database
    end
    
    if not SpectrumLootHelperDB.playerData then
        if SLH.Debug then
            SLH.Debug:LogWarn("Database", "playerData table not available for GetEntry", {
                key = key,
                playerName = playerName
            })
        end
        return nil -- Safe null handling for missing player data table
    end
    
    -- Check if entry exists in database
    local entry = SpectrumLootHelperDB.playerData[key]
    
    if entry == nil then
        if SLH.Debug then
            SLH.Debug:LogInfo("Database", "Entry not found in database", {
                key = key,
                playerName = playerName,
                serverName = serverName,
                wowVersion = wowVersion,
                found = false
            })
        end
        return nil -- Entry not found - return nil as specified
    end
    
    -- Validate entry structure before returning (safe null handling)
    if type(entry) ~= "table" then
        if SLH.Debug then
            SLH.Debug:LogWarn("Database", "Entry exists but has invalid structure", {
                key = key,
                entry = entry,
                entryType = type(entry),
                expectedType = "table"
            })
        end
        return nil -- Safe null handling for corrupted entry
    end
    
    -- Optional: Validate entry against schema for data integrity
    local entryValid, entryError = self:ValidateEntry(entry)
    if not entryValid then
        if SLH.Debug then
            SLH.Debug:LogWarn("Database", "Retrieved entry failed validation", {
                key = key,
                entry = entry,
                validationError = entryError,
                returnedAnyway = true
            })
        end
        -- Note: We still return the entry even if validation fails,
        -- as the caller may want to handle or repair the data
    end
    
    -- Log successful retrieval with entry details
    if SLH.Debug then
        SLH.Debug:LogInfo("Database", "Successfully retrieved entry from database", {
            key = key,
            playerName = playerName,
            serverName = serverName,
            wowVersion = wowVersion,
            found = true,
            hasVenariiCharges = entry.VenariiCharges ~= nil,
            hasEquipment = entry.Equipment ~= nil,
            hasLastUpdate = entry.LastUpdate ~= nil,
            venariiCharges = entry.VenariiCharges,
            lastUpdate = entry.LastUpdate,
            entryValid = entryValid
        })
    end
    
    -- Return entry data (never nil at this point due to earlier checks)
    return entry
end

-- Delete player entry from database
-- Checks existence before deletion, cleans up related data, and returns success/failure status
-- Provides comprehensive logging for deletion attempts and results
function Database:DeleteEntry(playerName, serverName, wowVersion)
    if SLH.Debug then
        SLH.Debug:LogDebug("Database", "DeleteEntry() called", {
            playerName = playerName,
            serverName = serverName,
            wowVersion = wowVersion
        })
    end
    
    -- Wrap entry deletion in error handling
    local success, result, deletedEntry = SafeExecute(function()
        return Database:_DeleteEntryInternal(playerName, serverName, wowVersion)
    end, "DeleteEntry")
    
    if not success then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Entry deletion failed", {
                playerName = playerName,
                serverName = serverName,
                wowVersion = wowVersion,
                error = result
            })
        end
        return false, result
    end
    
    return result, deletedEntry
end

-- Internal entry deletion logic (separated for error handling)
function Database:_DeleteEntryInternal(playerName, serverName, wowVersion)
    
    -- Generate key for deletion
    local key = self:GenerateKey(playerName, serverName, wowVersion)
    if not key then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Failed to generate key for entry deletion", {
                playerName = playerName,
                serverName = serverName,
                wowVersion = wowVersion
            })
        end
        return false, "Failed to generate player key"
    end
    
    -- Check if database structures exist
    if not SpectrumLootHelperDB then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "SpectrumLootHelperDB not available for DeleteEntry", {})
        end
        return false, "Database not initialized"
    end
    
    if not SpectrumLootHelperDB.playerData then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "playerData table not available for DeleteEntry", {})
        end
        return false, "Player data table not initialized"
    end
    
    -- Check if entry exists before deletion
    local existingEntry = SpectrumLootHelperDB.playerData[key]
    if not existingEntry then
        if SLH.Debug then
            SLH.Debug:LogWarn("Database", "Entry not found for deletion", {
                key = key,
                playerName = playerName,
                serverName = serverName,
                wowVersion = wowVersion,
                found = false
            })
        end
        return false, "Entry not found - cannot delete non-existent entry"
    end
    
    -- Create a backup copy of entry before deletion for logging and potential recovery
    local deletedEntryBackup = {}
    if type(existingEntry) == "table" then
        for field, value in pairs(existingEntry) do
            if type(value) == "table" then
                -- Deep copy tables (like Equipment)
                deletedEntryBackup[field] = {}
                for k, v in pairs(value) do
                    deletedEntryBackup[field][k] = v
                end
            else
                deletedEntryBackup[field] = value
            end
        end
    end
    
    -- Count total entries before deletion for logging
    local totalEntriesBefore = 0
    for _ in pairs(SpectrumLootHelperDB.playerData) do
        totalEntriesBefore = totalEntriesBefore + 1
    end
    
    -- Remove entry from database (clean up related data)
    SpectrumLootHelperDB.playerData[key] = nil
    
    -- Verify deletion was successful
    if SpectrumLootHelperDB.playerData[key] ~= nil then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Entry deletion verification failed", {
                key = key,
                entryStillExists = true
            })
        end
        return false, "Entry deletion failed - entry still exists after removal"
    end
    
    -- Count total entries after deletion for logging
    local totalEntriesAfter = 0
    for _ in pairs(SpectrumLootHelperDB.playerData) do
        totalEntriesAfter = totalEntriesAfter + 1
    end
    
    -- Log successful deletion with comprehensive details
    if SLH.Debug then
        SLH.Debug:LogInfo("Database", "Successfully deleted entry from database", {
            key = key,
            playerName = playerName,
            serverName = serverName,
            wowVersion = wowVersion,
            deletedEntry = {
                hadVenariiCharges = deletedEntryBackup.VenariiCharges ~= nil,
                hadEquipment = deletedEntryBackup.Equipment ~= nil,
                hadLastUpdate = deletedEntryBackup.LastUpdate ~= nil,
                venariiCharges = deletedEntryBackup.VenariiCharges,
                lastUpdate = deletedEntryBackup.LastUpdate
            },
            databaseStats = {
                entriesBeforeDeletion = totalEntriesBefore,
                entriesAfterDeletion = totalEntriesAfter,
                entriesRemoved = totalEntriesBefore - totalEntriesAfter
            },
            deletionSuccessful = true
        })
    end
    
    -- Additional cleanup: Check for any related data that might need cleanup
    -- Note: Currently, entries are self-contained, but this is where we would
    -- clean up any cross-references or related data in the future
    
    -- Return success/failure status with deleted entry data
    return true, deletedEntryBackup
end

-- Get all entries for current WoW version
-- Filters database entries by current WoW version and returns matching entries
-- Provides comprehensive logging and statistics for version-specific queries
function Database:GetCurrentVersionEntries()
    if SLH.Debug then
        SLH.Debug:LogDebug("Database", "GetCurrentVersionEntries() called", {})
    end
    
    -- Wrap version entries retrieval in error handling
    local success, result = SafeExecute(function()
        return Database:_GetCurrentVersionEntriesInternal()
    end, "GetCurrentVersionEntries")
    
    if not success then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Current version entries retrieval failed", {
                error = result
            })
        end
        return nil
    end
    
    return result
end

-- Internal current version entries logic (separated for error handling)
function Database:_GetCurrentVersionEntriesInternal()
    
    -- Get current WoW version
    local wowVersion, buildNumber, buildDate, gameVersion = GetBuildInfo()
    if not wowVersion or wowVersion == "" then
        if SLH.Debug then
            SLH.Debug:LogWarn("Database", "WoW version not available for version filtering", {
                wowVersion = wowVersion,
                loading = true
            })
        end
        return nil
    end
    
    -- Extract major.minor version format (same as GenerateKey does)
    local majorMinor = wowVersion:match("^(%d+%.%d+)")
    if not majorMinor then
        if SLH.Debug then
            SLH.Debug:LogWarn("Database", "Could not extract major.minor version", {
                wowVersion = wowVersion,
                pattern = "^(%d+%.%d+)"
            })
        end
        return nil
    end
    
    -- Check if database structures exist
    if not SpectrumLootHelperDB then
        if SLH.Debug then
            SLH.Debug:LogWarn("Database", "SpectrumLootHelperDB not available for version filtering", {})
        end
        return {}
    end
    
    if not SpectrumLootHelperDB.playerData then
        if SLH.Debug then
            SLH.Debug:LogWarn("Database", "playerData table not available for version filtering", {})
        end
        return {}
    end
    
    -- Filter database entries by current version
    local matchingEntries = {}
    local totalEntries = 0
    local matchingCount = 0
    local versionCounts = {}
    
    for key, entry in pairs(SpectrumLootHelperDB.playerData) do
        totalEntries = totalEntries + 1
        
        -- Extract version from key (format: "PlayerName-ServerName-Version")
        local keyVersion = key:match("%-([^%-]+)$") -- Get everything after the last dash
        
        if keyVersion then
            -- Count versions for statistics
            versionCounts[keyVersion] = (versionCounts[keyVersion] or 0) + 1
            
            -- Check if this entry matches current version
            if keyVersion == majorMinor then
                matchingEntries[key] = entry
                matchingCount = matchingCount + 1
                
                if SLH.Debug then
                    SLH.Debug:LogDebug("Database", "Found matching version entry", {
                        key = key,
                        version = keyVersion,
                        currentVersion = majorMinor
                    })
                end
            end
        else
            if SLH.Debug then
                SLH.Debug:LogWarn("Database", "Could not extract version from key", {
                    key = key,
                    pattern = "%-([^%-]+)$"
                })
            end
        end
    end
    
    -- Prepare version statistics for logging
    local versionStats = {}
    for version, count in pairs(versionCounts) do
        table.insert(versionStats, version .. ":" .. count)
    end
    
    -- Log number of entries found with comprehensive statistics
    if SLH.Debug then
        SLH.Debug:LogInfo("Database", "Current version entries retrieval completed", {
            currentWoWVersion = wowVersion,
            filteredVersion = majorMinor,
            totalEntriesInDatabase = totalEntries,
            matchingEntriesFound = matchingCount,
            versionBreakdown = versionStats,
            buildNumber = buildNumber,
            gameVersion = gameVersion,
            success = true
        })
    end
    
    -- Return table of matching entries
    return matchingEntries
end

-- ============================================================================
-- VALIDATION
-- ============================================================================

-- Validate VenariiCharges value
-- Ensures charges is a non-negative integer value
-- Returns validation result with error details
function Database:ValidateVenariiCharges(charges)
    if SLH.Debug then
        SLH.Debug:LogDebug("Database", "ValidateVenariiCharges() called", {
            charges = charges,
            chargesType = type(charges)
        })
    end
    
    -- Wrap validation in error handling
    local success, isValid, errorMsg = SafeExecute(function()
        return Database:_ValidateVenariiChargesInternal(charges)
    end, "ValidateVenariiCharges")
    
    if not success then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "VenariiCharges validation error", {
                charges = charges,
                error = isValid -- This contains the error message when success is false
            })
        end
        return false, "Validation error: " .. tostring(isValid)
    end
    
    return isValid, errorMsg
end

-- Internal VenariiCharges validation logic (separated for error handling)
function Database:_ValidateVenariiChargesInternal(charges)
    
    -- Check if charges is a number
    if type(charges) ~= "number" then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "VenariiCharges validation failed - not a number", {
                charges = charges,
                actualType = type(charges),
                expectedType = "number"
            })
        end
        return false, "VenariiCharges must be a number"
    end
    
    -- Ensure charges >= 0
    if charges < 0 then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "VenariiCharges validation failed - negative value", {
                charges = charges,
                minimum = 0
            })
        end
        return false, "VenariiCharges must be non-negative"
    end
    
    -- Check if charges is an integer (not a decimal)
    if charges ~= math.floor(charges) then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "VenariiCharges validation failed - not an integer", {
                charges = charges,
                floor = math.floor(charges)
            })
        end
        return false, "VenariiCharges must be an integer"
    end
    
    -- Log successful validation
    if SLH.Debug then
        SLH.Debug:LogInfo("Database", "VenariiCharges validation successful", {
            charges = charges,
            isValid = true
        })
    end
    
    -- Return validation success
    return true, nil
end

-- Validate equipment slot data
-- Checks all 16 equipment slots are booleans and required slots exist
-- Returns validation result with error details
function Database:ValidateEquipment(equipment)
    if SLH.Debug then
        SLH.Debug:LogDebug("Database", "ValidateEquipment() called", {
            hasEquipment = equipment ~= nil,
            equipmentType = type(equipment)
        })
    end
    
    -- Wrap validation in error handling
    local success, isValid, errorMsg = SafeExecute(function()
        return Database:_ValidateEquipmentInternal(equipment)
    end, "ValidateEquipment")
    
    if not success then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Equipment validation error", {
                equipment = equipment,
                error = isValid -- This contains the error message when success is false
            })
        end
        return false, "Validation error: " .. tostring(isValid)
    end
    
    return isValid, errorMsg
end

-- Internal equipment validation logic (separated for error handling)
function Database:_ValidateEquipmentInternal(equipment)
    
    -- Check if equipment is a table
    if type(equipment) ~= "table" then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Equipment validation failed - not a table", {
                equipment = equipment,
                actualType = type(equipment),
                expectedType = "table"
            })
        end
        return false, "Equipment must be a table"
    end
    
    -- Validate all required slots exist and are booleans
    local missingSlots = {}
    local invalidSlots = {}
    
    for i, slotName in ipairs(Database.EQUIPMENT_SLOTS) do
        if equipment[slotName] == nil then
            table.insert(missingSlots, slotName)
        elseif type(equipment[slotName]) ~= "boolean" then
            table.insert(invalidSlots, {
                slot = slotName,
                value = equipment[slotName],
                type = type(equipment[slotName])
            })
        end
    end
    
    -- Check for missing slots
    if #missingSlots > 0 then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Equipment validation failed - missing slots", {
                missingSlots = missingSlots,
                missingCount = #missingSlots,
                totalRequired = #Database.EQUIPMENT_SLOTS
            })
        end
        return false, "Missing required equipment slots: " .. table.concat(missingSlots, ", ")
    end
    
    -- Check for invalid slot values (non-booleans)
    if #invalidSlots > 0 then
        local invalidSlotNames = {}
        for _, slotInfo in ipairs(invalidSlots) do
            table.insert(invalidSlotNames, slotInfo.slot)
        end
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Equipment validation failed - invalid slot values", {
                invalidSlots = invalidSlots,
                invalidCount = #invalidSlots
            })
        end
        return false, "Equipment slots must be boolean values. Invalid slots: " .. table.concat(invalidSlotNames, ", ")
    end
    
    -- Check for unknown/extra slots
    local extraSlots = {}
    for slotName, _ in pairs(equipment) do
        local found = false
        for _, validSlot in ipairs(Database.EQUIPMENT_SLOTS) do
            if slotName == validSlot then
                found = true
                break
            end
        end
        if not found then
            table.insert(extraSlots, slotName)
        end
    end
    
    if #extraSlots > 0 then
        if SLH.Debug then
            SLH.Debug:LogWarn("Database", "Equipment validation warning - extra slots found", {
                extraSlots = extraSlots,
                extraCount = #extraSlots
            })
        end
        -- Note: We don't fail validation for extra slots, just warn
    end
    
    -- Log successful validation
    if SLH.Debug then
        SLH.Debug:LogInfo("Database", "Equipment validation successful", {
            totalSlots = #Database.EQUIPMENT_SLOTS,
            validSlots = #Database.EQUIPMENT_SLOTS,
            extraSlots = #extraSlots,
            isValid = true
        })
    end
    
    -- Return validation success
    return true, nil
end

-- Validate complete database entry
-- Uses ValidateVenariiCharges() and ValidateEquipment() to check entry structure matches schema
-- Returns comprehensive validation result with error details
function Database:ValidateEntry(entry)
    if SLH.Debug then
        SLH.Debug:LogDebug("Database", "ValidateEntry() called", {
            hasEntry = entry ~= nil,
            entryType = type(entry)
        })
    end
    
    -- Wrap validation in error handling
    local success, isValid, errorMsg = SafeExecute(function()
        return Database:_ValidateEntryInternal(entry)
    end, "ValidateEntry")
    
    if not success then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Entry validation error", {
                entry = entry,
                error = isValid -- This contains the error message when success is false
            })
        end
        return false, "Validation error: " .. tostring(isValid)
    end
    
    return isValid, errorMsg
end

-- Internal entry validation logic (separated for error handling)
function Database:_ValidateEntryInternal(entry)
    
    -- Check entry structure matches schema - must be a table
    if type(entry) ~= "table" then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Entry validation failed - not a table", {
                entry = entry,
                actualType = type(entry),
                expectedType = "table"
            })
        end
        return false, "Entry must be a table"
    end
    
    -- Validate LastUpdate is a timestamp (number)
    if entry.LastUpdate == nil then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Entry validation failed - missing LastUpdate", {
                hasLastUpdate = false
            })
        end
        return false, "Entry must have LastUpdate field"
    end
    
    if type(entry.LastUpdate) ~= "number" then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Entry validation failed - invalid LastUpdate type", {
                lastUpdate = entry.LastUpdate,
                actualType = type(entry.LastUpdate),
                expectedType = "number"
            })
        end
        return false, "LastUpdate must be a number (timestamp)"
    end
    
    -- Validate VenariiCharges using ValidateVenariiCharges()
    if entry.VenariiCharges == nil then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Entry validation failed - missing VenariiCharges", {
                hasVenariiCharges = false
            })
        end
        return false, "Entry must have VenariiCharges field"
    end
    
    local chargesValid, chargesError = self:ValidateVenariiCharges(entry.VenariiCharges)
    if not chargesValid then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Entry validation failed - invalid VenariiCharges", {
                venariiCharges = entry.VenariiCharges,
                error = chargesError
            })
        end
        return false, "VenariiCharges validation failed: " .. (chargesError or "unknown error")
    end
    
    -- Validate Equipment using ValidateEquipment()
    if entry.Equipment == nil then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Entry validation failed - missing Equipment", {
                hasEquipment = false
            })
        end
        return false, "Entry must have Equipment field"
    end
    
    local equipmentValid, equipmentError = self:ValidateEquipment(entry.Equipment)
    if not equipmentValid then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Entry validation failed - invalid Equipment", {
                equipment = entry.Equipment,
                error = equipmentError
            })
        end
        return false, "Equipment validation failed: " .. (equipmentError or "unknown error")
    end
    
    -- Check for unexpected fields (warn but don't fail)
    local expectedFields = { "LastUpdate", "VenariiCharges", "Equipment" }
    local unexpectedFields = {}
    
    for fieldName, _ in pairs(entry) do
        local found = false
        for _, expectedField in ipairs(expectedFields) do
            if fieldName == expectedField then
                found = true
                break
            end
        end
        if not found then
            table.insert(unexpectedFields, fieldName)
        end
    end
    
    if #unexpectedFields > 0 then
        if SLH.Debug then
            SLH.Debug:LogWarn("Database", "Entry validation warning - unexpected fields found", {
                unexpectedFields = unexpectedFields,
                unexpectedCount = #unexpectedFields
            })
        end
        -- Note: We don't fail validation for unexpected fields, just warn
    end
    
    -- Log successful validation
    if SLH.Debug then
        SLH.Debug:LogInfo("Database", "Entry validation successful", {
            hasLastUpdate = entry.LastUpdate ~= nil,
            hasVenariiCharges = entry.VenariiCharges ~= nil,
            hasEquipment = entry.Equipment ~= nil,
            unexpectedFields = #unexpectedFields,
            isValid = true
        })
    end
    
    -- Return comprehensive validation success
    return true, nil
end

-- ============================================================================
-- UPGRADE / MIGRATION
-- ============================================================================

-- TODO: Handle database schema upgrades
function Database:UpgradeSchema(fromVersion, toVersion)
    if SLH.Debug then
        SLH.Debug:LogDebug("Database", "UpgradeSchema() called", {
            fromVersion = fromVersion,
            toVersion = toVersion
        })
    end
    
    -- TODO: Check if upgrade is needed
    -- TODO: Backup existing data before upgrade
    -- TODO: Apply schema changes based on version differences
    -- TODO: Migrate existing entries to new schema
    -- TODO: Update database version marker
    -- TODO: Log successful upgrade completion
end

-- TODO: Migrate data between WoW versions
function Database:MigrateToNewWoWVersion(oldVersion, newVersion)
    if SLH.Debug then
        SLH.Debug:LogDebug("Database", "MigrateToNewWoWVersion() called", {
            oldVersion = oldVersion,
            newVersion = newVersion
        })
    end
    
    -- TODO: Preserve old version data for historical tracking
    -- TODO: Reset VenariiCharges to 0 for new version
    -- TODO: Reset all equipment slots to false for new version
    -- TODO: Create new entries with new version keys
    -- TODO: Log migration completion with entry counts
end

-- ============================================================================
-- DEBUGGING / LOGGING
-- ============================================================================

-- TODO: Get database statistics for debugging
function Database:GetDebugStats()
    if SLH.Debug then
        SLH.Debug:LogDebug("Database", "GetDebugStats() called", {})
    end
    
    -- TODO: Count total entries in database
    -- TODO: Count entries by WoW version
    -- TODO: Calculate memory usage
    -- TODO: Check for data integrity issues
    -- TODO: Return comprehensive stats table
end

-- TODO: Export database for debugging/support
function Database:ExportForDebug()
    if SLH.Debug then
        SLH.Debug:LogDebug("Database", "ExportForDebug() called", {})
    end
    
    -- TODO: Create sanitized copy of database
    -- TODO: Remove sensitive information if any
    -- TODO: Format for easy reading/analysis
    -- TODO: Return exportable data structure
end

-- TODO: Validate database integrity
function Database:ValidateIntegrity()
    if SLH.Debug then
        SLH.Debug:LogDebug("Database", "ValidateIntegrity() called", {})
    end
    
    -- TODO: Check all entries against schema
    -- TODO: Verify no corrupted or invalid data
    -- TODO: Check for orphaned or duplicate entries
    -- TODO: Report any integrity issues found
    -- TODO: Return integrity status and issue list
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- TODO: Clear all data for testing purposes
function Database:ClearAllData()
    if SLH.Debug then
        SLH.Debug:LogDebug("Database", "ClearAllData() called", {})
    end
    
    -- TODO: Confirm this is for testing/debugging only
    -- TODO: Clear SpectrumLootHelperDB.playerData
    -- TODO: Reset database to initial state
    -- TODO: Log data clearing action
end

-- TODO: Get database size information
function Database:GetSize()
    if SLH.Debug then
        SLH.Debug:LogDebug("Database", "GetSize() called", {})
    end
    
    -- TODO: Calculate memory usage of saved variables
    -- TODO: Count number of entries
    -- TODO: Return size information for monitoring
end

-- ============================================================================
-- MODULE INITIALIZATION
-- ============================================================================

-- Register event handlers if needed for database management
local function OnAddonLoaded(event, addonName)
    if addonName == ADDON_NAME then
        if SLH.Debug then
            SLH.Debug:LogInfo("Database", "Database module loaded", {
                version = Database.DB_VERSION,
                slotsCount = #Database.EQUIPMENT_SLOTS
            })
        end
    end
end

-- Create event frame and register events for database initialization
local DatabaseEventFrame = CreateFrame("Frame")
DatabaseEventFrame:RegisterEvent("ADDON_LOADED")
DatabaseEventFrame:SetScript("OnEvent", OnAddonLoaded)

-- Log that event frame has been set up
if SLH.Debug then
    SLH.Debug:LogDebug("Database", "Event frame registered", {
        events = {"ADDON_LOADED"}
    })
end
