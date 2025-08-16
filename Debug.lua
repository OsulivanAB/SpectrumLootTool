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
function SLH.Debug:DisplayLogsInChat(level, component, count)
    -- Placeholder for displaying logs in chat
    -- Parameters:
    -- - level: string, optional filter by log level
    -- - component: string, optional filter by component  
    -- - count: number, optional limit number of entries (default 10)
    
    -- Will handle:
    -- - Format log entries for chat display
    -- - Apply color coding by log level
    -- - Pagination for large log sets
    -- - User-friendly timestamp formatting
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
    -- Placeholder for bug report export
    -- Will handle:
    -- - Format logs for bug report submission
    -- - Include system information (WoW version, addon version, etc.)
    -- - Create compact, readable format
    -- - Include session context and statistics
    
    -- Returns formatted string suitable for copying to bug reports
    return "Debug log export placeholder"
end

-- Toggle debug logging via slash command
function SLH.Debug:Toggle()
    -- Placeholder for debug toggle functionality
    -- Will handle:
    -- - Toggle enabled state
    -- - Provide user feedback
    -- - Log the toggle action
    self:SetEnabled(not self.enabled)
end
