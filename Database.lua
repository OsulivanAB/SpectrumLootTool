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
    
    -- Check for schema upgrades needed (Task 19)
    local currentSchemaVersion = SpectrumLootHelperDB.databaseVersion
    if currentSchemaVersion and currentSchemaVersion ~= Database.DB_VERSION then
        if SLH.Debug then
            SLH.Debug:LogInfo("Database", "Schema upgrade needed", {
                currentVersion = currentSchemaVersion,
                targetVersion = Database.DB_VERSION
            })
        end
        
        -- Perform automatic schema upgrade
        local upgradeSuccess, upgradeMessage, upgradeStats = self:UpgradeSchema(currentSchemaVersion, Database.DB_VERSION)
        if upgradeSuccess then
            if SLH.Debug then
                SLH.Debug:LogInfo("Database", "Automatic schema upgrade completed", {
                    fromVersion = currentSchemaVersion,
                    toVersion = Database.DB_VERSION,
                    message = upgradeMessage,
                    statistics = upgradeStats
                })
            end
        else
            if SLH.Debug then
                SLH.Debug:LogError("Database", "Automatic schema upgrade failed", {
                    fromVersion = currentSchemaVersion,
                    toVersion = Database.DB_VERSION,
                    error = upgradeMessage
                })
            end
            -- Continue with initialization even if upgrade fails
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
            persistenceValidated = SpectrumLootHelperDB.lastDatabaseAccess ~= nil,
            schemaVersion = SpectrumLootHelperDB.databaseVersion,
            schemaUpToDate = SpectrumLootHelperDB.databaseVersion == Database.DB_VERSION
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

-- Handle database schema upgrades
-- Upgrades database schema from one version to another with data preservation
-- Supports version-specific migration rules and comprehensive backup/rollback
function Database:UpgradeSchema(fromVersion, toVersion)
    return self:SafeExecute("UpgradeSchema", function()
        
        if SLH.Debug then
            SLH.Debug:LogDebug("Database", "UpgradeSchema() starting schema upgrade", {
                fromVersion = fromVersion,
                toVersion = toVersion,
                operation = "schema_upgrade"
            })
        end
        
        -- Validate input parameters
        if not fromVersion or type(fromVersion) ~= "string" or fromVersion == "" then
            local errorMsg = "Invalid fromVersion parameter"
            if SLH.Debug then
                SLH.Debug:LogError("Database", errorMsg, {
                    fromVersion = fromVersion,
                    type = type(fromVersion)
                })
            end
            return false, errorMsg
        end
        
        if not toVersion or type(toVersion) ~= "string" or toVersion == "" then
            local errorMsg = "Invalid toVersion parameter"
            if SLH.Debug then
                SLH.Debug:LogError("Database", errorMsg, {
                    toVersion = toVersion,
                    type = type(toVersion)
                })
            end
            return false, errorMsg
        end
        
        -- Check if upgrade is needed
        if fromVersion == toVersion then
            if SLH.Debug then
                SLH.Debug:LogInfo("Database", "No schema upgrade needed - versions match", {
                    currentVersion = fromVersion,
                    targetVersion = toVersion
                })
            end
            return true, "No upgrade needed - schema is already at target version"
        end
        
        -- Ensure database is initialized
        if not SpectrumLootHelperDB or not SpectrumLootHelperDB.playerData then
            if SLH.Debug then
                SLH.Debug:LogWarn("Database", "Database not initialized for schema upgrade", {
                    fromVersion = fromVersion,
                    toVersion = toVersion
                })
            end
            -- Initialize database with new version
            if not SpectrumLootHelperDB then
                SpectrumLootHelperDB = {}
            end
            if not SpectrumLootHelperDB.playerData then
                SpectrumLootHelperDB.playerData = {}
            end
            SpectrumLootHelperDB.databaseVersion = toVersion
            return true, "Database initialized with new schema version"
        end
        
        -- Check version compatibility
        local upgradeSupported, compatibilityError = self:_CheckVersionCompatibility(fromVersion, toVersion)
        if not upgradeSupported then
            if SLH.Debug then
                SLH.Debug:LogError("Database", "Schema upgrade not supported", {
                    fromVersion = fromVersion,
                    toVersion = toVersion,
                    error = compatibilityError
                })
            end
            return false, "Schema upgrade not supported: " .. (compatibilityError or "unknown compatibility error")
        end
        
        -- Backup existing data before upgrade
        local backupSuccess, backupData = self:_BackupDatabaseForUpgrade()
        if not backupSuccess then
            if SLH.Debug then
                SLH.Debug:LogError("Database", "Failed to backup database for schema upgrade", {
                    error = backupData
                })
            end
            return false, "Failed to backup database: " .. (backupData or "unknown backup error")
        end
        
        -- Collect upgrade statistics
        local upgradeStats = {
            fromVersion = fromVersion,
            toVersion = toVersion,
            totalEntries = 0,
            upgradedEntries = 0,
            failedUpgrades = 0,
            schemaChangesApplied = 0,
            backupCreated = true,
            startTime = GetServerTime()
        }
        
        -- Count entries before upgrade
        for _ in pairs(SpectrumLootHelperDB.playerData) do
            upgradeStats.totalEntries = upgradeStats.totalEntries + 1
        end
        
        -- Apply schema changes based on version differences
        local upgradeSuccess, upgradeError = self:_ApplySchemaUpgrade(fromVersion, toVersion, upgradeStats)
        if not upgradeSuccess then
            -- Attempt rollback on upgrade failure
            if SLH.Debug then
                SLH.Debug:LogError("Database", "Schema upgrade failed - attempting rollback", {
                    error = upgradeError,
                    fromVersion = fromVersion,
                    toVersion = toVersion
                })
            end
            
            local rollbackSuccess = self:_RollbackSchemaUpgrade(backupData)
            if rollbackSuccess then
                return false, "Schema upgrade failed and was rolled back: " .. (upgradeError or "unknown upgrade error")
            else
                return false, "Schema upgrade failed and rollback failed - database may be corrupted"
            end
        end
        
        -- Migrate existing entries to new schema
        local migrationSuccess, migrationError = self:_MigrateEntriesToNewSchema(fromVersion, toVersion, upgradeStats)
        if not migrationSuccess then
            -- Attempt rollback on migration failure
            if SLH.Debug then
                SLH.Debug:LogError("Database", "Entry migration failed - attempting rollback", {
                    error = migrationError,
                    fromVersion = fromVersion,
                    toVersion = toVersion
                })
            end
            
            local rollbackSuccess = self:_RollbackSchemaUpgrade(backupData)
            if rollbackSuccess then
                return false, "Entry migration failed and was rolled back: " .. (migrationError or "unknown migration error")
            else
                return false, "Entry migration failed and rollback failed - database may be corrupted"
            end
        end
        
        -- Update database version marker
        SpectrumLootHelperDB.databaseVersion = toVersion
        upgradeStats.endTime = GetServerTime()
        upgradeStats.totalDuration = upgradeStats.endTime - upgradeStats.startTime
        
        -- Log successful upgrade completion
        if SLH.Debug then
            SLH.Debug:LogInfo("Database", "Schema upgrade completed successfully", {
                fromVersion = fromVersion,
                toVersion = toVersion,
                statistics = upgradeStats,
                totalEntries = upgradeStats.totalEntries,
                upgradedEntries = upgradeStats.upgradedEntries,
                failedUpgrades = upgradeStats.failedUpgrades,
                schemaChanges = upgradeStats.schemaChangesApplied,
                duration = upgradeStats.totalDuration,
                operation = "schema_upgrade_complete"
            })
        end
        
        -- Return success with detailed upgrade report
        local message = string.format(
            "Schema upgrade completed: %d entries migrated from %s to %s (%d changes applied, %d failed)",
            upgradeStats.upgradedEntries,
            fromVersion,
            toVersion,
            upgradeStats.schemaChangesApplied,
            upgradeStats.failedUpgrades
        )
        
        return true, message, upgradeStats
        
    end)
end

-- Internal helper: Check version compatibility for schema upgrades
function Database:_CheckVersionCompatibility(fromVersion, toVersion)
    
    -- Define supported upgrade paths
    local supportedUpgrades = {
        ["1.0.0"] = {"1.1.0", "1.2.0"}, -- 1.0.0 can upgrade to 1.1.0 or 1.2.0
        ["1.1.0"] = {"1.2.0", "1.3.0"}, -- 1.1.0 can upgrade to 1.2.0 or 1.3.0
        ["1.2.0"] = {"1.3.0", "2.0.0"}  -- 1.2.0 can upgrade to 1.3.0 or 2.0.0
    }
    
    -- Check if fromVersion is supported
    if not supportedUpgrades[fromVersion] then
        return false, "Unsupported source version: " .. fromVersion
    end
    
    -- Check if upgrade path exists
    local pathExists = false
    for _, supportedTarget in ipairs(supportedUpgrades[fromVersion]) do
        if supportedTarget == toVersion then
            pathExists = true
            break
        end
    end
    
    if not pathExists then
        return false, "No upgrade path from " .. fromVersion .. " to " .. toVersion
    end
    
    if SLH.Debug then
        SLH.Debug:LogInfo("Database", "Version compatibility check passed", {
            fromVersion = fromVersion,
            toVersion = toVersion,
            upgradePathValid = true
        })
    end
    
    return true
end

-- Internal helper: Backup database for upgrade safety
function Database:_BackupDatabaseForUpgrade()
    
    if SLH.Debug then
        SLH.Debug:LogDebug("Database", "Creating database backup for schema upgrade", {})
    end
    
    -- Create deep copy of database
    local backup = {
        playerData = {},
        databaseVersion = SpectrumLootHelperDB.databaseVersion,
        lastDatabaseAccess = SpectrumLootHelperDB.lastDatabaseAccess,
        backupTimestamp = GetServerTime()
    }
    
    -- Deep copy all player data
    for playerKey, playerData in pairs(SpectrumLootHelperDB.playerData) do
        if type(playerData) == "table" then
            backup.playerData[playerKey] = {}
            for field, value in pairs(playerData) do
                if type(value) == "table" then
                    -- Deep copy tables (like Equipment)
                    backup.playerData[playerKey][field] = {}
                    for k, v in pairs(value) do
                        backup.playerData[playerKey][field][k] = v
                    end
                else
                    backup.playerData[playerKey][field] = value
                end
            end
        else
            backup.playerData[playerKey] = playerData
        end
    end
    
    if SLH.Debug then
        SLH.Debug:LogInfo("Database", "Database backup created successfully", {
            entriesBackedUp = self:_CountTableEntries(backup.playerData),
            backupSize = self:_EstimateTableSize(backup),
            backupTimestamp = backup.backupTimestamp
        })
    end
    
    return true, backup
end

-- Internal helper: Apply schema changes during upgrade
function Database:_ApplySchemaUpgrade(fromVersion, toVersion, upgradeStats)
    
    if SLH.Debug then
        SLH.Debug:LogDebug("Database", "Applying schema changes for upgrade", {
            fromVersion = fromVersion,
            toVersion = toVersion
        })
    end
    
    -- Apply version-specific schema changes
    if fromVersion == "1.0.0" and toVersion == "1.1.0" then
        -- Example: Add new field to database structure
        if not SpectrumLootHelperDB.schemaUpgradeHistory then
            SpectrumLootHelperDB.schemaUpgradeHistory = {}
            upgradeStats.schemaChangesApplied = upgradeStats.schemaChangesApplied + 1
        end
        
    elseif fromVersion == "1.1.0" and toVersion == "1.2.0" then
        -- Example: Add integrity checking metadata
        if not SpectrumLootHelperDB.integrityMetadata then
            SpectrumLootHelperDB.integrityMetadata = {
                lastIntegrityCheck = nil,
                integrityScore = nil
            }
            upgradeStats.schemaChangesApplied = upgradeStats.schemaChangesApplied + 1
        end
        
    elseif fromVersion == "1.2.0" and toVersion == "2.0.0" then
        -- Example: Major version upgrade - restructure data
        if not SpectrumLootHelperDB.v2Features then
            SpectrumLootHelperDB.v2Features = {
                enhancedStatistics = true,
                improvedMigration = true
            }
            upgradeStats.schemaChangesApplied = upgradeStats.schemaChangesApplied + 1
        end
    end
    
    -- Record upgrade in history
    if not SpectrumLootHelperDB.schemaUpgradeHistory then
        SpectrumLootHelperDB.schemaUpgradeHistory = {}
    end
    
    table.insert(SpectrumLootHelperDB.schemaUpgradeHistory, {
        fromVersion = fromVersion,
        toVersion = toVersion,
        timestamp = GetServerTime(),
        appliedChanges = upgradeStats.schemaChangesApplied
    })
    
    if SLH.Debug then
        SLH.Debug:LogInfo("Database", "Schema changes applied successfully", {
            fromVersion = fromVersion,
            toVersion = toVersion,
            changesApplied = upgradeStats.schemaChangesApplied
        })
    end
    
    return true
end

-- Internal helper: Migrate entries to new schema format
function Database:_MigrateEntriesToNewSchema(fromVersion, toVersion, upgradeStats)
    
    if SLH.Debug then
        SLH.Debug:LogDebug("Database", "Migrating entries to new schema", {
            fromVersion = fromVersion,
            toVersion = toVersion,
            totalEntries = upgradeStats.totalEntries
        })
    end
    
    for playerKey, playerData in pairs(SpectrumLootHelperDB.playerData) do
        
        if type(playerData) == "table" then
            local entryMigrated = false
            
            -- Apply version-specific entry migrations
            if fromVersion == "1.0.0" and toVersion == "1.1.0" then
                -- Example: Add tracking fields to entries
                if not playerData.SchemaVersion then
                    playerData.SchemaVersion = toVersion
                    entryMigrated = true
                end
                
            elseif fromVersion == "1.1.0" and toVersion == "1.2.0" then
                -- Example: Add integrity metadata to entries
                if not playerData.IntegrityMetadata then
                    playerData.IntegrityMetadata = {
                        lastValidated = GetServerTime(),
                        validationsPassed = 0
                    }
                    entryMigrated = true
                end
                
            elseif fromVersion == "1.2.0" and toVersion == "2.0.0" then
                -- Example: Major restructuring for v2
                if not playerData.V2Structure then
                    playerData.V2Structure = {
                        migrationTimestamp = GetServerTime(),
                        preservedFromV1 = true
                    }
                    entryMigrated = true
                end
            end
            
            -- Update entry schema version
            playerData.SchemaVersion = toVersion
            
            if entryMigrated then
                upgradeStats.upgradedEntries = upgradeStats.upgradedEntries + 1
                
                if SLH.Debug then
                    SLH.Debug:LogDebug("Database", "Entry migrated to new schema", {
                        playerKey = playerKey,
                        fromVersion = fromVersion,
                        toVersion = toVersion
                    })
                end
            end
            
        else
            upgradeStats.failedUpgrades = upgradeStats.failedUpgrades + 1
            if SLH.Debug then
                SLH.Debug:LogWarn("Database", "Failed to migrate corrupted entry", {
                    playerKey = playerKey,
                    entryType = type(playerData)
                })
            end
        end
    end
    
    if SLH.Debug then
        SLH.Debug:LogInfo("Database", "Entry migration completed", {
            fromVersion = fromVersion,
            toVersion = toVersion,
            totalEntries = upgradeStats.totalEntries,
            upgradedEntries = upgradeStats.upgradedEntries,
            failedUpgrades = upgradeStats.failedUpgrades
        })
    end
    
    return true
end

-- Internal helper: Rollback schema upgrade in case of failure
function Database:_RollbackSchemaUpgrade(backupData)
    
    if SLH.Debug then
        SLH.Debug:LogWarn("Database", "Attempting schema upgrade rollback", {
            backupAvailable = backupData ~= nil
        })
    end
    
    if not backupData or type(backupData) ~= "table" then
        if SLH.Debug then
            SLH.Debug:LogError("Database", "Cannot rollback - backup data invalid", {
                backupType = type(backupData)
            })
        end
        return false
    end
    
    -- Restore database from backup
    SpectrumLootHelperDB.playerData = backupData.playerData or {}
    SpectrumLootHelperDB.databaseVersion = backupData.databaseVersion
    SpectrumLootHelperDB.lastDatabaseAccess = backupData.lastDatabaseAccess
    
    -- Remove failed upgrade from history if it exists
    if SpectrumLootHelperDB.schemaUpgradeHistory then
        -- Remove the last entry (failed upgrade)
        if #SpectrumLootHelperDB.schemaUpgradeHistory > 0 then
            table.remove(SpectrumLootHelperDB.schemaUpgradeHistory)
        end
    end
    
    if SLH.Debug then
        SLH.Debug:LogInfo("Database", "Schema upgrade rollback completed", {
            restoredEntries = self:_CountTableEntries(SpectrumLootHelperDB.playerData),
            restoredVersion = SpectrumLootHelperDB.databaseVersion
        })
    end
    
    return true
end

-- Internal helper: Count entries in a table
function Database:_CountTableEntries(table)
    if not table or type(table) ~= "table" then
        return 0
    end
    
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    return count
end

-- Internal helper: Estimate table memory size
function Database:_EstimateTableSize(table)
    if not table or type(table) ~= "table" then
        return 0
    end
    
    local size = 0
    for k, v in pairs(table) do
        size = size + #tostring(k) + #tostring(v)
        if type(v) == "table" then
            size = size + self:_EstimateTableSize(v)
        end
    end
    return size
end

-- Migrate data between WoW versions
function Database:MigrateToNewWoWVersion(oldVersion, newVersion)
    return self:SafeExecute("MigrateToNewWoWVersion", function()
        
        if SLH.Debug then
            SLH.Debug:LogDebug("Database", "MigrateToNewWoWVersion() starting migration", {
                oldVersion = oldVersion,
                newVersion = newVersion,
                operation = "version_migration"
            })
        end
        
        -- Validate input parameters
        if not oldVersion or type(oldVersion) ~= "string" or oldVersion == "" then
            local errorMsg = "Invalid oldVersion parameter"
            if SLH.Debug then
                SLH.Debug:LogError("Database", errorMsg, {
                    oldVersion = oldVersion,
                    type = type(oldVersion)
                })
            end
            return false, errorMsg
        end
        
        if not newVersion or type(newVersion) ~= "string" or newVersion == "" then
            local errorMsg = "Invalid newVersion parameter"
            if SLH.Debug then
                SLH.Debug:LogError("Database", errorMsg, {
                    newVersion = newVersion,
                    type = type(newVersion)
                })
            end
            return false, errorMsg
        end
        
        -- Ensure database is initialized
        if not SpectrumLootHelperDB or not SpectrumLootHelperDB.playerData then
            if SLH.Debug then
                SLH.Debug:LogWarn("Database", "Database not initialized for migration", {
                    oldVersion = oldVersion,
                    newVersion = newVersion
                })
            end
            return true, "No data to migrate - database not initialized"
        end
        
        -- Collect migration statistics
        local stats = {
            oldVersionEntries = 0,
            newVersionEntries = 0,
            migratedPlayers = 0,
            preservedEntries = 0,
            resetCharges = 0,
            resetEquipment = 0
        }
        
        -- Process each player's data
        for playerKey, playerData in pairs(SpectrumLootHelperDB.playerData) do
            
            if SLH.Debug then
                SLH.Debug:LogDebug("Database", "Processing player for migration", {
                    playerKey = playerKey,
                    oldVersion = oldVersion,
                    newVersion = newVersion
                })
            end
            
            -- Check if this entry belongs to the old version
            if playerKey:find(oldVersion, 1, true) then -- Plain text search
                stats.oldVersionEntries = stats.oldVersionEntries + 1
                
                -- Extract player name and server from old key
                local playerName, serverName = playerKey:match("^(.+)%-(.+)%-%d+%.%d+$")
                if playerName and serverName then
                    
                    -- Generate new version key
                    local newPlayerKey = playerName .. "-" .. serverName .. "-" .. newVersion
                    
                    if SLH.Debug then
                        SLH.Debug:LogDebug("Database", "Creating new version entry", {
                            oldKey = playerKey,
                            newKey = newPlayerKey,
                            playerName = playerName,
                            serverName = serverName,
                            oldVersion = oldVersion,
                            newVersion = newVersion
                        })
                    end
                    
                    -- Create fresh entry for new version with reset values
                    local newEntry = {
                        PlayerName = playerName,
                        ServerName = serverName,
                        WoWVersion = newVersion,
                        VenariiCharges = 0, -- Reset charges for new version
                        Equipment = {
                            [1] = false,   -- Head
                            [2] = false,   -- Neck
                            [3] = false,   -- Shoulder
                            [4] = false,   -- Shirt
                            [5] = false,   -- Chest
                            [6] = false,   -- Waist
                            [7] = false,   -- Legs
                            [8] = false,   -- Feet
                            [9] = false,   -- Wrist
                            [10] = false,  -- Hands
                            [11] = false,  -- Finger1
                            [12] = false,  -- Finger2
                            [13] = false,  -- Trinket1
                            [14] = false,  -- Trinket2
                            [15] = false,  -- Back
                            [16] = false   -- MainHand
                        },
                        LastUpdate = GetServerTime()
                    }
                    
                    -- Store new entry
                    SpectrumLootHelperDB.playerData[newPlayerKey] = newEntry
                    stats.newVersionEntries = stats.newVersionEntries + 1
                    stats.migratedPlayers = stats.migratedPlayers + 1
                    stats.resetCharges = stats.resetCharges + 1
                    stats.resetEquipment = stats.resetEquipment + 16 -- All 16 slots reset
                    
                    -- Preserve old version data (don't delete old entries)
                    stats.preservedEntries = stats.preservedEntries + 1
                    
                    if SLH.Debug then
                        SLH.Debug:LogInfo("Database", "Successfully migrated player to new version", {
                            playerName = playerName,
                            serverName = serverName,
                            oldKey = playerKey,
                            newKey = newPlayerKey,
                            oldVersion = oldVersion,
                            newVersion = newVersion
                        })
                    end
                    
                else
                    if SLH.Debug then
                        SLH.Debug:LogWarn("Database", "Could not parse player key for migration", {
                            playerKey = playerKey,
                            pattern = "^(.+)%-(.+)%-%d+%.%d+$"
                        })
                    end
                end
            end
        end
        
        -- Log migration completion with comprehensive statistics
        if SLH.Debug then
            SLH.Debug:LogInfo("Database", "Migration completed successfully", {
                oldVersion = oldVersion,
                newVersion = newVersion,
                statistics = stats,
                totalProcessed = stats.oldVersionEntries,
                totalMigrated = stats.newVersionEntries,
                playersAffected = stats.migratedPlayers,
                dataPreserved = stats.preservedEntries,
                operation = "migration_complete"
            })
        end
        
        -- Return success with detailed migration report
        local message = string.format(
            "Migration completed: %d players migrated from %s to %s (%d old entries preserved)",
            stats.migratedPlayers,
            oldVersion,
            newVersion,
            stats.preservedEntries
        )
        
        return true, message, stats
        
    end)
end

-- ============================================================================
-- DEBUGGING / LOGGING
-- ============================================================================

-- Get database statistics for debugging and monitoring
-- Provides comprehensive statistics including entry counts, memory usage, version distribution, and integrity status
-- Returns detailed statistics table for debugging and performance monitoring
function Database:GetDebugStats()
    return self:SafeExecute("GetDebugStats", function()
        
        if SLH.Debug then
            SLH.Debug:LogDebug("Database", "GetDebugStats() starting statistics collection", {
                operation = "debug_statistics"
            })
        end
        
        local startTime = GetServerTime()
        
        -- Initialize comprehensive statistics structure
        local debugStats = {
            timestamp = startTime,
            database = {
                initialized = false,
                totalEntries = 0,
                memoryUsage = 0,
                memoryUsageFormatted = "0 B"
            },
            entries = {
                byVersion = {},
                byPlayer = {},
                byServer = {}
            },
            integrity = {
                valid = 0,
                corrupted = 0,
                orphaned = 0,
                schemaViolations = 0
            },
            performance = {
                collectionTime = 0,
                averageEntrySize = 0,
                largestEntry = 0,
                smallestEntry = math.huge
            },
            schema = {
                version = Database.DB_VERSION,
                equipmentSlots = #Database.EQUIPMENT_SLOTS,
                expectedFields = {"LastUpdate", "VenariiCharges", "Equipment"}
            }
        }
        
        -- Check if database is initialized
        if not SpectrumLootHelperDB or not SpectrumLootHelperDB.playerData then
            if SLH.Debug then
                SLH.Debug:LogInfo("Database", "Database not initialized for statistics", {})
            end
            debugStats.database.initialized = false
            return true, debugStats
        end
        
        debugStats.database.initialized = true
        
        -- Count total entries and analyze each entry
        local totalMemoryUsage = 0
        local entryCount = 0
        
        for playerKey, playerData in pairs(SpectrumLootHelperDB.playerData) do
            entryCount = entryCount + 1
            
            -- Calculate estimated memory usage for this entry
            local entrySize = 0
            
            -- Key size
            entrySize = entrySize + #playerKey
            
            -- Data size estimation
            if type(playerData) == "table" then
                -- Basic fields
                entrySize = entrySize + 8 + 8 + 8  -- LastUpdate (8), VenariiCharges (8), base table (8)
                
                -- Equipment table
                if playerData.Equipment and type(playerData.Equipment) == "table" then
                    entrySize = entrySize + 8 + (#Database.EQUIPMENT_SLOTS * 4)  -- Equipment table + 16 booleans
                end
                
                -- String fields
                if playerData.PlayerName then entrySize = entrySize + #playerData.PlayerName end
                if playerData.ServerName then entrySize = entrySize + #playerData.ServerName end
                if playerData.WoWVersion then entrySize = entrySize + #playerData.WoWVersion end
                
                -- Update size tracking
                debugStats.performance.largestEntry = math.max(debugStats.performance.largestEntry, entrySize)
                debugStats.performance.smallestEntry = math.min(debugStats.performance.smallestEntry, entrySize)
            else
                entrySize = 50 -- Estimate for corrupted entry
            end
            
            totalMemoryUsage = totalMemoryUsage + entrySize
            
            -- Extract version, player, and server information
            local playerName, serverName, wowVersion = playerKey:match("^(.+)%-(.+)%-(%d+%.%d+)$")
            
            if playerName and serverName and wowVersion then
                -- Count by version
                debugStats.entries.byVersion[wowVersion] = (debugStats.entries.byVersion[wowVersion] or 0) + 1
                
                -- Count by player (unique players across versions)
                local playerIdentifier = playerName .. "-" .. serverName
                debugStats.entries.byPlayer[playerIdentifier] = (debugStats.entries.byPlayer[playerIdentifier] or 0) + 1
                
                -- Count by server
                debugStats.entries.byServer[serverName] = (debugStats.entries.byServer[serverName] or 0) + 1
                
                -- Quick integrity check
                if type(playerData) == "table" then
                    local valid, _ = self:ValidateEntry(playerData)
                    if valid then
                        debugStats.integrity.valid = debugStats.integrity.valid + 1
                    else
                        debugStats.integrity.schemaViolations = debugStats.integrity.schemaViolations + 1
                    end
                else
                    debugStats.integrity.corrupted = debugStats.integrity.corrupted + 1
                end
            else
                debugStats.integrity.orphaned = debugStats.integrity.orphaned + 1
            end
        end
        
        -- Update database statistics
        debugStats.database.totalEntries = entryCount
        debugStats.database.memoryUsage = totalMemoryUsage
        debugStats.database.memoryUsageFormatted = self:_FormatMemorySize(totalMemoryUsage)
        
        -- Calculate performance metrics
        if entryCount > 0 then
            debugStats.performance.averageEntrySize = totalMemoryUsage / entryCount
        end
        
        if debugStats.performance.smallestEntry == math.huge then
            debugStats.performance.smallestEntry = 0
        end
        
        -- Calculate collection time
        debugStats.performance.collectionTime = GetServerTime() - startTime
        
        -- Generate summary information
        debugStats.summary = {
            totalPlayers = self:_CountUniqueKeys(debugStats.entries.byPlayer),
            totalServers = self:_CountUniqueKeys(debugStats.entries.byServer),
            totalVersions = self:_CountUniqueKeys(debugStats.entries.byVersion),
            integrityRate = entryCount > 0 and (debugStats.integrity.valid / entryCount) * 100 or 0,
            memoryPerEntry = debugStats.performance.averageEntrySize,
            healthStatus = self:_DetermineHealthStatus(debugStats)
        }
        
        -- Log comprehensive statistics collection results
        if SLH.Debug then
            SLH.Debug:LogInfo("Database", "Debug statistics collection completed", {
                totalEntries = debugStats.database.totalEntries,
                memoryUsage = debugStats.database.memoryUsage,
                validEntries = debugStats.integrity.valid,
                corruptedEntries = debugStats.integrity.corrupted,
                uniquePlayers = debugStats.summary.totalPlayers,
                uniqueServers = debugStats.summary.totalServers,
                wowVersions = debugStats.summary.totalVersions,
                integrityRate = debugStats.summary.integrityRate,
                collectionTime = debugStats.performance.collectionTime,
                healthStatus = debugStats.summary.healthStatus,
                operation = "debug_stats_complete"
            })
        end
        
        return true, debugStats
        
    end)
end

-- Helper function to format memory size in human-readable format
function Database:_FormatMemorySize(bytes)
    if bytes < 1024 then
        return string.format("%d B", bytes)
    elseif bytes < 1024 * 1024 then
        return string.format("%.1f KB", bytes / 1024)
    elseif bytes < 1024 * 1024 * 1024 then
        return string.format("%.1f MB", bytes / (1024 * 1024))
    else
        return string.format("%.1f GB", bytes / (1024 * 1024 * 1024))
    end
end

-- Helper function to count unique keys in a table
function Database:_CountUniqueKeys(table)
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    return count
end

-- Helper function to determine overall database health status
function Database:_DetermineHealthStatus(stats)
    local total = stats.database.totalEntries
    if total == 0 then
        return "EMPTY"
    end
    
    local corruptionRate = (stats.integrity.corrupted + stats.integrity.orphaned) / total * 100
    local integrityRate = stats.integrity.valid / total * 100
    
    if corruptionRate > 10 then
        return "CRITICAL"
    elseif corruptionRate > 5 then
        return "WARNING"
    elseif integrityRate > 95 then
        return "EXCELLENT"
    elseif integrityRate > 90 then
        return "GOOD"
    else
        return "FAIR"
    end
end

-- Export database for debugging and support purposes
-- Creates sanitized, formatted export suitable for sharing with developers
-- Removes sensitive information while preserving diagnostic value
function Database:ExportForDebug()
    return self:SafeExecute("ExportForDebug", function()
        
        if SLH.Debug then
            SLH.Debug:LogDebug("Database", "ExportForDebug() starting database export", {
                operation = "debug_export"
            })
        end
        
        local startTime = GetServerTime()
        
        -- Get comprehensive database statistics first
        local success, debugStats = self:GetDebugStats()
        if not success then
            if SLH.Debug then
                SLH.Debug:LogError("Database", "Failed to get debug stats for export", {})
            end
            debugStats = { database = { initialized = false, totalEntries = 0 } }
        end
        
        -- Initialize export structure
        local exportData = {
            header = {
                title = "SpectrumLootTool Database Debug Export",
                timestamp = GetServerTime(),
                dateString = date("%Y-%m-%d %H:%M:%S", GetServerTime()),
                databaseVersion = Database.DB_VERSION,
                exportVersion = "1.0"
            },
            system = {
                wowVersion = nil,
                buildNumber = nil,
                gameVersion = nil,
                playerName = UnitName("player") or "Unknown",
                realmName = GetRealmName() or "Unknown",
                addonVersion = SLH.version or "unknown"
            },
            statistics = debugStats,
            sanitizedData = {
                totalEntries = 0,
                sampleEntries = {},
                versionDistribution = {},
                serverDistribution = {},
                integrityStatus = {}
            },
            diagnostics = {
                exportDuration = 0,
                sanitizationMethod = "player_name_hash",
                privacyLevel = "SAFE_FOR_SHARING"
            }
        }
        
        -- Get WoW system information
        local wowVersion, buildNumber, buildDate, gameVersion = GetBuildInfo()
        if wowVersion then
            exportData.system.wowVersion = wowVersion
            exportData.system.buildNumber = buildNumber
            exportData.system.gameVersion = gameVersion
        end
        
        -- Check if database is initialized
        if not SpectrumLootHelperDB or not SpectrumLootHelperDB.playerData then
            if SLH.Debug then
                SLH.Debug:LogInfo("Database", "Database not initialized - generating empty export", {})
            end
            
            exportData.sanitizedData.totalEntries = 0
            exportData.diagnostics.exportDuration = GetServerTime() - startTime
            
            return true, self:_FormatExportForDisplay(exportData)
        end
        
        -- Sanitize and export database entries
        local sampleCount = 0
        local maxSamples = 10  -- Limit sample entries for privacy and size
        
        for playerKey, playerData in pairs(SpectrumLootHelperDB.playerData) do
            exportData.sanitizedData.totalEntries = exportData.sanitizedData.totalEntries + 1
            
            -- Extract version and server information for distribution analysis
            local playerName, serverName, wowVersion = playerKey:match("^(.+)%-(.+)%-(%d+%.%d+)$")
            if wowVersion then
                exportData.sanitizedData.versionDistribution[wowVersion] = 
                    (exportData.sanitizedData.versionDistribution[wowVersion] or 0) + 1
            end
            if serverName then
                exportData.sanitizedData.serverDistribution[serverName] = 
                    (exportData.sanitizedData.serverDistribution[serverName] or 0) + 1
            end
            
            -- Add sample entry (sanitized) for diagnostic purposes
            if sampleCount < maxSamples and type(playerData) == "table" then
                local sanitizedEntry = self:_SanitizeEntry(playerKey, playerData, sampleCount + 1)
                table.insert(exportData.sanitizedData.sampleEntries, sanitizedEntry)
                sampleCount = sampleCount + 1
            end
            
            -- Quick integrity check for diagnostics
            if type(playerData) == "table" then
                local valid, error = self:ValidateEntry(playerData)
                if not valid then
                    table.insert(exportData.sanitizedData.integrityStatus, {
                        keyPattern = self:_SanitizeKeyPattern(playerKey),
                        issue = error,
                        entryType = type(playerData)
                    })
                end
            else
                table.insert(exportData.sanitizedData.integrityStatus, {
                    keyPattern = self:_SanitizeKeyPattern(playerKey),
                    issue = "Entry is not a table",
                    entryType = type(playerData)
                })
            end
        end
        
        -- Calculate export completion time
        exportData.diagnostics.exportDuration = GetServerTime() - startTime
        
        -- Log comprehensive export operation
        if SLH.Debug then
            SLH.Debug:LogInfo("Database", "Database export completed", {
                totalEntries = exportData.sanitizedData.totalEntries,
                sampleEntries = #exportData.sanitizedData.sampleEntries,
                integrityIssues = #exportData.sanitizedData.integrityStatus,
                exportDuration = exportData.diagnostics.exportDuration,
                privacyLevel = exportData.diagnostics.privacyLevel,
                operation = "debug_export_complete"
            })
        end
        
        -- Return formatted export for display
        return true, self:_FormatExportForDisplay(exportData)
        
    end)
end

-- Helper function to sanitize individual database entry
function Database:_SanitizeEntry(playerKey, playerData, sampleNumber)
    -- Create a sanitized version of the entry for debugging
    local sanitized = {
        sampleId = sampleNumber,
        keyPattern = self:_SanitizeKeyPattern(playerKey),
        dataStructure = {
            hasLastUpdate = playerData.LastUpdate ~= nil,
            lastUpdateType = type(playerData.LastUpdate),
            hasVenariiCharges = playerData.VenariiCharges ~= nil,
            venariiChargesType = type(playerData.VenariiCharges),
            venariiChargesValue = playerData.VenariiCharges,  -- Safe to include as it's just a number
            hasEquipment = playerData.Equipment ~= nil,
            equipmentType = type(playerData.Equipment)
        }
    }
    
    -- Include equipment structure analysis (no sensitive data)
    if playerData.Equipment and type(playerData.Equipment) == "table" then
        sanitized.equipmentAnalysis = {
            totalSlots = 0,
            trueSlots = 0,
            falseSlots = 0,
            invalidSlots = 0
        }
        
        for slotName, value in pairs(playerData.Equipment) do
            sanitized.equipmentAnalysis.totalSlots = sanitized.equipmentAnalysis.totalSlots + 1
            if type(value) == "boolean" then
                if value then
                    sanitized.equipmentAnalysis.trueSlots = sanitized.equipmentAnalysis.trueSlots + 1
                else
                    sanitized.equipmentAnalysis.falseSlots = sanitized.equipmentAnalysis.falseSlots + 1
                end
            else
                sanitized.equipmentAnalysis.invalidSlots = sanitized.equipmentAnalysis.invalidSlots + 1
            end
        end
    end
    
    return sanitized
end

-- Helper function to sanitize player key while preserving pattern information
function Database:_SanitizeKeyPattern(playerKey)
    -- Replace player name with generic placeholder but keep structure
    local playerName, serverName, wowVersion = playerKey:match("^(.+)%-(.+)%-(%d+%.%d+)$")
    if playerName and serverName and wowVersion then
        -- Create hash of player name for uniqueness while maintaining privacy
        local hash = 0
        for i = 1, #playerName do
            hash = hash + string.byte(playerName, i)
        end
        hash = hash % 1000  -- Keep it short
        
        return string.format("Player%03d-%s-%s", hash, serverName, wowVersion)
    else
        return "MALFORMED_KEY_PATTERN"
    end
end

-- Helper function to format export data for display
function Database:_FormatExportForDisplay(exportData)
    local lines = {}
    
    -- Header
    table.insert(lines, "=" .. string.rep("=", 60) .. "=")
    table.insert(lines, exportData.header.title)
    table.insert(lines, "Export Date: " .. exportData.header.dateString)
    table.insert(lines, "Database Version: " .. exportData.header.databaseVersion)
    table.insert(lines, "=" .. string.rep("=", 60) .. "=")
    table.insert(lines, "")
    
    -- System Information
    table.insert(lines, "SYSTEM INFORMATION:")
    table.insert(lines, "  WoW Version: " .. (exportData.system.wowVersion or "Unknown"))
    table.insert(lines, "  Build Number: " .. (exportData.system.buildNumber or "Unknown"))
    table.insert(lines, "  Realm: " .. exportData.system.realmName)
    table.insert(lines, "  Player: " .. exportData.system.playerName)
    table.insert(lines, "  Addon Version: " .. exportData.system.addonVersion)
    table.insert(lines, "")
    
    -- Database Statistics
    table.insert(lines, "DATABASE STATISTICS:")
    if exportData.statistics and exportData.statistics.database then
        local db = exportData.statistics.database
        table.insert(lines, "  Initialized: " .. (db.initialized and "Yes" or "No"))
        table.insert(lines, "  Total Entries: " .. db.totalEntries)
        table.insert(lines, "  Memory Usage: " .. (db.memoryUsageFormatted or "Unknown"))
        
        if exportData.statistics.summary then
            local s = exportData.statistics.summary
            table.insert(lines, "  Unique Players: " .. (s.totalPlayers or 0))
            table.insert(lines, "  Servers: " .. (s.totalServers or 0))
            table.insert(lines, "  WoW Versions: " .. (s.totalVersions or 0))
            table.insert(lines, "  Integrity Rate: " .. string.format("%.1f%%", s.integrityRate or 0))
            table.insert(lines, "  Health Status: " .. (s.healthStatus or "Unknown"))
        end
    end
    table.insert(lines, "")
    
    -- Version Distribution
    table.insert(lines, "WOW VERSION DISTRIBUTION:")
    if exportData.sanitizedData.versionDistribution then
        for version, count in pairs(exportData.sanitizedData.versionDistribution) do
            table.insert(lines, "  " .. version .. ": " .. count .. " entries")
        end
    end
    table.insert(lines, "")
    
    -- Server Distribution
    table.insert(lines, "SERVER DISTRIBUTION:")
    if exportData.sanitizedData.serverDistribution then
        for server, count in pairs(exportData.sanitizedData.serverDistribution) do
            table.insert(lines, "  " .. server .. ": " .. count .. " entries")
        end
    end
    table.insert(lines, "")
    
    -- Sample Entries (Sanitized)
    table.insert(lines, "SAMPLE ENTRIES (SANITIZED):")
    if exportData.sanitizedData.sampleEntries then
        for _, sample in ipairs(exportData.sanitizedData.sampleEntries) do
            table.insert(lines, "  Sample " .. sample.sampleId .. ":")
            table.insert(lines, "    Key Pattern: " .. sample.keyPattern)
            table.insert(lines, "    Venarii Charges: " .. (sample.dataStructure.venariiChargesValue or "null"))
            if sample.equipmentAnalysis then
                local eq = sample.equipmentAnalysis
                table.insert(lines, "    Equipment: " .. eq.totalSlots .. " slots (" .. eq.trueSlots .. " true, " .. eq.falseSlots .. " false, " .. eq.invalidSlots .. " invalid)")
            end
        end
    end
    table.insert(lines, "")
    
    -- Integrity Issues
    if exportData.sanitizedData.integrityStatus and #exportData.sanitizedData.integrityStatus > 0 then
        table.insert(lines, "INTEGRITY ISSUES:")
        for _, issue in ipairs(exportData.sanitizedData.integrityStatus) do
            table.insert(lines, "  " .. issue.keyPattern .. ": " .. issue.issue)
        end
        table.insert(lines, "")
    end
    
    -- Export Diagnostics
    table.insert(lines, "EXPORT DIAGNOSTICS:")
    table.insert(lines, "  Export Duration: " .. string.format("%.3f seconds", exportData.diagnostics.exportDuration))
    table.insert(lines, "  Privacy Level: " .. exportData.diagnostics.privacyLevel)
    table.insert(lines, "  Sanitization: " .. exportData.diagnostics.sanitizationMethod)
    table.insert(lines, "")
    
    -- Footer
    table.insert(lines, "=" .. string.rep("=", 60) .. "=")
    table.insert(lines, "This export is safe for sharing - no sensitive player data included")
    table.insert(lines, "Generated by SpectrumLootTool Database Export System")
    table.insert(lines, "=" .. string.rep("=", 60) .. "=")
    
    return table.concat(lines, "\n")
end

-- Check database integrity (alias for CheckDataIntegrity)
function Database:ValidateIntegrity()
    return self:CheckDataIntegrity()
end

-- Check database data integrity
-- Checks all entries against schema, verifies no corrupted data, checks for duplicates
-- Returns comprehensive integrity status and detailed issue list
function Database:CheckDataIntegrity()
    return self:SafeExecute("CheckDataIntegrity", function()
        
        if SLH.Debug then
            SLH.Debug:LogDebug("Database", "CheckDataIntegrity() starting comprehensive integrity check", {
                operation = "integrity_check"
            })
        end
        
        -- Initialize integrity check results
        local integrityResults = {
            startTime = GetServerTime(),
            totalEntries = 0,
            validEntries = 0,
            corruptedEntries = 0,
            duplicateEntries = 0,
            orphanedEntries = 0,
            schemaViolations = 0,
            issues = {},
            summary = {},
            passed = false
        }
        
        -- Check if database is initialized
        if not SpectrumLootHelperDB or not SpectrumLootHelperDB.playerData then
            if SLH.Debug then
                SLH.Debug:LogWarn("Database", "Database not initialized - cannot check integrity", {})
            end
            return true, "Database not initialized - nothing to check", integrityResults
        end
        
        -- Count total entries and perform initial checks
        for playerKey, playerData in pairs(SpectrumLootHelperDB.playerData) do
            integrityResults.totalEntries = integrityResults.totalEntries + 1
            
            if SLH.Debug then
                SLH.Debug:LogDebug("Database", "Checking entry integrity", {
                    playerKey = playerKey,
                    entryNumber = integrityResults.totalEntries
                })
            end
            
            -- Check entry structure (must be table)
            if type(playerData) ~= "table" then
                integrityResults.corruptedEntries = integrityResults.corruptedEntries + 1
                table.insert(integrityResults.issues, {
                    type = "corruption",
                    severity = "HIGH",
                    playerKey = playerKey,
                    issue = "Entry data is not a table",
                    details = {
                        actualType = type(playerData),
                        expectedType = "table"
                    }
                })
                if SLH.Debug then
                    SLH.Debug:LogError("Database", "Corrupted entry detected - not a table", {
                        playerKey = playerKey,
                        actualType = type(playerData)
                    })
                end
                goto continue -- Skip further validation for this corrupted entry
            end
            
            -- Validate entry against schema using existing ValidateEntry function
            local entryValid, entryError = self:ValidateEntry(playerData)
            if not entryValid then
                integrityResults.schemaViolations = integrityResults.schemaViolations + 1
                table.insert(integrityResults.issues, {
                    type = "schema_violation",
                    severity = "MEDIUM",
                    playerKey = playerKey,
                    issue = "Entry violates schema requirements",
                    details = {
                        validationError = entryError
                    }
                })
                if SLH.Debug then
                    SLH.Debug:LogWarn("Database", "Schema violation detected", {
                        playerKey = playerKey,
                        validationError = entryError
                    })
                end
            else
                integrityResults.validEntries = integrityResults.validEntries + 1
            end
            
            -- Check for key format consistency
            local playerName, serverName, wowVersion = playerKey:match("^(.+)%-(.+)%-(%d+%.%d+)$")
            if not playerName or not serverName or not wowVersion then
                integrityResults.orphanedEntries = integrityResults.orphanedEntries + 1
                table.insert(integrityResults.issues, {
                    type = "orphaned_entry",
                    severity = "MEDIUM",
                    playerKey = playerKey,
                    issue = "Player key does not match expected format",
                    details = {
                        expectedPattern = "PlayerName-ServerName-Version",
                        actualKey = playerKey
                    }
                })
                if SLH.Debug then
                    SLH.Debug:LogWarn("Database", "Orphaned entry with invalid key format", {
                        playerKey = playerKey,
                        expectedPattern = "PlayerName-ServerName-Version"
                    })
                end
            else
                -- Verify extracted info matches entry data (if available)
                if playerData.PlayerName and playerData.PlayerName ~= playerName then
                    table.insert(integrityResults.issues, {
                        type = "data_mismatch",
                        severity = "MEDIUM",
                        playerKey = playerKey,
                        issue = "PlayerName in key doesn't match entry data",
                        details = {
                            keyPlayerName = playerName,
                            entryPlayerName = playerData.PlayerName
                        }
                    })
                end
                
                if playerData.ServerName and playerData.ServerName ~= serverName then
                    table.insert(integrityResults.issues, {
                        type = "data_mismatch",
                        severity = "MEDIUM",
                        playerKey = playerKey,
                        issue = "ServerName in key doesn't match entry data",
                        details = {
                            keyServerName = serverName,
                            entryServerName = playerData.ServerName
                        }
                    })
                end
                
                if playerData.WoWVersion and playerData.WoWVersion ~= wowVersion then
                    table.insert(integrityResults.issues, {
                        type = "data_mismatch",
                        severity = "MEDIUM",
                        playerKey = playerKey,
                        issue = "WoWVersion in key doesn't match entry data",
                        details = {
                            keyWoWVersion = wowVersion,
                            entryWoWVersion = playerData.WoWVersion
                        }
                    })
                end
            end
            
            ::continue:: -- Label for corrupted entry skip
        end
        
        -- Check for duplicate entries (same player, different keys)
        local playerTracker = {}
        for playerKey, playerData in pairs(SpectrumLootHelperDB.playerData) do
            if type(playerData) == "table" then
                local playerName, serverName, wowVersion = playerKey:match("^(.+)%-(.+)%-(%d+%.%d+)$")
                if playerName and serverName then
                    local playerIdentifier = playerName .. "-" .. serverName
                    if not playerTracker[playerIdentifier] then
                        playerTracker[playerIdentifier] = {}
                    end
                    table.insert(playerTracker[playerIdentifier], {
                        key = playerKey,
                        version = wowVersion
                    })
                end
            end
        end
        
        -- Report duplicate analysis (not necessarily errors, but good to track)
        for playerIdentifier, entries in pairs(playerTracker) do
            if #entries > 1 then
                -- Multiple versions for same player (this is expected behavior)
                if SLH.Debug then
                    SLH.Debug:LogInfo("Database", "Multiple versions found for player", {
                        player = playerIdentifier,
                        versions = #entries,
                        keys = entries
                    })
                end
            end
        end
        
        -- Generate comprehensive summary
        integrityResults.endTime = GetServerTime()
        integrityResults.duration = integrityResults.endTime - integrityResults.startTime
        
        -- Calculate success metrics
        local successRate = 0
        if integrityResults.totalEntries > 0 then
            successRate = (integrityResults.validEntries / integrityResults.totalEntries) * 100
        end
        
        integrityResults.passed = (integrityResults.corruptedEntries == 0 and 
                                  integrityResults.schemaViolations == 0 and 
                                  integrityResults.orphanedEntries == 0)
        
        -- Generate summary information
        table.insert(integrityResults.summary, string.format("Total entries checked: %d", integrityResults.totalEntries))
        table.insert(integrityResults.summary, string.format("Valid entries: %d (%.1f%%)", integrityResults.validEntries, successRate))
        table.insert(integrityResults.summary, string.format("Corrupted entries: %d", integrityResults.corruptedEntries))
        table.insert(integrityResults.summary, string.format("Schema violations: %d", integrityResults.schemaViolations))
        table.insert(integrityResults.summary, string.format("Orphaned entries: %d", integrityResults.orphanedEntries))
        table.insert(integrityResults.summary, string.format("Total issues found: %d", #integrityResults.issues))
        
        -- Log comprehensive integrity check results
        if SLH.Debug then
            SLH.Debug:LogInfo("Database", "Integrity check completed", {
                totalEntries = integrityResults.totalEntries,
                validEntries = integrityResults.validEntries,
                corruptedEntries = integrityResults.corruptedEntries,
                schemaViolations = integrityResults.schemaViolations,
                orphanedEntries = integrityResults.orphanedEntries,
                totalIssues = #integrityResults.issues,
                successRate = successRate,
                passed = integrityResults.passed,
                duration = integrityResults.duration,
                operation = "integrity_check_complete"
            })
        end
        
        -- Return results with appropriate success message
        local message
        if integrityResults.passed then
            message = string.format(
                "Database integrity check PASSED: %d entries verified, no critical issues found",
                integrityResults.totalEntries
            )
        else
            message = string.format(
                "Database integrity check found issues: %d corrupted, %d schema violations, %d orphaned entries",
                integrityResults.corruptedEntries,
                integrityResults.schemaViolations,
                integrityResults.orphanedEntries
            )
        end
        
        return true, message, integrityResults
        
    end)
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Clear all data for testing purposes
-- WARNING: This function completely wipes all database data - use only for testing/debugging
-- Provides comprehensive confirmation and logging to prevent accidental data loss
function Database:ClearAllData()
    return self:SafeExecute("ClearAllData", function()
        
        if SLH.Debug then
            SLH.Debug:LogDebug("Database", "ClearAllData() starting data clear operation", {
                operation = "clear_all_data",
                warning = "This will permanently delete all database entries"
            })
        end
        
        -- Ensure database is initialized before attempting to clear
        if not SpectrumLootHelperDB then
            if SLH.Debug then
                SLH.Debug:LogWarn("Database", "Cannot clear data - SpectrumLootHelperDB not initialized", {})
            end
            return true, "No data to clear - database not initialized"
        end
        
        -- Count entries before clearing for logging
        local entriesBeforeClear = 0
        if SpectrumLootHelperDB.playerData then
            for _ in pairs(SpectrumLootHelperDB.playerData) do
                entriesBeforeClear = entriesBeforeClear + 1
            end
        end
        
        -- Get current database statistics before clearing
        local statsBeforeClear = {}
        local debugStatsSuccess, debugStats = self:GetDebugStats()
        if debugStatsSuccess and debugStats then
            statsBeforeClear = {
                totalEntries = debugStats.database.totalEntries,
                memoryUsage = debugStats.database.memoryUsage,
                totalPlayers = debugStats.summary.totalPlayers or 0,
                totalServers = debugStats.summary.totalServers or 0,
                totalVersions = debugStats.summary.totalVersions or 0
            }
        end
        
        -- Clear all player data
        SpectrumLootHelperDB.playerData = {}
        
        -- Reset database metadata but preserve version information
        local preservedVersion = SpectrumLootHelperDB.databaseVersion
        local preservedUpgradeHistory = SpectrumLootHelperDB.schemaUpgradeHistory
        
        -- Reset additional data structures while preserving critical system info
        if SpectrumLootHelperDB.integrityMetadata then
            SpectrumLootHelperDB.integrityMetadata = {
                lastIntegrityCheck = nil,
                integrityScore = nil
            }
        end
        
        if SpectrumLootHelperDB.v2Features then
            -- Keep v2Features but reset any data-dependent values
            SpectrumLootHelperDB.v2Features.lastDataClear = GetServerTime()
        end
        
        -- Update last database access timestamp
        SpectrumLootHelperDB.lastDatabaseAccess = time()
        
        -- Verify data was actually cleared
        local entriesAfterClear = 0
        if SpectrumLootHelperDB.playerData then
            for _ in pairs(SpectrumLootHelperDB.playerData) do
                entriesAfterClear = entriesAfterClear + 1
            end
        end
        
        if entriesAfterClear > 0 then
            if SLH.Debug then
                SLH.Debug:LogError("Database", "Data clear verification failed - entries still present", {
                    entriesRemaining = entriesAfterClear
                })
            end
            return false, "Data clear failed - entries still present in database"
        end
        
        -- Add clear operation to upgrade history for tracking
        if not SpectrumLootHelperDB.schemaUpgradeHistory then
            SpectrumLootHelperDB.schemaUpgradeHistory = {}
        end
        
        table.insert(SpectrumLootHelperDB.schemaUpgradeHistory, {
            operation = "data_clear",
            timestamp = GetServerTime(),
            entriesCleared = entriesBeforeClear,
            preservedVersion = preservedVersion,
            clearedBy = "manual_operation"
        })
        
        -- Log comprehensive clear operation results
        if SLH.Debug then
            SLH.Debug:LogInfo("Database", "Database clear operation completed successfully", {
                operation = "clear_all_data_complete",
                entriesBeforeClear = entriesBeforeClear,
                entriesAfterClear = entriesAfterClear,
                entriesCleared = entriesBeforeClear - entriesAfterClear,
                statsBeforeClear = statsBeforeClear,
                preservedDatabaseVersion = preservedVersion,
                preservedUpgradeHistory = preservedUpgradeHistory ~= nil,
                clearTimestamp = GetServerTime(),
                verificationPassed = entriesAfterClear == 0
            })
        end
        
        -- Return success with detailed clear report
        local message = string.format(
            "Database cleared successfully: %d entries removed, database version %s preserved",
            entriesBeforeClear,
            preservedVersion or "unknown"
        )
        
        return true, message, {
            entriesCleared = entriesBeforeClear,
            databaseVersion = preservedVersion,
            clearTimestamp = GetServerTime(),
            upgradeHistoryPreserved = preservedUpgradeHistory ~= nil
        }
        
    end)
end

-- Get database size information
-- Provides comprehensive database size metrics for monitoring and optimization
-- Returns detailed size breakdown including memory usage, entry counts, and storage efficiency
function Database:GetSize()
    return self:SafeExecute("GetSize", function()
        
        if SLH.Debug then
            SLH.Debug:LogDebug("Database", "GetSize() starting size calculation", {
                operation = "database_size_analysis"
            })
        end
        
        local startTime = GetServerTime()
        
        -- Initialize size analysis structure
        local sizeInfo = {
            timestamp = startTime,
            database = {
                initialized = false,
                totalEntries = 0,
                totalMemoryBytes = 0,
                totalMemoryFormatted = "0 B"
            },
            breakdown = {
                playerDataSize = 0,
                metadataSize = 0,
                upgradeHistorySize = 0,
                otherDataSize = 0
            },
            entryAnalysis = {
                averageEntrySize = 0,
                largestEntrySize = 0,
                smallestEntrySize = math.huge,
                entrySizeDistribution = {}
            },
            keyAnalysis = {
                averageKeyLength = 0,
                totalKeySize = 0,
                uniqueVersions = 0,
                uniqueServers = 0,
                uniquePlayers = 0
            },
            efficiency = {
                storageEfficiency = 0,
                overhead = 0,
                optimization = "unknown"
            }
        }
        
        -- Check if database is initialized
        if not SpectrumLootHelperDB then
            if SLH.Debug then
                SLH.Debug:LogInfo("Database", "Database not initialized for size analysis", {})
            end
            sizeInfo.database.initialized = false
            return true, sizeInfo
        end
        
        sizeInfo.database.initialized = true
        
        -- Calculate size of saved variables structure
        local metadataSize = 0
        
        -- Database version size
        if SpectrumLootHelperDB.databaseVersion then
            metadataSize = metadataSize + #SpectrumLootHelperDB.databaseVersion
        end
        
        -- Last database access timestamp
        metadataSize = metadataSize + 8  -- timestamp size
        
        -- Upgrade history size
        local upgradeHistorySize = 0
        if SpectrumLootHelperDB.schemaUpgradeHistory then
            for _, historyEntry in ipairs(SpectrumLootHelperDB.schemaUpgradeHistory) do
                upgradeHistorySize = upgradeHistorySize + self:_EstimateTableSize(historyEntry)
            end
        end
        
        -- Other metadata size
        local otherDataSize = 0
        if SpectrumLootHelperDB.integrityMetadata then
            otherDataSize = otherDataSize + self:_EstimateTableSize(SpectrumLootHelperDB.integrityMetadata)
        end
        if SpectrumLootHelperDB.v2Features then
            otherDataSize = otherDataSize + self:_EstimateTableSize(SpectrumLootHelperDB.v2Features)
        end
        
        -- Analyze player data
        local playerDataSize = 0
        local totalKeySize = 0
        local versionTracker = {}
        local serverTracker = {}
        local playerTracker = {}
        
        if SpectrumLootHelperDB.playerData then
            
            for playerKey, playerData in pairs(SpectrumLootHelperDB.playerData) do
                sizeInfo.database.totalEntries = sizeInfo.database.totalEntries + 1
                
                -- Calculate entry size
                local entrySize = #playerKey  -- Key size
                local dataSize = 0
                
                if type(playerData) == "table" then
                    dataSize = self:_EstimateTableSize(playerData)
                else
                    dataSize = 50  -- Estimate for corrupted entries
                end
                
                local totalEntrySize = entrySize + dataSize
                playerDataSize = playerDataSize + totalEntrySize
                totalKeySize = totalKeySize + #playerKey
                
                -- Track entry size statistics
                sizeInfo.entryAnalysis.largestEntrySize = math.max(sizeInfo.entryAnalysis.largestEntrySize, totalEntrySize)
                sizeInfo.entryAnalysis.smallestEntrySize = math.min(sizeInfo.entryAnalysis.smallestEntrySize, totalEntrySize)
                
                -- Extract version, server, and player information
                local playerName, serverName, wowVersion = playerKey:match("^(.+)%-(.+)%-(%d+%.%d+)$")
                if playerName and serverName and wowVersion then
                    versionTracker[wowVersion] = true
                    serverTracker[serverName] = true
                    playerTracker[playerName .. "-" .. serverName] = true
                end
                
                -- Track size distribution by ranges
                local sizeRange = "Unknown"
                if totalEntrySize < 512 then
                    sizeRange = "< 512B"
                elseif totalEntrySize < 1024 then
                    sizeRange = "512B - 1KB"
                elseif totalEntrySize < 2048 then
                    sizeRange = "1KB - 2KB"
                elseif totalEntrySize < 4096 then
                    sizeRange = "2KB - 4KB"
                else
                    sizeRange = "> 4KB"
                end
                
                sizeInfo.entryAnalysis.entrySizeDistribution[sizeRange] = 
                    (sizeInfo.entryAnalysis.entrySizeDistribution[sizeRange] or 0) + 1
            end
        end
        
        -- Calculate averages and totals
        if sizeInfo.database.totalEntries > 0 then
            sizeInfo.entryAnalysis.averageEntrySize = playerDataSize / sizeInfo.database.totalEntries
            sizeInfo.keyAnalysis.averageKeyLength = totalKeySize / sizeInfo.database.totalEntries
        end
        
        -- Reset smallestEntrySize if no entries found
        if sizeInfo.entryAnalysis.smallestEntrySize == math.huge then
            sizeInfo.entryAnalysis.smallestEntrySize = 0
        end
        
        -- Count unique entities
        sizeInfo.keyAnalysis.uniqueVersions = self:_CountTableEntries(versionTracker)
        sizeInfo.keyAnalysis.uniqueServers = self:_CountTableEntries(serverTracker)
        sizeInfo.keyAnalysis.uniquePlayers = self:_CountTableEntries(playerTracker)
        sizeInfo.keyAnalysis.totalKeySize = totalKeySize
        
        -- Calculate total sizes
        sizeInfo.breakdown.playerDataSize = playerDataSize
        sizeInfo.breakdown.metadataSize = metadataSize
        sizeInfo.breakdown.upgradeHistorySize = upgradeHistorySize
        sizeInfo.breakdown.otherDataSize = otherDataSize
        
        local totalSize = playerDataSize + metadataSize + upgradeHistorySize + otherDataSize
        sizeInfo.database.totalMemoryBytes = totalSize
        sizeInfo.database.totalMemoryFormatted = self:_FormatMemorySize(totalSize)
        
        -- Calculate efficiency metrics
        if totalSize > 0 then
            local dataPercentage = (playerDataSize / totalSize) * 100
            local overheadPercentage = ((metadataSize + upgradeHistorySize + otherDataSize) / totalSize) * 100
            
            sizeInfo.efficiency.storageEfficiency = dataPercentage
            sizeInfo.efficiency.overhead = overheadPercentage
            
            if dataPercentage > 90 then
                sizeInfo.efficiency.optimization = "excellent"
            elseif dataPercentage > 80 then
                sizeInfo.efficiency.optimization = "good"
            elseif dataPercentage > 70 then
                sizeInfo.efficiency.optimization = "fair"
            else
                sizeInfo.efficiency.optimization = "poor"
            end
        end
        
        -- Calculate analysis duration
        local analysisTime = GetServerTime() - startTime
        sizeInfo.analysisDuration = analysisTime
        
        -- Log comprehensive size analysis results
        if SLH.Debug then
            SLH.Debug:LogInfo("Database", "Database size analysis completed", {
                operation = "database_size_complete",
                totalEntries = sizeInfo.database.totalEntries,
                totalMemoryBytes = sizeInfo.database.totalMemoryBytes,
                totalMemoryFormatted = sizeInfo.database.totalMemoryFormatted,
                averageEntrySize = sizeInfo.entryAnalysis.averageEntrySize,
                largestEntrySize = sizeInfo.entryAnalysis.largestEntrySize,
                smallestEntrySize = sizeInfo.entryAnalysis.smallestEntrySize,
                uniqueVersions = sizeInfo.keyAnalysis.uniqueVersions,
                uniqueServers = sizeInfo.keyAnalysis.uniqueServers,
                uniquePlayers = sizeInfo.keyAnalysis.uniquePlayers,
                storageEfficiency = sizeInfo.efficiency.storageEfficiency,
                overhead = sizeInfo.efficiency.overhead,
                optimization = sizeInfo.efficiency.optimization,
                analysisDuration = analysisTime
            })
        end
        
        return true, sizeInfo
        
    end)
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
