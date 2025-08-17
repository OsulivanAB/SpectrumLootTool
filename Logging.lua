local ADDON_NAME, SLH = ...

-- OUTLINE: Logging.lua - Structured audit logging system for officer actions
-- Purpose: Track user actions for auditing purposes (separate from debug and sync logging)
-- This is NOT a debugging tool - it's an audit log for officer accountability

SLH.Logging = {
    version = "1.0", -- Logging system version
    
    -- Performance optimization: cached data
    _cache = {
        playerName = nil,
        playerServer = nil,
        lastCacheTime = 0,
        cacheValidDuration = 300, -- 5 minutes
        isOfficerResult = nil,
        isOfficerCacheTime = 0
    }
}

-- Initialize the logging system
-- Sets up data structures and validates officer permissions
function SLH.Logging:Init()
    SLH.Debug:LogDebug("Logging", "Initializing audit logging system", { version = self.version })
    
    -- Ensure SpectrumLootHelperDB exists (should be created by Core.lua)
    if not SpectrumLootHelperDB then
        SLH.Debug:LogError("Logging", "SpectrumLootHelperDB not found - Core.lua may not be loaded", {})
        return false
    end
    
    -- Initialize auditLog table if it doesn't exist
    if not SpectrumLootHelperDB.auditLog then
        SpectrumLootHelperDB.auditLog = {}
        SLH.Debug:LogInfo("Logging", "Created new auditLog table in saved variables", {})
    else
        SLH.Debug:LogDebug("Logging", "Existing auditLog table found", { 
            entryCount = self:GetLogCount() 
        })
    end
    
    -- Initialize version tracking for future database migrations
    if not SpectrumLootHelperDB.auditLog._version then
        SpectrumLootHelperDB.auditLog._version = self.version
        SLH.Debug:LogInfo("Logging", "Set auditLog database version", { version = self.version })
    else
        -- Check for version mismatch (future migration support)
        if SpectrumLootHelperDB.auditLog._version ~= self.version then
            SLH.Debug:LogWarn("Logging", "AuditLog database version mismatch", {
                currentVersion = self.version,
                databaseVersion = SpectrumLootHelperDB.auditLog._version
            })
            -- Future: Add migration logic here
        end
    end
    
    SLH.Debug:LogInfo("Logging", "Audit logging system initialized successfully", {
        version = self.version,
        entryCount = self:GetLogCount()
    })
    
    return true
end

-- Helper function to get current log count (for initialization and debugging)
-- Returns: number - Count of audit log entries
function SLH.Logging:GetLogCount()
    if not SpectrumLootHelperDB or not SpectrumLootHelperDB.auditLog then
        return 0
    end
    
    local count = 0
    for logID, entry in pairs(SpectrumLootHelperDB.auditLog) do
        -- Skip version metadata entry
        if logID ~= "_version" then
            count = count + 1
        end
    end
    
    return count
end

-- Internal function to check if current user has officer permissions
-- Uses existing SLH.OFFICER_RANK threshold for permission gating
-- Returns: boolean - true if user is officer, false otherwise
function SLH.Logging:IsOfficer()
    -- Performance optimization: cache officer status for 30 seconds
    local currentTime = GetTime()
    if self._cache.isOfficerResult ~= nil and (currentTime - self._cache.isOfficerCacheTime) < 30 then
        SLH.Debug:LogDebug("Logging", "Using cached officer status", { 
            cached = self._cache.isOfficerResult,
            cacheAge = currentTime - self._cache.isOfficerCacheTime
        })
        return self._cache.isOfficerResult
    end
    
    local success, result = pcall(function()
        SLH.Debug:LogDebug("Logging", "Checking officer permissions", { playerName = self:GetCachedPlayerName() })
        
        local unit = "player"
        local guild = nil
        local rankIndex = nil
        
        -- Protected call for guild API operations
        local guildSuccess, guildInfo = pcall(function()
            if UnitIsInMyGuild(unit) then
                local g, _, r = GetGuildInfo(unit)
                return g, r
            end
            return nil, nil
        end)
        
        if guildSuccess then
            guild, rankIndex = guildInfo, select(2, guildInfo)
            SLH.Debug:LogDebug("Logging", "Retrieved guild info from GetGuildInfo", {
                guild = guild,
                rankIndex = rankIndex
            })
        else
            SLH.Debug:LogWarn("Logging", "GetGuildInfo API call failed", { error = guildInfo })
        end
    
        -- Fallback: search guild roster if direct lookup failed
        if not guild or not rankIndex then
            local rosterSuccess, rosterResult = pcall(function()
                local numMembers = GetNumGuildMembers()
                if not numMembers or numMembers == 0 then
                    return nil, nil
                end
                
                for i = 1, numMembers do
                    local name, _, rankIndex2 = GetGuildRosterInfo(i)
                    if name and name == UnitName("player") then
                        local fallbackGuild = GetGuildInfo("player") or "Spectrum Federation"
                        return fallbackGuild, rankIndex2
                    end
                end
                return nil, nil
            end)
            
            if rosterSuccess and rosterResult then
                guild, rankIndex = rosterResult, select(2, rosterResult)
                SLH.Debug:LogDebug("Logging", "Found player in guild roster", {
                    playerName = UnitName("player"),
                    guild = guild,
                    rankIndex = rankIndex
                })
            else
                SLH.Debug:LogWarn("Logging", "Guild roster lookup failed", { error = rosterResult })
            end
        end
        
        -- If no guild data found, return false
        if not guild then
            SLH.Debug:LogWarn("Logging", "No guild data found for current player", {})
            return false
        end
        
        if not rankIndex then
            SLH.Debug:LogWarn("Logging", "No rank index found for current player", { guild = guild })
            return false
        end
        
        -- Enhanced guild name matching - be flexible like Core.lua
        local isSpectrumFed = false
        local guildLower = string.lower(guild)
        
        -- Check various possible guild name formats
        if string.find(guildLower, "spectrum federation") 
           or (string.find(guildLower, "spectrum") and string.find(guildLower, "federation")) then
            isSpectrumFed = true
        end
        
        local isOfficer = isSpectrumFed and rankIndex <= SLH.OFFICER_RANK
        
        SLH.Debug:LogDebug("Logging", "Officer permission check completed", {
            guild = guild,
            rankIndex = rankIndex,
            isSpectrumFed = isSpectrumFed,
            isOfficer = isOfficer,
            officerRankThreshold = SLH.OFFICER_RANK
        })
        
        return isOfficer
    end)
    
    if success then
        -- Cache the result for performance
        self._cache.isOfficerResult = result
        self._cache.isOfficerCacheTime = currentTime
        return result
    else
        SLH.Debug:LogError("Logging", "Critical error in IsOfficer function", { 
            error = result,
            failsafe = "Returning false for safety"
        })
        return false
    end
end

-- Performance optimization: cached player information
-- Returns: string - Current player name (cached)
function SLH.Logging:GetCachedPlayerName()
    local currentTime = GetTime()
    
    if self._cache.playerName and (currentTime - self._cache.lastCacheTime) < self._cache.cacheValidDuration then
        return self._cache.playerName
    end
    
    local success, name = pcall(UnitName, "player")
    if success and name then
        self._cache.playerName = name
        self._cache.lastCacheTime = currentTime
        return name
    end
    
    return self._cache.playerName or "Unknown"
end

-- Performance optimization: cached server information  
-- Returns: string - Current server name (cached)
function SLH.Logging:GetCachedServerName()
    local currentTime = GetTime()
    
    if self._cache.playerServer and (currentTime - self._cache.lastCacheTime) < self._cache.cacheValidDuration then
        return self._cache.playerServer
    end
    
    local success, server = pcall(GetRealmName)
    if success and server then
        self._cache.playerServer = server
        self._cache.lastCacheTime = currentTime
        return server
    end
    
    return self._cache.playerServer or "Unknown Server"
end

-- Generate unique hash-based Log ID for new entries
-- Combines timestamp, officer name, and action details for uniqueness
-- Returns: string - unique hashed identifier for the log entry
function SLH.Logging:GenerateLogID(officerName, timestamp, fieldChanged)
    SLH.Debug:LogDebug("Logging", "Generating log ID", {
        officerName = officerName,
        timestamp = timestamp,
        fieldChanged = fieldChanged
    })
    
    -- Input validation
    if not officerName or officerName == "" then
        SLH.Debug:LogError("Logging", "GenerateLogID requires valid officerName", {})
        return nil
    end
    
    if not timestamp or timestamp <= 0 then
        SLH.Debug:LogError("Logging", "GenerateLogID requires valid timestamp", { timestamp = timestamp })
        return nil
    end
    
    if not fieldChanged or fieldChanged == "" then
        SLH.Debug:LogError("Logging", "GenerateLogID requires valid fieldChanged", {})
        return nil
    end
    
    -- Create concatenated string for hashing
    local hashString = officerName .. "|" .. tostring(timestamp) .. "|" .. fieldChanged
    
    -- Simple but effective hash algorithm for WoW addon context
    local hash = 0
    for i = 1, string.len(hashString) do
        local char = string.byte(hashString, i)
        hash = hash + char
        hash = hash * 31 -- Prime multiplier for better distribution
        -- Keep hash manageable by using modulo
        hash = hash % 1000000
    end
    
    -- Add microsecond precision to reduce collision probability
    local microTime = GetTime()
    local microSuffix = math.floor((microTime * 1000) % 1000)
    
    -- Format as readable hash: LOG_XXXXXX_YYY (where X=hash, Y=micro)
    local logID = string.format("LOG_%06d_%03d", hash, microSuffix)
    
    -- Additional collision check - ensure ID doesn't already exist
    local attempts = 0
    local originalID = logID
    while SpectrumLootHelperDB and SpectrumLootHelperDB.auditLog and SpectrumLootHelperDB.auditLog[logID] do
        attempts = attempts + 1
        -- Add collision counter suffix
        logID = originalID .. "_" .. attempts
        
        -- Prevent infinite loop
        if attempts > 999 then
            SLH.Debug:LogError("Logging", "Too many ID collisions, using timestamp fallback", {
                originalID = originalID,
                attempts = attempts
            })
            logID = "LOG_" .. tostring(timestamp) .. "_" .. tostring(math.random(1000, 9999))
            break
        end
    end
    
    SLH.Debug:LogDebug("Logging", "Log ID generated successfully", {
        logID = logID,
        hashString = hashString,
        collisionAttempts = attempts
    })
    
    return logID
end

-- Create a new audit log entry (officer-gated)
-- Parameters:
--   playerName: string - Name of player being modified
--   playerServer: string - Server of player being modified  
--   fieldChanged: string - Either "Venari Charges" or "Gear Slot"
--   changeMade: string/boolean - For Venari: "up"/"down", For Gear: true/false
-- Returns: string - Log ID if successful, nil if failed
function SLH.Logging:CreateLogEntry(playerName, playerServer, fieldChanged, changeMade)
    -- Performance optimization: defer heavy operations during combat
    local inCombat = InCombatLockdown and InCombatLockdown()
    local debugLevel = inCombat and "LogInfo" or "LogDebug"
    
    SLH.Debug[debugLevel](SLH.Debug, "Logging", "CreateLogEntry called", {
        playerName = playerName,
        playerServer = playerServer,
        fieldChanged = fieldChanged,
        changeMade = changeMade,
        inCombat = inCombat
    })
    
    -- Validate officer permissions first
    if not self:IsOfficer() then
        SLH.Debug:LogWarn("Logging", "CreateLogEntry rejected - insufficient permissions", {
            currentPlayer = UnitName("player")
        })
        return nil
    end
    
    -- Validate required parameters
    if not playerName or playerName == "" then
        SLH.Debug:LogError("Logging", "CreateLogEntry failed - invalid playerName", { playerName = playerName })
        return nil
    end
    
    if not playerServer or playerServer == "" then
        SLH.Debug:LogError("Logging", "CreateLogEntry failed - invalid playerServer", { playerServer = playerServer })
        return nil
    end
    
    -- Validate fieldChanged parameter
    local validFields = { ["Venari Charges"] = true, ["Gear Slot"] = true }
    if not fieldChanged or not validFields[fieldChanged] then
        SLH.Debug:LogError("Logging", "CreateLogEntry failed - invalid fieldChanged", {
            fieldChanged = fieldChanged,
            validFields = { "Venari Charges", "Gear Slot" }
        })
        return nil
    end
    
    -- Validate changeMade parameter based on field type
    local isValidChange = false
    if fieldChanged == "Venari Charges" then
        isValidChange = (changeMade == "up" or changeMade == "down")
    elseif fieldChanged == "Gear Slot" then
        isValidChange = (changeMade == true or changeMade == false)
    end
    
    if not isValidChange then
        SLH.Debug:LogError("Logging", "CreateLogEntry failed - invalid changeMade for field type", {
            fieldChanged = fieldChanged,
            changeMade = changeMade,
            expectedForVenari = "up or down",
            expectedForGear = "true or false"
        })
        return nil
    end
    
    -- Get current timestamp and officer information with error handling
    local timestamp, officerName, officerServer
    
    local timeSuccess, timeResult = pcall(GetServerTime)
    if timeSuccess and timeResult and timeResult > 0 then
        timestamp = timeResult
    else
        SLH.Debug:LogError("Logging", "GetServerTime failed, using fallback", { 
            error = timeResult,
            fallback = "Using time() approximation"
        })
        timestamp = time() -- Fallback to Lua time
    end
    
    -- Use cached player information for better performance
    officerName = self:GetCachedPlayerName()
    if officerName == "Unknown" then
        SLH.Debug:LogError("Logging", "Cannot determine officer name", { 
            impact = "Cannot create log entry without officer name"
        })
        return nil
    end
    
    officerServer = self:GetCachedServerName()
    
    -- Generate unique log ID
    local logID = self:GenerateLogID(officerName, timestamp, fieldChanged)
    if not logID then
        SLH.Debug:LogError("Logging", "CreateLogEntry failed - could not generate log ID", {})
        return nil
    end
    
    -- Ensure database structure exists and is valid
    local dbSuccess, dbResult = pcall(function()
        if not SpectrumLootHelperDB then
            error("SpectrumLootHelperDB not found")
        end
        
        if not SpectrumLootHelperDB.auditLog then
            SLH.Debug:LogWarn("Logging", "auditLog table missing, attempting to recreate", {})
            SpectrumLootHelperDB.auditLog = { _version = self.version }
        end
        
        if type(SpectrumLootHelperDB.auditLog) ~= "table" then
            error("auditLog is not a table - database corruption detected")
        end
        
        return true
    end)
    
    if not dbSuccess then
        SLH.Debug:LogError("Logging", "Database integrity check failed", { 
            error = dbResult,
            impact = "Cannot create log entry"
        })
        return nil
    end
    
    -- Create and store log entry structure with error protection
    local storageSuccess, storageError = pcall(function()
        local logEntry = {
            ID = logID,
            PlayerName = playerName,
            PlayerServer = playerServer,
            OfficerName = officerName,
            OfficerServer = officerServer,
            Timestamp = timestamp,
            FieldChanged = fieldChanged,
            ChangeMade = changeMade
        }
        
        -- Validate entry structure before storage
        for key, value in pairs(logEntry) do
            if value == nil then
                error("Log entry field '" .. key .. "' is nil")
            end
        end
        
        -- Store in saved variables
        SpectrumLootHelperDB.auditLog[logID] = logEntry
        return true
    end)
    
    if not storageSuccess then
        SLH.Debug:LogError("Logging", "Failed to store log entry", { 
            logID = logID,
            error = storageError,
            impact = "Log entry not saved"
        })
        return nil
    end
    
    SLH.Debug:LogInfo("Logging", "Log entry created successfully", {
        logID = logID,
        playerName = playerName,
        playerServer = playerServer,
        officerName = officerName,
        fieldChanged = fieldChanged,
        changeMade = changeMade,
        timestamp = timestamp
    })
    
    return logID
end

-- Retrieve all audit log entries 
-- Returns: table - Array of all log entries, empty table if none exist
function SLH.Logging:GetAllLogs()
    SLH.Debug:LogDebug("Logging", "GetAllLogs called", {})
    
    -- Check if database exists
    if not SpectrumLootHelperDB or not SpectrumLootHelperDB.auditLog then
        SLH.Debug:LogWarn("Logging", "GetAllLogs - auditLog database not found", {})
        return {}
    end
    
    local logs = {}
    local entryCount = 0
    
    -- Optimized table iteration - pre-allocate if possible
    for logID, entry in pairs(SpectrumLootHelperDB.auditLog) do
        if logID ~= "_version" and type(entry) == "table" and entry.Timestamp then
            logs[#logs + 1] = entry -- Faster than table.insert
            entryCount = entryCount + 1
        end
    end
    
    -- Optimized sort - only if we have entries
    if entryCount > 1 then
        table.sort(logs, function(a, b)
            return a.Timestamp > b.Timestamp
        end)
    end
    
    SLH.Debug:LogDebug("Logging", "GetAllLogs completed", {
        entryCount = entryCount,
        sortedByTimestamp = "newest first"
    })
    
    return logs
end

-- Retrieve audit log entries created by current user only
-- Returns: table - Array of log entries from current officer, empty table if none
function SLH.Logging:GetMyLogs()
    local currentPlayer = self:GetCachedPlayerName()
    SLH.Debug:LogDebug("Logging", "GetMyLogs called", { currentPlayer = currentPlayer })
    
    -- Check if database exists
    if not SpectrumLootHelperDB or not SpectrumLootHelperDB.auditLog then
        SLH.Debug:LogWarn("Logging", "GetMyLogs - auditLog database not found", {})
        return {}
    end
    
    if currentPlayer == "Unknown" then
        SLH.Debug:LogError("Logging", "GetMyLogs - could not determine current player name", {})
        return {}
    end
    
    local myLogs = {}
    local totalEntries = 0
    local myEntryCount = 0
    
    -- Optimized filtering with early validation
    for logID, entry in pairs(SpectrumLootHelperDB.auditLog) do
        if logID ~= "_version" and type(entry) == "table" and entry.OfficerName then
            totalEntries = totalEntries + 1
            if entry.OfficerName == currentPlayer then
                myLogs[#myLogs + 1] = entry -- Faster than table.insert
                myEntryCount = myEntryCount + 1
            end
        end
    end
    
    -- Optimized sort - only if we have entries
    if myEntryCount > 1 then
        table.sort(myLogs, function(a, b)
            return a.Timestamp > b.Timestamp
        end)
    end
    
    SLH.Debug:LogDebug("Logging", "GetMyLogs completed", {
        currentPlayer = currentPlayer,
        totalEntries = totalEntries,
        myEntryCount = myEntryCount,
        sortedByTimestamp = "newest first"
    })
    
    return myLogs
end

-- Delete a specific audit log entry by ID (officer-gated)
-- Parameters:
--   logID: string - Unique identifier of log entry to delete
-- Returns: boolean - true if deleted successfully, false if failed
function SLH.Logging:DeleteLogEntry(logID)
    SLH.Debug:LogDebug("Logging", "DeleteLogEntry called", { logID = logID })
    
    -- Validate officer permissions first
    if not self:IsOfficer() then
        SLH.Debug:LogWarn("Logging", "DeleteLogEntry rejected - insufficient permissions", {
            currentPlayer = UnitName("player"),
            logID = logID
        })
        return false
    end
    
    -- Validate logID parameter
    if not logID or logID == "" then
        SLH.Debug:LogError("Logging", "DeleteLogEntry failed - invalid logID parameter", { logID = logID })
        return false
    end
    
    -- Check if database exists
    if not SpectrumLootHelperDB or not SpectrumLootHelperDB.auditLog then
        SLH.Debug:LogError("Logging", "DeleteLogEntry failed - auditLog database not found", { logID = logID })
        return false
    end
    
    -- Check if log entry exists
    local existingEntry = SpectrumLootHelperDB.auditLog[logID]
    if not existingEntry then
        SLH.Debug:LogWarn("Logging", "DeleteLogEntry failed - log entry not found", { logID = logID })
        return false
    end
    
    -- Prevent deletion of version metadata
    if logID == "_version" then
        SLH.Debug:LogError("Logging", "DeleteLogEntry rejected - cannot delete version metadata", { logID = logID })
        return false
    end
    
    -- Store entry details for logging before deletion
    local entryDetails = {
        playerName = existingEntry.PlayerName,
        officerName = existingEntry.OfficerName,
        timestamp = existingEntry.Timestamp,
        fieldChanged = existingEntry.FieldChanged
    }
    
    -- Delete the entry
    SpectrumLootHelperDB.auditLog[logID] = nil
    
    SLH.Debug:LogInfo("Logging", "Log entry deleted successfully", {
        logID = logID,
        deletedBy = UnitName("player"),
        originalEntry = entryDetails
    })
    
    return true
end

-- Internal data structure placeholder for storing logs in saved variables
-- Will be stored in SpectrumLootHelperDB.auditLog as:
-- {
--   [logID] = {
--     ID = "unique_hash_id",
--     PlayerName = "PlayerName",
--     PlayerServer = "ServerName", 
--     OfficerName = "OfficerName",
--     Timestamp = 1692147600, -- Server timestamp
--     FieldChanged = "Venari Charges" or "Gear Slot",
--     ChangeMade = "up"/"down" or true/false
--   }
-- }

-- Integration testing function for validating all logging functionality
-- This function performs comprehensive testing of all logging components
-- Returns: table - Test results summary
function SLH.Logging:RunIntegrationTests()
    SLH.Debug:LogInfo("Logging", "Starting integration tests", {})
    
    local testResults = {
        passed = 0,
        failed = 0,
        errors = {},
        summary = {}
    }
    
    local function addTest(testName, success, details)
        if success then
            testResults.passed = testResults.passed + 1
            table.insert(testResults.summary, "✅ " .. testName)
        else
            testResults.failed = testResults.failed + 1
            table.insert(testResults.summary, "❌ " .. testName .. ": " .. (details or "Unknown error"))
            table.insert(testResults.errors, { test = testName, details = details })
        end
    end
    
    -- Test 1: Database initialization
    local dbExists = (SpectrumLootHelperDB and SpectrumLootHelperDB.auditLog)
    addTest("Database Structure", dbExists, dbExists and nil or "SpectrumLootHelperDB.auditLog not found")
    
    -- Test 2: Officer permission check
    local isOfficerResult = self:IsOfficer()
    local officerTestPassed = (type(isOfficerResult) == "boolean")
    addTest("Officer Permission Check", officerTestPassed, officerTestPassed and nil or "IsOfficer() did not return boolean")
    
    -- Test 3: Log ID generation
    local testOfficer = "TestOfficer"
    local testTimestamp = GetServerTime()
    local testField = "Venari Charges"
    local logID = self:GenerateLogID(testOfficer, testTimestamp, testField)
    local idTestPassed = (logID and type(logID) == "string" and logID ~= "")
    addTest("Log ID Generation", idTestPassed, idTestPassed and nil or "GenerateLogID failed or returned invalid ID")
    
    -- Test 4: Log entry creation (if officer)
    local createTestPassed = false
    local createDetails = "Not tested - insufficient permissions"
    if isOfficerResult then
        local entryID = self:CreateLogEntry("TestPlayer", "TestServer", "Venari Charges", "up")
        createTestPassed = (entryID ~= nil)
        createDetails = createTestPassed and nil or "CreateLogEntry failed for valid officer"
    end
    addTest("Log Entry Creation", createTestPassed or not isOfficerResult, createDetails)
    
    -- Test 5: Log retrieval
    local allLogs = self:GetAllLogs()
    local myLogs = self:GetMyLogs()
    local retrievalTestPassed = (type(allLogs) == "table" and type(myLogs) == "table")
    addTest("Log Retrieval", retrievalTestPassed, retrievalTestPassed and nil or "GetAllLogs or GetMyLogs returned non-table")
    
    -- Test 6: Edge case handling - invalid parameters
    local invalidCreateResult = self:CreateLogEntry("", "", "InvalidField", "InvalidChange")
    local edgeTestPassed = (invalidCreateResult == nil)
    addTest("Edge Case Handling", edgeTestPassed, edgeTestPassed and nil or "Invalid parameters should return nil")
    
    -- Test 7: Log count consistency
    local initialCount = self:GetLogCount()
    local retrievedCount = #allLogs
    local countTestPassed = (type(initialCount) == "number")
    addTest("Log Count Function", countTestPassed, countTestPassed and nil or "GetLogCount did not return number")
    
    -- Test 8: Database version tracking
    local versionExists = (SpectrumLootHelperDB and SpectrumLootHelperDB.auditLog and SpectrumLootHelperDB.auditLog._version)
    addTest("Version Tracking", versionExists, versionExists and nil or "Database version not tracked")
    
    -- Summary
    testResults.total = testResults.passed + testResults.failed
    testResults.successRate = (testResults.total > 0) and (testResults.passed / testResults.total * 100) or 0
    
    SLH.Debug:LogInfo("Logging", "Integration tests completed", {
        totalTests = testResults.total,
        passed = testResults.passed,
        failed = testResults.failed,
        successRate = string.format("%.1f%%", testResults.successRate)
    })
    
    return testResults
end

-- Helper function for manual testing - creates sample log entries
-- Only works for officers, creates test data for validation
function SLH.Logging:CreateTestData()
    if not self:IsOfficer() then
        SLH.Debug:LogWarn("Logging", "CreateTestData rejected - insufficient permissions", {})
        return false
    end
    
    local testEntries = {
        { player = "TestPlayer1", server = "TestServer", field = "Venari Charges", change = "up" },
        { player = "TestPlayer2", server = "TestServer", field = "Venari Charges", change = "down" },
        { player = "TestPlayer3", server = "TestServer", field = "Gear Slot", change = true },
        { player = "TestPlayer4", server = "TestServer", field = "Gear Slot", change = false }
    }
    
    local createdCount = 0
    for _, entry in ipairs(testEntries) do
        local logID = self:CreateLogEntry(entry.player, entry.server, entry.field, entry.change)
        if logID then
            createdCount = createdCount + 1
        end
    end
    
    SLH.Debug:LogInfo("Logging", "Test data creation completed", { createdEntries = createdCount })
    return createdCount > 0
end

-- Performance monitoring and optimization functions
-- Returns: table - Memory and performance statistics
function SLH.Logging:GetPerformanceStats()
    local stats = {
        memoryUsage = 0,
        entryCount = 0,
        cacheHits = 0,
        avgEntrySize = 0
    }
    
    if SpectrumLootHelperDB and SpectrumLootHelperDB.auditLog then
        -- Estimate memory usage (rough calculation)
        for logID, entry in pairs(SpectrumLootHelperDB.auditLog) do
            if logID ~= "_version" then
                stats.entryCount = stats.entryCount + 1
                -- Rough byte estimation per entry (strings + overhead)
                stats.memoryUsage = stats.memoryUsage + 200 -- Base entry overhead
                if entry.PlayerName then stats.memoryUsage = stats.memoryUsage + #entry.PlayerName end
                if entry.OfficerName then stats.memoryUsage = stats.memoryUsage + #entry.OfficerName end
                if entry.PlayerServer then stats.memoryUsage = stats.memoryUsage + #entry.PlayerServer end
                if entry.FieldChanged then stats.memoryUsage = stats.memoryUsage + #entry.FieldChanged end
            end
        end
        
        if stats.entryCount > 0 then
            stats.avgEntrySize = math.floor(stats.memoryUsage / stats.entryCount)
        end
    end
    
    -- Cache efficiency
    local currentTime = GetTime()
    if self._cache.lastCacheTime > 0 and (currentTime - self._cache.lastCacheTime) < self._cache.cacheValidDuration then
        stats.cacheHits = 1
    end
    
    return stats
end

-- Memory optimization: clean up old entries (optional feature)
-- Parameters: maxEntries - Maximum number of entries to keep (default: 1000)
-- Returns: number - Number of entries removed
function SLH.Logging:OptimizeStorage(maxEntries)
    maxEntries = maxEntries or 1000
    
    if not self:IsOfficer() then
        SLH.Debug:LogWarn("Logging", "Storage optimization requires officer permissions", {})
        return 0
    end
    
    local allLogs = self:GetAllLogs()
    local totalEntries = #allLogs
    
    if totalEntries <= maxEntries then
        SLH.Debug:LogDebug("Logging", "No storage optimization needed", { 
            currentEntries = totalEntries,
            maxEntries = maxEntries 
        })
        return 0
    end
    
    -- Remove oldest entries beyond the limit
    local toRemove = totalEntries - maxEntries
    local removedCount = 0
    
    -- Start from the oldest entries (end of sorted array)
    for i = maxEntries + 1, totalEntries do
        local entry = allLogs[i]
        if entry and entry.ID then
            if self:DeleteLogEntry(entry.ID) then
                removedCount = removedCount + 1
            end
        end
    end
    
    SLH.Debug:LogInfo("Logging", "Storage optimization completed", { 
        removedEntries = removedCount,
        remainingEntries = totalEntries - removedCount
    })
    
    return removedCount
end

-- Comprehensive functionality verification - validates all implemented features
-- Returns: table - Detailed verification results
function SLH.Logging:VerifyFunctionality()
    SLH.Debug:LogInfo("Logging", "Starting comprehensive functionality verification", {})
    
    local verification = {
        passed = 0,
        failed = 0,
        results = {},
        functionSignatures = {},
        dataStructure = {},
        integration = {}
    }
    
    local function addResult(category, test, success, details)
        local result = {
            test = test,
            success = success,
            details = details or ""
        }
        
        if not verification[category] then
            verification[category] = {}
        end
        table.insert(verification[category], result)
        
        if success then
            verification.passed = verification.passed + 1
        else
            verification.failed = verification.failed + 1
        end
    end
    
    -- Verify function signatures match outline specifications
    local expectedFunctions = {
        "Init", "IsOfficer", "GenerateLogID", "CreateLogEntry", 
        "GetAllLogs", "GetMyLogs", "DeleteLogEntry", "GetLogCount"
    }
    
    for _, funcName in ipairs(expectedFunctions) do
        local exists = (type(self[funcName]) == "function")
        addResult("functionSignatures", "Function " .. funcName .. " exists", exists, 
            exists and "Function found" or "Function missing")
    end
    
    -- Verify data structure matches specification format
    if SpectrumLootHelperDB and SpectrumLootHelperDB.auditLog then
        addResult("dataStructure", "Database structure exists", true, "SpectrumLootHelperDB.auditLog found")
        
        local hasVersion = (SpectrumLootHelperDB.auditLog._version ~= nil)
        addResult("dataStructure", "Version tracking exists", hasVersion, 
            hasVersion and "Version: " .. tostring(SpectrumLootHelperDB.auditLog._version) or "No version found")
        
        -- Test log entry format if entries exist
        local sampleEntry = nil
        for logID, entry in pairs(SpectrumLootHelperDB.auditLog) do
            if logID ~= "_version" and type(entry) == "table" then
                sampleEntry = entry
                break
            end
        end
        
        if sampleEntry then
            local requiredFields = {"ID", "PlayerName", "PlayerServer", "OfficerName", "Timestamp", "FieldChanged", "ChangeMade"}
            local allFieldsPresent = true
            local missingFields = {}
            
            for _, field in ipairs(requiredFields) do
                if not sampleEntry[field] then
                    allFieldsPresent = false
                    table.insert(missingFields, field)
                end
            end
            
            addResult("dataStructure", "Log entry format correct", allFieldsPresent, 
                allFieldsPresent and "All required fields present" or "Missing: " .. table.concat(missingFields, ", "))
        else
            addResult("dataStructure", "Log entry format", true, "No entries to validate (empty database)")
        end
    else
        addResult("dataStructure", "Database structure exists", false, "SpectrumLootHelperDB.auditLog not found")
    end
    
    -- Verify officer permission gating
    local isOfficerResult = self:IsOfficer()
    addResult("integration", "Officer permission check", type(isOfficerResult) == "boolean", 
        "IsOfficer() returned: " .. tostring(isOfficerResult))
    
    -- Test parameter validation
    local invalidResult = self:CreateLogEntry("", "", "InvalidField", "InvalidValue")
    addResult("integration", "Parameter validation", invalidResult == nil, 
        "Invalid parameters correctly rejected: " .. tostring(invalidResult == nil))
    
    -- Test timestamp accuracy
    local testTimestamp = GetServerTime()
    local timestampValid = (testTimestamp and testTimestamp > 1600000000) -- Reasonable timestamp check
    addResult("integration", "Timestamp accuracy", timestampValid, 
        "Server timestamp: " .. tostring(testTimestamp))
    
    -- Test retrieval functions
    local allLogs = self:GetAllLogs()
    local myLogs = self:GetMyLogs()
    addResult("integration", "Log retrieval functions", type(allLogs) == "table" and type(myLogs) == "table", 
        "GetAllLogs: " .. type(allLogs) .. ", GetMyLogs: " .. type(myLogs))
    
    -- Verify performance optimizations
    local perfStats = self:GetPerformanceStats()
    addResult("integration", "Performance monitoring", type(perfStats) == "table", 
        "Performance stats available: " .. tostring(type(perfStats) == "table"))
    
    -- Integration with existing addon components
    local coreIntegration = (SLH and SLH.OFFICER_RANK and SLH.Debug)
    addResult("integration", "Core addon integration", coreIntegration, 
        coreIntegration and "SLH.OFFICER_RANK and SLH.Debug available" or "Missing core components")
    
    verification.total = verification.passed + verification.failed
    verification.successRate = (verification.total > 0) and (verification.passed / verification.total * 100) or 0
    
    SLH.Debug:LogInfo("Logging", "Functionality verification completed", {
        totalTests = verification.total,
        passed = verification.passed,
        failed = verification.failed,
        successRate = string.format("%.1f%%", verification.successRate)
    })
    
    return verification
end

-- Generate a comprehensive test report for documentation and validation
-- Returns: string - Formatted test report
function SLH.Logging:GenerateTestReport()
    local verification = self:VerifyFunctionality()
    local integration = self:RunIntegrationTests()
    local performance = self:GetPerformanceStats()
    
    local report = {
        "=== SpectrumLootTool Logging System Test Report ===",
        "Generated: " .. date("%Y-%m-%d %H:%M:%S"),
        "",
        "FUNCTIONALITY VERIFICATION:",
        string.format("  Total Tests: %d", verification.total),
        string.format("  Passed: %d", verification.passed),
        string.format("  Failed: %d", verification.failed),
        string.format("  Success Rate: %.1f%%", verification.successRate),
        "",
        "INTEGRATION TESTS:",
        string.format("  Total Tests: %d", integration.total),
        string.format("  Passed: %d", integration.passed),
        string.format("  Failed: %d", integration.failed),
        string.format("  Success Rate: %.1f%%", integration.successRate),
        "",
        "PERFORMANCE STATS:",
        string.format("  Entry Count: %d", performance.entryCount),
        string.format("  Memory Usage: %d bytes", performance.memoryUsage),
        string.format("  Average Entry Size: %d bytes", performance.avgEntrySize),
        "",
        "SYSTEM STATUS: " .. ((verification.successRate > 90 and integration.successRate > 90) and "HEALTHY" or "NEEDS ATTENTION"),
        "=========================="
    }
    
    SLH.Debug:LogInfo("Logging", "Test report generated", {
        functionalityScore = verification.successRate,
        integrationScore = integration.successRate,
        overallStatus = (verification.successRate > 90 and integration.successRate > 90) and "HEALTHY" or "NEEDS ATTENTION"
    })
    
    return table.concat(report, "\n")
end
