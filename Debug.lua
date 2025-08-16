local ADDON_NAME, SLH = ...

-- Debug logging module for session-based debugging and bug reporting
SLH.Debug = {
    version = "1.0", -- Debug system version
    enabled = false, -- Debug logging enabled/disabled
    sessionStartTime = nil, -- Session start timestamp
    logBuffer = {}, -- In-memory log buffer for current session
    maxLogEntries = 1000, -- Maximum log entries to retain in memory
    logFilePath = "SpectrumLootTool_Debug.log", -- Debug log file name
}

-- Internal helper function to serialize log data for file output
function SLH.Debug:_SerializeLogData(data)
    -- Convert log data table to readable string format
    -- Handles nested tables, arrays, and various data types safely
    
    if data == nil then
        return nil
    end
    
    if type(data) ~= "table" then
        return tostring(data)
    end
    
    -- Use pcall to handle any serialization errors gracefully
    local success, result = pcall(function()
        local parts = {}
        
        -- Handle table serialization with depth limit to prevent infinite recursion
        local function serializeValue(value, depth)
            depth = depth or 0
            if depth > 3 then -- Limit depth to prevent stack overflow
                return "..."
            end
            
            if type(value) == "table" then
                local tableParts = {}
                local count = 0
                for k, v in pairs(value) do
                    count = count + 1
                    if count > 10 then -- Limit number of entries
                        table.insert(tableParts, "...")
                        break
                    end
                    local keyStr = type(k) == "string" and k or tostring(k)
                    local valueStr = serializeValue(v, depth + 1)
                    table.insert(tableParts, keyStr .. "=" .. valueStr)
                end
                return "{" .. table.concat(tableParts, ", ") .. "}"
            elseif type(value) == "string" then
                return "\"" .. value .. "\""
            else
                return tostring(value)
            end
        end
        
        for k, v in pairs(data) do
            local keyStr = type(k) == "string" and k or tostring(k)
            local valueStr = serializeValue(v)
            table.insert(parts, keyStr .. "=" .. valueStr)
        end
        
        return table.concat(parts, ", ")
    end)
    
    if success then
        return result
    else
        return "serialization_error"
    end
end

-- Initialize the debug system
function SLH.Debug:Init()
    -- Ensure saved variables structure exists (SpectrumLootHelperDB is initialized in Core.lua)
    if SpectrumLootHelperDB then
        SpectrumLootHelperDB.debug = SpectrumLootHelperDB.debug or {}
        
        -- Initialize debug state from saved variables or defaults
        if SpectrumLootHelperDB.debug.enabled ~= nil then
            self.enabled = SpectrumLootHelperDB.debug.enabled
        else
            self.enabled = false -- Default to disabled
            SpectrumLootHelperDB.debug.enabled = self.enabled
        end
    else
        -- Fallback if saved variables not yet available
        self.enabled = false
    end
    
    -- Initialize memory buffer as empty array
    self.logBuffer = {}
    
    -- Set session start time (will be updated on StartSession)
    self.sessionStartTime = GetServerTime()
    
    -- Validate and set up log file path
    local addonPath = "Interface\\AddOns\\SpectrumLootTool\\"
    self.logFilePath = addonPath .. "SpectrumLootTool_Debug.log"
    
    -- Initialize memory structures for tracking stats
    self.stats = {
        totalLogEntries = 0,
        logEntriesByLevel = {},
        logEntriesByComponent = {}
    }
    
    -- Log the initialization (only if already enabled)
    if self.enabled then
        self:LogInfo("Debug", "Debug system initialized", {
            version = self.version,
            maxLogEntries = self.maxLogEntries,
            logFilePath = self.logFilePath,
            sessionStartTime = self.sessionStartTime
        })
    end
end

-- Start a new debug session (called on PLAYER_LOGIN)
function SLH.Debug:StartSession()
    -- Record new session start time
    self.sessionStartTime = GetServerTime()
    
    -- Reset in-memory log buffer to start fresh
    self.logBuffer = {}
    
    -- Initialize or reset session statistics
    self.stats = self.stats or {}
    self.stats.totalLogEntries = 0
    self.stats.logEntriesByLevel = {}
    self.stats.logEntriesByComponent = {}
    
    -- Note: In WoW's limited file system environment, we cannot directly delete files
    -- File cleanup will be handled implicitly by overwriting on FlushToFile()
    -- Previous session data persists only until new data is written
    
    -- Log the session start event (only if debug logging is enabled)
    if self:IsEnabled() then
        self:LogInfo("Debug", "New debug session started", {
            sessionStartTime = self.sessionStartTime,
            wowBuild = select(4, GetBuildInfo()),
            wowVersion = GetBuildInfo(),
            playerName = UnitName("player"),
            realmName = GetRealmName(),
            addonVersion = SLH.version or "unknown"
        })
    end
end

-- Enable or disable debug logging
function SLH.Debug:SetEnabled(enabled)
    -- Validate input parameter
    if type(enabled) ~= "boolean" then
        error("SetEnabled expects a boolean parameter, got " .. type(enabled))
        return
    end
    
    local oldState = self.enabled
    self.enabled = enabled
    
    -- Update saved variables for persistence
    if SpectrumLootHelperDB and SpectrumLootHelperDB.debug then
        SpectrumLootHelperDB.debug.enabled = enabled
    end
    
    -- Log the state change (only if transitioning to enabled or was previously enabled)
    if enabled or oldState then
        local action = enabled and "enabled" or "disabled"
        self:LogInfo("Debug", "Debug logging " .. action, {
            previousState = oldState,
            newState = enabled,
            timestamp = GetServerTime()
        })
    end
    
    -- Provide user feedback
    if enabled and not oldState then
        -- Transitioning from disabled to enabled
        print("|cFF00FF00[Spectrum Loot Helper]|r Debug logging enabled. Use /slh debuglog commands to manage logs.")
    elseif not enabled and oldState then
        -- Transitioning from enabled to disabled  
        print("|cFFFFAA00[Spectrum Loot Helper]|r Debug logging disabled.")
    end
    -- No feedback for no-change cases (enabled->enabled or disabled->disabled)
end

-- Check if debug logging is currently enabled
function SLH.Debug:IsEnabled()
    -- Fast, reliable state check for debug logging status
    -- Returns: boolean, true if debug logging is enabled
    -- 
    -- This function is designed for high-frequency calls throughout the system
    -- and provides a consistent interface for state checking
    
    -- Ensure enabled state is always a boolean (defensive programming)
    if type(self.enabled) ~= "boolean" then
        -- Fallback to false if state is corrupted, but don't error
        self.enabled = false
    end
    
    return self.enabled
end

-- Log a debug message with timestamp and context
function SLH.Debug:Log(level, component, message, data)
    -- Performance optimization: Skip entirely if debug logging is disabled
    if not self:IsEnabled() then
        return
    end
    
    -- Parameter validation
    if type(level) ~= "string" or level == "" then
        error("Log() requires a valid level string")
        return
    end
    if type(component) ~= "string" or component == "" then
        error("Log() requires a valid component string")
        return
    end
    if type(message) ~= "string" or message == "" then
        error("Log() requires a valid message string")
        return
    end
    
    -- Ensure log buffer exists
    self.logBuffer = self.logBuffer or {}
    
    -- Generate timestamps
    local currentTime = GetServerTime()
    local sessionTime = self.sessionStartTime and (currentTime - self.sessionStartTime) or 0
    
    -- Create log entry
    local logEntry = {
        timestamp = currentTime,
        sessionTime = sessionTime,
        level = level:upper(), -- Normalize to uppercase
        component = component,
        message = message,
        data = data -- Optional, can be nil or table
    }
    
    -- Add to memory buffer
    table.insert(self.logBuffer, logEntry)
    
    -- Memory management: Enforce maximum log entries (FIFO)
    if #self.logBuffer > self.maxLogEntries then
        table.remove(self.logBuffer, 1) -- Remove oldest entry
    end
    
    -- Update statistics
    self:_UpdateStats(logEntry)
end

-- Convenience functions for different log levels
function SLH.Debug:LogInfo(component, message, data)
    -- Type-safe wrapper for INFO level logging
    -- Validates parameters and provides consistent interface
    if type(component) ~= "string" or component == "" then
        error("LogInfo() requires a valid component string")
        return
    end
    if type(message) ~= "string" or message == "" then
        error("LogInfo() requires a valid message string") 
        return
    end
    
    self:Log("INFO", component, message, data)
end

function SLH.Debug:LogWarn(component, message, data)
    -- Type-safe wrapper for WARN level logging
    -- Used for warnings that don't halt execution but indicate potential issues
    if type(component) ~= "string" or component == "" then
        error("LogWarn() requires a valid component string")
        return
    end
    if type(message) ~= "string" or message == "" then
        error("LogWarn() requires a valid message string")
        return
    end
    
    self:Log("WARN", component, message, data)
end

function SLH.Debug:LogError(component, message, data)
    -- Type-safe wrapper for ERROR level logging
    -- Used for errors that affect functionality but don't crash the addon
    if type(component) ~= "string" or component == "" then
        error("LogError() requires a valid component string")
        return
    end
    if type(message) ~= "string" or message == "" then
        error("LogError() requires a valid message string")
        return
    end
    
    self:Log("ERROR", component, message, data)
end

function SLH.Debug:LogDebug(component, message, data)
    -- Type-safe wrapper for DEBUG level logging (most verbose)
    -- Used for detailed debugging information, typically filtered out in production
    if type(component) ~= "string" or component == "" then
        error("LogDebug() requires a valid component string")
        return
    end
    if type(message) ~= "string" or message == "" then
        error("LogDebug() requires a valid message string")
        return
    end
    
    self:Log("DEBUG", component, message, data)
end

-- Get current session debug logs
function SLH.Debug:GetSessionLogs(level, component, count)
    -- Filter and retrieve logs from memory buffer
    -- Parameters:
    -- - level: string, optional filter by log level (e.g., "INFO", "ERROR")
    -- - component: string, optional filter by component (e.g., "Core", "UI")
    -- - count: number, optional limit number of entries returned (default: all)
    -- Returns: array of log entries, most recent first
    
    -- Performance optimization: Early exit if no logs or debug disabled
    if not self.logBuffer or #self.logBuffer == 0 then
        return {}
    end
    
    -- Parameter validation and normalization
    if level and type(level) ~= "string" then
        error("GetSessionLogs() level parameter must be string or nil")
        return {}
    end
    if component and type(component) ~= "string" then
        error("GetSessionLogs() component parameter must be string or nil")
        return {}
    end
    if count and (type(count) ~= "number" or count < 0) then
        error("GetSessionLogs() count parameter must be positive number or nil")
        return {}
    end
    
    -- Normalize level to uppercase for consistent filtering
    local filterLevel = level and level:upper() or nil
    
    -- Apply filters and collect matching entries
    local filteredLogs = {}
    
    -- Iterate through log buffer (already in chronological order)
    for i, logEntry in ipairs(self.logBuffer) do
        local includeEntry = true
        
        -- Apply level filter if specified
        if filterLevel and logEntry.level ~= filterLevel then
            includeEntry = false
        end
        
        -- Apply component filter if specified
        if includeEntry and component and logEntry.component ~= component then
            includeEntry = false
        end
        
        -- Add entry if it passes all filters
        if includeEntry then
            -- Create a copy to prevent external modification of internal data
            local entryCopy = {
                timestamp = logEntry.timestamp,
                sessionTime = logEntry.sessionTime,
                level = logEntry.level,
                component = logEntry.component,
                message = logEntry.message,
                data = logEntry.data -- Note: This maintains reference to original data table
            }
            table.insert(filteredLogs, entryCopy)
        end
    end
    
    -- Sort results: Most recent entries first (reverse chronological order)
    table.sort(filteredLogs, function(a, b)
        return a.timestamp > b.timestamp
    end)
    
    -- Apply count limit if specified
    if count and count > 0 and #filteredLogs > count then
        local limitedLogs = {}
        for i = 1, count do
            table.insert(limitedLogs, filteredLogs[i])
        end
        filteredLogs = limitedLogs
    end
    
    -- Performance logging for debugging the debug system itself
    if self:IsEnabled() and (filterLevel or component or count) then
        self:LogDebug("Debug", "Session logs retrieved with filters", {
            originalCount = #self.logBuffer,
            filteredCount = #filteredLogs,
            levelFilter = filterLevel,
            componentFilter = component,
            countLimit = count
        })
    end
    
    return filteredLogs
end

-- Write current log buffer to file
function SLH.Debug:FlushToFile()
    -- Early exit if no logs to flush
    if not self.logBuffer or #self.logBuffer == 0 then
        return false, "No logs to flush"
    end
    
    -- Early exit if logging is disabled (shouldn't have logs, but defensive programming)
    if not self:IsEnabled() then
        return false, "Debug logging is disabled"
    end
    
    -- Note: WoW's Lua environment has severely limited file I/O capabilities
    -- AddOns cannot directly write to arbitrary files due to security restrictions
    -- However, we can use alternative approaches for log persistence:
    
    -- Approach 1: Use WoW's saved variables system for persistence
    -- This data will be saved to SavedVariables automatically by WoW
    local success, errorMsg = pcall(function()
        -- Ensure saved variables structure exists
        SpectrumLootHelperDB = SpectrumLootHelperDB or {}
        SpectrumLootHelperDB.debugLogs = SpectrumLootHelperDB.debugLogs or {}
        
        -- Format logs for saved variables storage
        local formattedLogs = {}
        for i, entry in ipairs(self.logBuffer) do
            local formattedEntry = string.format(
                "[%s +%ds] %s/%s: %s",
                date("%Y-%m-%d %H:%M:%S", entry.timestamp),
                entry.sessionTime,
                entry.level,
                entry.component,
                entry.message
            )
            
            -- Add data context if present
            if entry.data then
                local dataStr = self:_SerializeLogData(entry.data)
                if dataStr then
                    formattedEntry = formattedEntry .. " | Data: " .. dataStr
                end
            end
            
            table.insert(formattedLogs, formattedEntry)
        end
        
        -- Store formatted logs with session metadata
        SpectrumLootHelperDB.debugLogs = {
            sessionStart = self.sessionStartTime,
            lastFlush = GetServerTime(),
            wowVersion = GetBuildInfo(),
            addonVersion = SLH.version or "unknown",
            logCount = #formattedLogs,
            logs = formattedLogs
        }
    end)
    
    if not success then
        -- Log the flush error (but avoid infinite recursion)
        print("|cFFFF0000[Spectrum Loot Helper]|r Failed to flush debug logs: " .. (errorMsg or "unknown error"))
        return false, errorMsg or "Flush operation failed"
    end
    
    -- Log successful flush operation
    self:LogInfo("Debug", "Debug logs flushed to saved variables", {
        logCount = #self.logBuffer,
        flushTime = GetServerTime(),
        method = "saved_variables"
    })
    
    return true, "Logs successfully flushed to saved variables"
end

-- Get debug log file path and status
function SLH.Debug:GetLogFileInfo()
    -- File path management and status checking for debug log file
    -- Returns table with file information for session management and UI display
    -- Dependencies: Init() for file path setup
    
    local fileInfo = {
        path = self.logFilePath,
        exists = false,
        size = 0,
        lastModified = nil,
        readable = false,
        directory = nil
    }
    
    -- Extract directory path for validation
    if self.logFilePath then
        local lastSlash = self.logFilePath:find("\\[^\\]*$")
        if lastSlash then
            fileInfo.directory = self.logFilePath:sub(1, lastSlash - 1)
        end
    end
    
    -- Note: WoW's Lua environment has limited file system access
    -- File existence and size checking would typically be done through:
    -- 1. WoW's saved variables system for persistence
    -- 2. Addon-specific file operations during write operations
    -- 3. Manual tracking of file state through session management
    
    -- For now, we'll track file state through our session management
    -- Real file operations will be handled in FlushToFile() and StartSession()
    
    -- Check if we have any logs in memory buffer (indicates active logging)
    if self.logBuffer and #self.logBuffer > 0 then
        fileInfo.exists = true
        -- Estimate size based on memory buffer content
        local estimatedSize = 0
        for _, entry in ipairs(self.logBuffer) do
            -- Rough estimate: timestamp(20) + level(8) + component(20) + message(100) + overhead(50)
            estimatedSize = estimatedSize + 200
        end
        fileInfo.size = estimatedSize
        fileInfo.readable = true
        
        -- Use session start time as proxy for last modified
        fileInfo.lastModified = self.sessionStartTime
    end
    
    -- Validate file path structure
    if not self.logFilePath or self.logFilePath == "" then
        fileInfo.path = nil
        fileInfo.directory = nil
    end
    
    return fileInfo
end

-- Clear current session logs (memory and file)
function SLH.Debug:ClearLogs()
    -- Store previous counts for user feedback
    local previousLogCount = #self.logBuffer
    local wasEnabled = self:IsEnabled()
    
    -- Clear in-memory log buffer
    self.logBuffer = {}
    
    -- Reset session statistics
    if self.stats then
        self.stats.totalLogEntries = 0
        self.stats.logEntriesByLevel = {}
        self.stats.logEntriesByComponent = {}
    end
    
    -- Note: In WoW's limited file system environment, we cannot directly delete files
    -- File clearing will be handled implicitly when new data is written via FlushToFile()
    -- This maintains the same approach as StartSession() for consistency
    
    -- Log the clear action (if enabled and there were logs to clear)
    if wasEnabled and previousLogCount > 0 then
        self:LogInfo("Debug", "Debug logs manually cleared", {
            previousLogCount = previousLogCount,
            clearedAt = GetServerTime(),
            clearedBy = "manual_action"
        })
    end
    
    -- Notify user of action with appropriate feedback
    if previousLogCount > 0 then
        print("|cFFFFAA00[Spectrum Loot Helper]|r Debug logs cleared (" .. previousLogCount .. " entries removed).")
    else
        print("|cFF808080[Spectrum Loot Helper]|r No debug logs to clear.")
    end
end

-- Display debug logs in chat window
-- Display debug logs in chat window
function SLH.Debug:DisplayLogsInChat(level, component, count)
    -- Show debug logs in WoW chat window
    -- Parameters:
    -- - level: string, optional filter by log level
    -- - component: string, optional filter by component  
    -- - count: number, optional limit number of entries (default 10)
    -- Dependencies: GetSessionLogs() for data retrieval
    -- Focus: Chat formatting, color coding, pagination
    
    -- Set default count if not specified
    local displayCount = count or 10
    
    -- Parameter validation
    if level and type(level) ~= "string" then
        print("|cFFFF0000[Spectrum Loot Helper]|r Error: level must be a string")
        return
    end
    if component and type(component) ~= "string" then
        print("|cFFFF0000[Spectrum Loot Helper]|r Error: component must be a string")
        return
    end
    if displayCount and (type(displayCount) ~= "number" or displayCount <= 0) then
        print("|cFFFF0000[Spectrum Loot Helper]|r Error: count must be a positive number")
        return
    end
    
    -- Early exit if debug logging is disabled
    if not self:IsEnabled() then
        print("|cFFFFAA00[Spectrum Loot Helper]|r Debug logging is disabled. Use /slh debuglog enable to turn it on.")
        return
    end
    
    -- Retrieve filtered logs using existing GetSessionLogs function
    local logs = self:GetSessionLogs(level, component, displayCount)
    
    -- Check if any logs were found
    if not logs or #logs == 0 then
        local filterText = ""
        if level or component then
            local filters = {}
            if level then table.insert(filters, "level=" .. level) end
            if component then table.insert(filters, "component=" .. component) end
            filterText = " (filtered by " .. table.concat(filters, ", ") .. ")"
        end
        print("|cFF808080[Spectrum Loot Helper]|r No debug logs found" .. filterText .. ".")
        return
    end
    
    -- Display header with filter information
    local headerText = "|cFF00FF00[Spectrum Loot Helper]|r Debug Logs"
    if level or component then
        local filters = {}
        if level then table.insert(filters, "Level: " .. level) end
        if component then table.insert(filters, "Component: " .. component) end
        headerText = headerText .. " |cFF808080(" .. table.concat(filters, ", ") .. ")|r"
    end
    headerText = headerText .. " |cFF808080- Showing " .. #logs .. " entries|r"
    print(headerText)
    print("|cFF808080" .. string.rep("-", 60) .. "|r")
    
    -- Display each log entry with appropriate color coding
    for i, logEntry in ipairs(logs) do
        local formattedEntry = self:_FormatLogEntryForChat(logEntry)
        print(formattedEntry)
    end
    
    -- Display footer with pagination info
    local totalLogs = #self.logBuffer
    if #logs < totalLogs then
        local remaining = totalLogs - #logs
        print("|cFF808080" .. string.rep("-", 60) .. "|r")
        print("|cFF808080[Spectrum Loot Helper]|r " .. remaining .. " more entries available. Use count parameter to see more.")
    end
    
    -- Log the display action (without creating recursion)
    if not self._displayingLogs then
        self._displayingLogs = true
        self:LogDebug("Debug", "Debug logs displayed in chat", {
            entriesShown = #logs,
            totalEntries = totalLogs,
            levelFilter = level,
            componentFilter = component,
            displayCount = displayCount
        })
        self._displayingLogs = false
    end
end

-- Get debug system statistics
function SLH.Debug:GetStats()
    -- Provide debug system health and usage information
    -- Returns comprehensive statistics about the debug system state and performance
    -- Dependencies: All logging functions for comprehensive stats
    -- Focus: Memory usage calculation, categorization, performance metrics
    
    -- Ensure stats structure exists (defensive programming)
    self.stats = self.stats or {
        totalLogEntries = 0,
        logEntriesByLevel = {},
        logEntriesByComponent = {}
    }
    
    -- Calculate session duration
    local currentTime = GetServerTime()
    local sessionDuration = 0
    if self.sessionStartTime then
        sessionDuration = currentTime - self.sessionStartTime
    end
    
    -- Recalculate real-time statistics from current log buffer
    local realTimeStats = {
        totalLogEntries = 0,
        logEntriesByLevel = {},
        logEntriesByComponent = {}
    }
    
    -- Calculate estimated memory usage
    local estimatedMemoryUsage = 0
    
    if self.logBuffer then
        realTimeStats.totalLogEntries = #self.logBuffer
        
        -- Process each log entry for categorization and memory estimation
        for _, logEntry in ipairs(self.logBuffer) do
            -- Count by level
            local level = logEntry.level or "UNKNOWN"
            realTimeStats.logEntriesByLevel[level] = (realTimeStats.logEntriesByLevel[level] or 0) + 1
            
            -- Count by component
            local component = logEntry.component or "UNKNOWN"
            realTimeStats.logEntriesByComponent[component] = (realTimeStats.logEntriesByComponent[component] or 0) + 1
            
            -- Estimate memory usage per entry
            -- Base structure: timestamp(8) + sessionTime(8) + level(string) + component(string) + message(string)
            local entrySize = 16 -- Base numbers
            entrySize = entrySize + (logEntry.level and #logEntry.level or 0)
            entrySize = entrySize + (logEntry.component and #logEntry.component or 0)
            entrySize = entrySize + (logEntry.message and #logEntry.message or 0)
            
            -- Estimate data table size (if present)
            if logEntry.data then
                entrySize = entrySize + self:_EstimateDataSize(logEntry.data)
            end
            
            estimatedMemoryUsage = estimatedMemoryUsage + entrySize
        end
    end
    
    -- Calculate file size from saved variables (if available)
    local fileSize = 0
    if SpectrumLootHelperDB and SpectrumLootHelperDB.debugLogs and SpectrumLootHelperDB.debugLogs.logs then
        -- Estimate size based on saved logs
        for _, logString in ipairs(SpectrumLootHelperDB.debugLogs.logs) do
            fileSize = fileSize + #logString + 1 -- +1 for newline
        end
    end
    
    -- Get file information
    local fileInfo = self:GetLogFileInfo()
    
    -- Calculate performance metrics
    local averageLogsPerMinute = 0
    if sessionDuration > 0 then
        averageLogsPerMinute = (realTimeStats.totalLogEntries * 60) / sessionDuration
    end
    
    -- Build comprehensive statistics table
    local stats = {
        -- Session information
        sessionStartTime = self.sessionStartTime,
        sessionDuration = sessionDuration,
        sessionDurationFormatted = self:_FormatDuration(sessionDuration),
        
        -- Log counts and categorization
        totalLogEntries = realTimeStats.totalLogEntries,
        logEntriesByLevel = realTimeStats.logEntriesByLevel,
        logEntriesByComponent = realTimeStats.logEntriesByComponent,
        
        -- Memory and storage metrics
        memoryUsage = estimatedMemoryUsage,
        memoryUsageFormatted = self:_FormatBytes(estimatedMemoryUsage),
        fileSize = fileSize,
        fileSizeFormatted = self:_FormatBytes(fileSize),
        maxLogEntries = self.maxLogEntries,
        bufferUtilization = self.maxLogEntries > 0 and (realTimeStats.totalLogEntries / self.maxLogEntries) or 0,
        
        -- System state
        enabled = self.enabled,
        version = self.version,
        logFilePath = self.logFilePath,
        
        -- Performance metrics
        averageLogsPerMinute = averageLogsPerMinute,
        
        -- File information
        fileExists = fileInfo.exists,
        fileReadable = fileInfo.readable,
        
        -- System context
        wowVersion = GetBuildInfo(),
        addonVersion = SLH.version or "unknown",
        playerName = UnitName("player"),
        realmName = GetRealmName(),
        
        -- Timestamps for reporting
        statsGeneratedAt = currentTime,
        statsGeneratedAtFormatted = date("%Y-%m-%d %H:%M:%S", currentTime)
    }
    
    -- Add debug logging for stats generation (if enabled and not generating recursion)
    if self:IsEnabled() then
        -- Use a simple flag to prevent infinite recursion during stats generation
        if not self._generatingStats then
            self._generatingStats = true
            self:LogDebug("Debug", "System statistics generated", {
                totalEntries = stats.totalLogEntries,
                memoryUsage = stats.memoryUsageFormatted,
                sessionDuration = stats.sessionDurationFormatted,
                bufferUtilization = string.format("%.1f%%", stats.bufferUtilization * 100)
            })
            self._generatingStats = false
        end
    end
    
    return stats
end

-- Internal helper function to format a log entry for chat display
function SLH.Debug:_FormatLogEntryForChat(logEntry)
    -- Format a single log entry for display in WoW chat window
    -- Applies color coding by log level and formats timestamps appropriately
    
    if not logEntry then
        return "|cFFFF0000[DEBUG]|r Invalid log entry"
    end
    
    -- Color coding by log level
    local levelColors = {
        ERROR = "|cFFFF0000",   -- Red
        WARN  = "|cFFFFAA00",   -- Orange
        INFO  = "|cFF00FF00",   -- Green
        DEBUG = "|cFF808080"    -- Gray
    }
    
    local levelColor = levelColors[logEntry.level] or "|cFFFFFFFF" -- White fallback
    local resetColor = "|r"
    
    -- Format session time for readability
    local sessionTimeStr = ""
    if logEntry.sessionTime and logEntry.sessionTime >= 0 then
        if logEntry.sessionTime < 60 then
            sessionTimeStr = string.format("+%ds", logEntry.sessionTime)
        elseif logEntry.sessionTime < 3600 then
            local minutes = math.floor(logEntry.sessionTime / 60)
            local seconds = logEntry.sessionTime % 60
            sessionTimeStr = string.format("+%dm%ds", minutes, seconds)
        else
            local hours = math.floor(logEntry.sessionTime / 3600)
            local minutes = math.floor((logEntry.sessionTime % 3600) / 60)
            sessionTimeStr = string.format("+%dh%dm", hours, minutes)
        end
    end
    
    -- Format component with fixed width for alignment
    local componentStr = logEntry.component or "UNKNOWN"
    if #componentStr > 8 then
        componentStr = componentStr:sub(1, 7) .. "+"
    else
        componentStr = componentStr .. string.rep(" ", 8 - #componentStr)
    end
    
    -- Build the formatted message
    local formattedMsg = string.format(
        "%s[%s]%s %s%s%s %s%s%s: %s",
        levelColor,
        logEntry.level or "UNKNOWN",
        resetColor,
        "|cFF808080",
        sessionTimeStr,
        resetColor,
        "|cFF606060",
        componentStr,
        resetColor,
        logEntry.message or "No message"
    )
    
    -- Add data context if present (limit length to prevent chat spam)
    if logEntry.data then
        local dataStr = self:_SerializeLogData(logEntry.data)
        if dataStr and #dataStr > 0 then
            -- Limit data display to prevent chat flooding
            if #dataStr > 100 then
                dataStr = dataStr:sub(1, 97) .. "..."
            end
            formattedMsg = formattedMsg .. " |cFF404040| " .. dataStr .. resetColor
        end
    end
    
    return formattedMsg
end

-- Internal helper function to estimate memory usage of data tables
function SLH.Debug:_EstimateDataSize(data)
    -- Estimate memory usage of a data table (in bytes)
    -- Uses recursive traversal with depth limiting to prevent infinite loops
    
    if data == nil then
        return 0
    end
    
    if type(data) ~= "table" then
        -- Estimate size for primitive types
        if type(data) == "string" then
            return #data
        elseif type(data) == "number" then
            return 8 -- Assume 64-bit numbers
        elseif type(data) == "boolean" then
            return 1
        else
            return 8 -- Unknown types, assume pointer size
        end
    end
    
    -- Handle table estimation with depth limiting
    local function estimateTableSize(tbl, depth)
        depth = depth or 0
        if depth > 3 then -- Prevent infinite recursion
            return 50 -- Rough estimate for deep tables
        end
        
        local size = 16 -- Base table overhead
        local count = 0
        
        for k, v in pairs(tbl) do
            count = count + 1
            if count > 20 then -- Limit processing for very large tables
                size = size + 100 -- Rough estimate for remaining entries
                break
            end
            
            -- Add key size
            if type(k) == "string" then
                size = size + #k
            else
                size = size + 8
            end
            
            -- Add value size (recursive)
            if type(v) == "table" then
                size = size + estimateTableSize(v, depth + 1)
            elseif type(v) == "string" then
                size = size + #v
            else
                size = size + 8
            end
        end
        
        return size
    end
    
    return estimateTableSize(data)
end

-- Internal helper function to format byte sizes into human-readable format
function SLH.Debug:_FormatBytes(bytes)
    -- Convert bytes to human-readable format (B, KB, MB)
    if bytes < 1024 then
        return string.format("%d B", bytes)
    elseif bytes < 1024 * 1024 then
        return string.format("%.1f KB", bytes / 1024)
    else
        return string.format("%.1f MB", bytes / (1024 * 1024))
    end
end

-- Internal helper function to format duration into human-readable format
function SLH.Debug:_FormatDuration(seconds)
    -- Convert seconds to human-readable duration format
    if seconds < 60 then
        return string.format("%d seconds", seconds)
    elseif seconds < 3600 then
        local minutes = math.floor(seconds / 60)
        local remainingSeconds = seconds % 60
        return string.format("%d minutes, %d seconds", minutes, remainingSeconds)
    else
        local hours = math.floor(seconds / 3600)
        local remainingMinutes = math.floor((seconds % 3600) / 60)
        return string.format("%d hours, %d minutes", hours, remainingMinutes)
    end
end

-- Internal helper function to update logging statistics
function SLH.Debug:_UpdateStats(logEntry)
    -- Ensure stats structure exists
    self.stats = self.stats or {
        totalLogEntries = 0,
        logEntriesByLevel = {},
        logEntriesByComponent = {}
    }
    
    -- Update total count
    self.stats.totalLogEntries = #self.logBuffer
    
    -- Update level statistics
    local level = logEntry.level
    self.stats.logEntriesByLevel[level] = (self.stats.logEntriesByLevel[level] or 0) + 1
    
    -- Update component statistics  
    local component = logEntry.component
    self.stats.logEntriesByComponent[component] = (self.stats.logEntriesByComponent[component] or 0) + 1
end

-- Export debug logs for bug reports
function SLH.Debug:ExportForBugReport()
    -- Create comprehensive bug report export with system information and logs
    local lines = {}
    
    -- Header with timestamp
    table.insert(lines, "=== SpectrumLootTool Debug Report ===")
    table.insert(lines, "Generated: " .. date("%Y-%m-%d %H:%M:%S"))
    table.insert(lines, "")
    
    -- System Information
    table.insert(lines, "--- System Information ---")
    
    -- WoW Version Information
    local success, wowVersion = pcall(function()
        local version, build, date, tocversion = GetBuildInfo()
        return string.format("Version: %s, Build: %s, Date: %s, TOC: %s", version, build, date, tocversion)
    end)
    table.insert(lines, "WoW: " .. (success and wowVersion or "Unknown"))
    
    -- Addon Version
    table.insert(lines, "Addon Version: " .. (SLH.version or "Unknown"))
    table.insert(lines, "Debug Version: " .. (self.version or "Unknown"))
    
    -- Player and Guild Information
    local playerName = UnitName("player") or "Unknown"
    local guildName = GetGuildInfo("player") or "None"
    table.insert(lines, "Player: " .. playerName)
    table.insert(lines, "Guild: " .. guildName)
    
    -- Group Status
    local groupStatus = "Solo"
    if IsInRaid() then
        groupStatus = "Raid (" .. GetNumGroupMembers() .. " members)"
    elseif IsInGroup() then
        groupStatus = "Party (" .. GetNumGroupMembers() .. " members)"
    end
    table.insert(lines, "Group: " .. groupStatus)
    
    -- Debug System Status
    table.insert(lines, "Debug Enabled: " .. tostring(self.enabled))
    if self.sessionStartTime then
        local sessionDuration = GetServerTime() - self.sessionStartTime
        table.insert(lines, "Session Duration: " .. self:_FormatDuration(sessionDuration))
    end
    table.insert(lines, "")
    
    -- Statistics Summary
    table.insert(lines, "--- Debug Statistics ---")
    local stats = self:GetStats()
    table.insert(lines, "Total Log Entries: " .. stats.totalEntries)
    table.insert(lines, "Memory Usage: " .. self:_FormatBytes(stats.memoryUsage))
    table.insert(lines, "Session Uptime: " .. self:_FormatDuration(stats.sessionDuration))
    
    -- Log Entries by Level
    if stats.logEntriesByLevel then
        table.insert(lines, "Entries by Level:")
        for level, count in pairs(stats.logEntriesByLevel) do
            table.insert(lines, "  " .. level .. ": " .. count)
        end
    end
    
    -- Log Entries by Component
    if stats.logEntriesByComponent then
        table.insert(lines, "Entries by Component:")
        for component, count in pairs(stats.logEntriesByComponent) do
            table.insert(lines, "  " .. component .. ": " .. count)
        end
    end
    table.insert(lines, "")
    
    -- Recent Log Entries (last 50 or all if fewer)
    table.insert(lines, "--- Recent Debug Logs ---")
    local recentLogs = self:GetSessionLogs(nil, nil, 50)
    
    if #recentLogs == 0 then
        table.insert(lines, "No debug logs in current session.")
    else
        table.insert(lines, "Showing " .. #recentLogs .. " most recent entries:")
        table.insert(lines, "")
        
        for _, logEntry in ipairs(recentLogs) do
            -- Format: [TIME] LEVEL [COMPONENT] MESSAGE (DATA)
            local timestamp = date("%H:%M:%S", logEntry.timestamp)
            local levelStr = string.upper(logEntry.level or "INFO")
            local componentStr = logEntry.component or "Unknown"
            local messageStr = logEntry.message or ""
            
            local logLine = string.format("[%s] %s [%s] %s", 
                timestamp, levelStr, componentStr, messageStr)
            
            -- Add data context if present
            if logEntry.data then
                local dataStr = self:_SerializeLogData(logEntry.data)
                if dataStr and dataStr ~= "" then
                    logLine = logLine .. " (" .. dataStr .. ")"
                end
            end
            
            table.insert(lines, logLine)
        end
    end
    
    -- Footer
    table.insert(lines, "")
    table.insert(lines, "=== End Debug Report ===")
    table.insert(lines, "")
    table.insert(lines, "Please copy this entire report when submitting bug reports.")
    table.insert(lines, "Include steps to reproduce the issue and any error messages seen in-game.")
    
    -- Join all lines and return
    local report = table.concat(lines, "\n")
    
    -- Log the export action
    self:LogInfo("Debug", "Bug report exported", { 
        reportSize = string.len(report),
        logEntries = #recentLogs,
        sessionDuration = stats.sessionDuration
    })
    
    return report
end

-- Toggle debug logging via slash command
function SLH.Debug:Toggle()
    -- Store previous state for logging
    local wasEnabled = self.enabled
    
    -- Toggle the enabled state
    self:SetEnabled(not self.enabled)
    
    -- Provide user feedback in chat
    if self.enabled then
        print("|cff00ff00SLH Debug: Debug logging ENABLED|r")
        print("|cff00ff00Use '/slh debug off' to disable or '/slh debug export' for bug reports|r")
        
        -- Log the enable action
        self:LogInfo("Debug", "Debug logging enabled via toggle command", {
            previousState = wasEnabled,
            sessionStartTime = self.sessionStartTime
        })
    else
        print("|cffff0000SLH Debug: Debug logging DISABLED|r")
        print("|cffff0000Use '/slh debug on' to re-enable debug output|r")
        
        -- Log the disable action (this will be one of the last entries before disabling)
        self:LogInfo("Debug", "Debug logging disabled via toggle command", {
            previousState = wasEnabled,
            sessionDuration = self.sessionStartTime and (GetServerTime() - self.sessionStartTime) or 0
        })
    end
end

-- ========================================
-- TASK 15: INTEGRATION TESTING - CORE FUNCTIONS
-- ========================================

-- Comprehensive integration test for core debug system functionality
function SLH.Debug:RunCoreIntegrationTest()
    local testResults = {
        testName = "Debug System Core Integration Test",
        startTime = GetServerTime(),
        tests = {},
        passed = 0,
        failed = 0,
        errors = {}
    }
    
    print("|cff00ff00=== SLH Debug: Starting Core Integration Test ===|r")
    
    -- Test 1: System Initialization
    local function testInit()
        local success, result = pcall(function()
            -- Verify Init() sets up required components
            local wasEnabled = self.enabled
            self:Init()
            
            return {
                hasSessionStartTime = self.sessionStartTime ~= nil,
                hasLogBuffer = type(self.logBuffer) == "table",
                hasStats = type(self.stats) == "table",
                enabledStatePreserved = self.enabled == wasEnabled
            }
        end)
        
        if success and result.hasSessionStartTime and result.hasLogBuffer and result.hasStats then
            return true, "Init() properly initializes all components"
        else
            return false, "Init() failed: " .. (success and "Missing components" or tostring(result))
        end
    end
    
    -- Test 2: Basic Logging Flow
    local function testLoggingFlow()
        local success, result = pcall(function()
            local initialCount = #self.logBuffer
            local wasEnabled = self.enabled
            
            -- Ensure debug is enabled for testing
            if not self.enabled then
                self:SetEnabled(true)
            end
            
            -- Test each log level
            self:LogInfo("IntegrationTest", "Test info message", {testData = "info"})
            self:LogWarn("IntegrationTest", "Test warn message", {testData = "warn"})
            self:LogError("IntegrationTest", "Test error message", {testData = "error"})
            self:LogDebug("IntegrationTest", "Test debug message", {testData = "debug"})
            
            local finalCount = #self.logBuffer
            local entriesAdded = finalCount - initialCount
            
            -- Restore original enabled state
            self:SetEnabled(wasEnabled)
            
            return {
                entriesAdded = entriesAdded,
                expectedEntries = 4,
                logBufferValid = type(self.logBuffer) == "table"
            }
        end)
        
        if success and result.entriesAdded >= 4 and result.logBufferValid then
            return true, string.format("Logging flow successful (%d entries added)", result.entriesAdded)
        else
            return false, "Logging flow failed: " .. (success and ("Added " .. result.entriesAdded .. " entries") or tostring(result))
        end
    end
    
    -- Test 3: Log Retrieval and Filtering
    local function testLogRetrieval()
        local success, result = pcall(function()
            -- Test GetSessionLogs with various filters
            local allLogs = self:GetSessionLogs()
            local infoLogs = self:GetSessionLogs("INFO")
            local testComponentLogs = self:GetSessionLogs(nil, "IntegrationTest")
            local limitedLogs = self:GetSessionLogs(nil, nil, 5)
            
            return {
                hasAllLogs = #allLogs > 0,
                hasInfoLogs = #infoLogs > 0,
                hasComponentLogs = #testComponentLogs > 0,
                limitWorking = #limitedLogs <= 5,
                allLogsCount = #allLogs
            }
        end)
        
        if success and result.hasAllLogs and result.limitWorking then
            return true, string.format("Log retrieval successful (%d total logs)", result.allLogsCount)
        else
            return false, "Log retrieval failed: " .. (success and "No logs or limit issue" or tostring(result))
        end
    end
    
    -- Test 4: Statistics Generation
    local function testStatistics()
        local success, result = pcall(function()
            local stats = self:GetStats()
            
            return {
                hasStats = type(stats) == "table",
                hasTotalEntries = type(stats.totalEntries) == "number",
                hasMemoryUsage = type(stats.memoryUsage) == "number",
                hasSessionDuration = type(stats.sessionDuration) == "number",
                hasLevelBreakdown = type(stats.logEntriesByLevel) == "table",
                hasComponentBreakdown = type(stats.logEntriesByComponent) == "table"
            }
        end)
        
        if success and result.hasStats and result.hasTotalEntries and result.hasMemoryUsage then
            return true, "Statistics generation successful"
        else
            return false, "Statistics generation failed: Missing required fields"
        end
    end
    
    -- Test 5: File Operations (if enabled)
    local function testFileOperations()
        local success, result = pcall(function()
            -- Test GetLogFileInfo
            local fileInfo = self:GetLogFileInfo()
            
            -- Test FlushToFile (only if enabled)
            local flushSuccess = false
            if self.enabled then
                flushSuccess = self:FlushToFile()
            end
            
            return {
                hasFileInfo = type(fileInfo) == "table",
                hasFilePath = type(fileInfo.path) == "string",
                flushAttempted = self.enabled,
                flushResult = flushSuccess
            }
        end)
        
        if success and result.hasFileInfo and result.hasFilePath then
            return true, "File operations functional"
        else
            return false, "File operations failed: " .. (success and "Missing file info" or tostring(result))
        end
    end
    
    -- Run all tests
    local tests = {
        {name = "System Initialization", func = testInit},
        {name = "Basic Logging Flow", func = testLoggingFlow},
        {name = "Log Retrieval & Filtering", func = testLogRetrieval},
        {name = "Statistics Generation", func = testStatistics},
        {name = "File Operations", func = testFileOperations}
    }
    
    for _, test in ipairs(tests) do
        local success, message = test.func()
        local result = {
            name = test.name,
            passed = success,
            message = message,
            timestamp = GetServerTime()
        }
        
        table.insert(testResults.tests, result)
        
        if success then
            testResults.passed = testResults.passed + 1
            print("|cff00ff00✅ " .. test.name .. ": " .. message .. "|r")
        else
            testResults.failed = testResults.failed + 1
            table.insert(testResults.errors, test.name .. ": " .. message)
            print("|cffff0000❌ " .. test.name .. ": " .. message .. "|r")
        end
    end
    
    -- Generate summary
    testResults.endTime = GetServerTime()
    testResults.duration = testResults.endTime - testResults.startTime
    testResults.totalTests = #tests
    testResults.successRate = (testResults.passed / testResults.totalTests) * 100
    
    print("|cff00ff00=== Integration Test Summary ===|r")
    print(string.format("|cff00ff00Tests Passed: %d/%d (%.1f%%)|r", 
        testResults.passed, testResults.totalTests, testResults.successRate))
    print(string.format("|cff00ff00Duration: %.2f seconds|r", testResults.duration))
    
    if testResults.failed > 0 then
        print("|cffff0000Failed Tests:|r")
        for _, error in ipairs(testResults.errors) do
            print("|cffff0000  - " .. error .. "|r")
        end
    end
    
    -- Log the test results
    self:LogInfo("IntegrationTest", "Core integration test completed", {
        passed = testResults.passed,
        failed = testResults.failed,
        successRate = testResults.successRate,
        duration = testResults.duration
    })
    
    return testResults
end

-- Performance validation test for debug system efficiency
function SLH.Debug:RunPerformanceValidation()
    local perfResults = {
        testName = "Debug System Performance Validation",
        startTime = GetServerTime(),
        metrics = {},
        recommendations = {}
    }
    
    print("|cff00ff00=== SLH Debug: Starting Performance Validation ===|r")
    
    -- Test 1: Logging Performance (when enabled)
    local function measureLoggingPerformance()
        if not self.enabled then
            return {
                skipped = true,
                reason = "Debug disabled - performance impact minimal"
            }
        end
        
        local iterations = 100
        local startTime = debugprofilestop and debugprofilestop() or GetServerTime() * 1000
        
        for i = 1, iterations do
            self:LogDebug("PerfTest", "Performance test message " .. i, {
                iteration = i,
                data = {test = true, value = i * 2}
            })
        end
        
        local endTime = debugprofilestop and debugprofilestop() or GetServerTime() * 1000
        local totalTime = endTime - startTime
        local avgTimePerLog = totalTime / iterations
        
        return {
            iterations = iterations,
            totalTime = totalTime,
            avgTimePerLog = avgTimePerLog,
            logsPerSecond = 1000 / avgTimePerLog
        }
    end
    
    -- Test 2: Memory Usage Assessment
    local function assessMemoryUsage()
        local stats = self:GetStats()
        local bufferSize = #self.logBuffer
        local estimatedMemory = stats.memoryUsage or 0
        
        -- Memory efficiency recommendations
        local recommendations = {}
        if bufferSize > 800 then
            table.insert(recommendations, "Consider clearing old logs - buffer approaching limit")
        end
        if estimatedMemory > 1024 * 1024 then  -- 1MB
            table.insert(recommendations, "Memory usage high - consider reducing log retention")
        end
        
        return {
            bufferSize = bufferSize,
            maxBufferSize = self.maxLogEntries,
            bufferUtilization = (bufferSize / self.maxLogEntries) * 100,
            estimatedMemoryBytes = estimatedMemory,
            estimatedMemoryMB = estimatedMemory / (1024 * 1024),
            recommendations = recommendations
        }
    end
    
    -- Test 3: Disabled State Performance
    local function testDisabledPerformance()
        local wasEnabled = self.enabled
        self:SetEnabled(false)
        
        local iterations = 1000
        local startTime = debugprofilestop and debugprofilestop() or GetServerTime() * 1000
        
        -- These should be nearly instant when disabled
        for i = 1, iterations do
            self:LogInfo("PerfTest", "This should be ignored", {data = i})
        end
        
        local endTime = debugprofilestop and debugprofilestop() or GetServerTime() * 1000
        local totalTime = endTime - startTime
        
        self:SetEnabled(wasEnabled)
        
        return {
            iterations = iterations,
            totalTime = totalTime,
            avgTimePerLog = totalTime / iterations,
            efficientlySkipped = totalTime < 10  -- Should be very fast when disabled
        }
    end
    
    -- Run performance tests
    local loggingPerf = measureLoggingPerformance()
    local memoryAssess = assessMemoryUsage()
    local disabledPerf = testDisabledPerformance()
    
    perfResults.metrics = {
        loggingPerformance = loggingPerf,
        memoryUsage = memoryAssess,
        disabledPerformance = disabledPerf
    }
    
    -- Generate performance report
    print("|cff00ff00--- Logging Performance ---|r")
    if loggingPerf.skipped then
        print("|cffff8800Skipped: " .. loggingPerf.reason .. "|r")
    else
        print(string.format("|cff00ff00Average time per log: %.3f ms|r", loggingPerf.avgTimePerLog))
        print(string.format("|cff00ff00Logs per second: %.1f|r", loggingPerf.logsPerSecond))
        
        if loggingPerf.avgTimePerLog > 1.0 then
            table.insert(perfResults.recommendations, "Logging performance may be slow for high-frequency operations")
        end
    end
    
    print("|cff00ff00--- Memory Usage ---|r")
    print(string.format("|cff00ff00Buffer utilization: %.1f%% (%d/%d entries)|r", 
        memoryAssess.bufferUtilization, memoryAssess.bufferSize, memoryAssess.maxBufferSize))
    print(string.format("|cff00ff00Estimated memory: %.2f MB|r", memoryAssess.estimatedMemoryMB))
    
    print("|cff00ff00--- Disabled State Performance ---|r")
    print(string.format("|cff00ff00Disabled overhead: %.3f ms for %d calls|r", 
        disabledPerf.totalTime, disabledPerf.iterations))
    print(string.format("|cff00ff00Efficiently skipped: %s|r", 
        disabledPerf.efficientlySkipped and "Yes" or "No"))
    
    if not disabledPerf.efficientlySkipped then
        table.insert(perfResults.recommendations, "Disabled state performance needs optimization")
    end
    
    -- Combine all recommendations
    for _, rec in ipairs(memoryAssess.recommendations) do
        table.insert(perfResults.recommendations, rec)
    end
    
    if #perfResults.recommendations > 0 then
        print("|cffff8800--- Recommendations ---|r")
        for _, rec in ipairs(perfResults.recommendations) do
            print("|cffff8800- " .. rec .. "|r")
        end
    else
        print("|cff00ff00--- All Performance Metrics Optimal ---|r")
    end
    
    perfResults.endTime = GetServerTime()
    perfResults.duration = perfResults.endTime - perfResults.startTime
    
    -- Log performance results
    self:LogInfo("PerformanceTest", "Performance validation completed", {
        duration = perfResults.duration,
        recommendationCount = #perfResults.recommendations,
        loggingEnabled = not (loggingPerf.skipped or false)
    })
    
    return perfResults
end

-- Convenience function to run all integration tests
function SLH.Debug:RunAllIntegrationTests()
    print("|cff00ff00========================================|r")
    print("|cff00ff00    SLH Debug Integration Testing    |r") 
    print("|cff00ff00========================================|r")
    
    local coreResults = self:RunCoreIntegrationTest()
    print("")
    local perfResults = self:RunPerformanceValidation()
    
    print("|cff00ff00========================================|r")
    print("|cff00ff00         Testing Complete           |r")
    print("|cff00ff00========================================|r")
    
    local allPassed = coreResults.failed == 0
    local hasPerformanceIssues = #perfResults.recommendations > 0
    
    if allPassed and not hasPerformanceIssues then
        print("|cff00ff00🎉 All tests passed with optimal performance!|r")
    elseif allPassed then
        print("|cffff8800✅ All tests passed, but performance could be improved.|r")
    else
        print("|cffff0000❌ Some tests failed. Review the results above.|r")
    end
    
    return {
        coreIntegration = coreResults,
        performance = perfResults,
        overallSuccess = allPassed,
        needsOptimization = hasPerformanceIssues
    }
end
