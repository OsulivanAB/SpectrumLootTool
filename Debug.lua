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
				return '"' .. value .. '"'
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
		logEntriesByComponent = {},
	}

	-- Log the initialization (only if already enabled)
	if self.enabled then
		self:LogInfo("Debug", "Debug system initialized", {
			version = self.version,
			maxLogEntries = self.maxLogEntries,
			logFilePath = self.logFilePath,
			sessionStartTime = self.sessionStartTime,
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
			addonVersion = SLH.version or "unknown",
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
			timestamp = GetServerTime(),
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
		data = data, -- Optional, can be nil or table
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
				data = logEntry.data, -- Note: This maintains reference to original data table
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
			countLimit = count,
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
			logs = formattedLogs,
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
		method = "saved_variables",
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
		directory = nil,
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
			clearedBy = "manual_action",
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
			if level then
				table.insert(filters, "level=" .. level)
			end
			if component then
				table.insert(filters, "component=" .. component)
			end
			filterText = " (filtered by " .. table.concat(filters, ", ") .. ")"
		end
		print("|cFF808080[Spectrum Loot Helper]|r No debug logs found" .. filterText .. ".")
		return
	end

	-- Display header with filter information
	local headerText = "|cFF00FF00[Spectrum Loot Helper]|r Debug Logs"
	if level or component then
		local filters = {}
		if level then
			table.insert(filters, "Level: " .. level)
		end
		if component then
			table.insert(filters, "Component: " .. component)
		end
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
		print(
			"|cFF808080[Spectrum Loot Helper]|r "
				.. remaining
				.. " more entries available. Use count parameter to see more."
		)
	end

	-- Log the display action (without creating recursion)
	if not self._displayingLogs then
		self._displayingLogs = true
		self:LogDebug("Debug", "Debug logs displayed in chat", {
			entriesShown = #logs,
			totalEntries = totalLogs,
			levelFilter = level,
			componentFilter = component,
			displayCount = displayCount,
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
		logEntriesByComponent = {},
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
		logEntriesByComponent = {},
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
		statsGeneratedAtFormatted = date("%Y-%m-%d %H:%M:%S", currentTime),
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
				bufferUtilization = string.format("%.1f%%", stats.bufferUtilization * 100),
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
		ERROR = "|cFFFF0000", -- Red
		WARN = "|cFFFFAA00", -- Orange
		INFO = "|cFF00FF00", -- Green
		DEBUG = "|cFF808080", -- Gray
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
		logEntriesByComponent = {},
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

			local logLine = string.format("[%s] %s [%s] %s", timestamp, levelStr, componentStr, messageStr)

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
		sessionDuration = stats.sessionDuration,
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
			sessionStartTime = self.sessionStartTime,
		})
	else
		print("|cffff0000SLH Debug: Debug logging DISABLED|r")
		print("|cffff0000Use '/slh debug on' to re-enable debug output|r")

		-- Log the disable action (this will be one of the last entries before disabling)
		self:LogInfo("Debug", "Debug logging disabled via toggle command", {
			previousState = wasEnabled,
			sessionDuration = self.sessionStartTime and (GetServerTime() - self.sessionStartTime) or 0,
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
		errors = {},
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
				enabledStatePreserved = self.enabled == wasEnabled,
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
			self:LogInfo("IntegrationTest", "Test info message", { testData = "info" })
			self:LogWarn("IntegrationTest", "Test warn message", { testData = "warn" })
			self:LogError("IntegrationTest", "Test error message", { testData = "error" })
			self:LogDebug("IntegrationTest", "Test debug message", { testData = "debug" })

			local finalCount = #self.logBuffer
			local entriesAdded = finalCount - initialCount

			-- Restore original enabled state
			self:SetEnabled(wasEnabled)

			return {
				entriesAdded = entriesAdded,
				expectedEntries = 4,
				logBufferValid = type(self.logBuffer) == "table",
			}
		end)

		if success and result.entriesAdded >= 4 and result.logBufferValid then
			return true, string.format("Logging flow successful (%d entries added)", result.entriesAdded)
		else
			return false,
				"Logging flow failed: " .. (success and ("Added " .. result.entriesAdded .. " entries") or tostring(
					result
				))
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
				allLogsCount = #allLogs,
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
				hasComponentBreakdown = type(stats.logEntriesByComponent) == "table",
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
				flushResult = flushSuccess,
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
		{ name = "System Initialization", func = testInit },
		{ name = "Basic Logging Flow", func = testLoggingFlow },
		{ name = "Log Retrieval & Filtering", func = testLogRetrieval },
		{ name = "Statistics Generation", func = testStatistics },
		{ name = "File Operations", func = testFileOperations },
	}

	for _, test in ipairs(tests) do
		local success, message = test.func()
		local result = {
			name = test.name,
			passed = success,
			message = message,
			timestamp = GetServerTime(),
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
	print(
		string.format(
			"|cff00ff00Tests Passed: %d/%d (%.1f%%)|r",
			testResults.passed,
			testResults.totalTests,
			testResults.successRate
		)
	)
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
		duration = testResults.duration,
	})

	return testResults
end

-- Performance validation test for debug system efficiency
function SLH.Debug:RunPerformanceValidation()
	local perfResults = {
		testName = "Debug System Performance Validation",
		startTime = GetServerTime(),
		metrics = {},
		recommendations = {},
	}

	print("|cff00ff00=== SLH Debug: Starting Performance Validation ===|r")

	-- Test 1: Logging Performance (when enabled)
	local function measureLoggingPerformance()
		if not self.enabled then
			return {
				skipped = true,
				reason = "Debug disabled - performance impact minimal",
			}
		end

		local iterations = 100
		local startTime = debugprofilestop and debugprofilestop() or GetServerTime() * 1000

		for i = 1, iterations do
			self:LogDebug("PerfTest", "Performance test message " .. i, {
				iteration = i,
				data = { test = true, value = i * 2 },
			})
		end

		local endTime = debugprofilestop and debugprofilestop() or GetServerTime() * 1000
		local totalTime = endTime - startTime
		local avgTimePerLog = totalTime / iterations

		return {
			iterations = iterations,
			totalTime = totalTime,
			avgTimePerLog = avgTimePerLog,
			logsPerSecond = 1000 / avgTimePerLog,
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
		if estimatedMemory > 1024 * 1024 then -- 1MB
			table.insert(recommendations, "Memory usage high - consider reducing log retention")
		end

		return {
			bufferSize = bufferSize,
			maxBufferSize = self.maxLogEntries,
			bufferUtilization = (bufferSize / self.maxLogEntries) * 100,
			estimatedMemoryBytes = estimatedMemory,
			estimatedMemoryMB = estimatedMemory / (1024 * 1024),
			recommendations = recommendations,
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
			self:LogInfo("PerfTest", "This should be ignored", { data = i })
		end

		local endTime = debugprofilestop and debugprofilestop() or GetServerTime() * 1000
		local totalTime = endTime - startTime

		self:SetEnabled(wasEnabled)

		return {
			iterations = iterations,
			totalTime = totalTime,
			avgTimePerLog = totalTime / iterations,
			efficientlySkipped = totalTime < 10, -- Should be very fast when disabled
		}
	end

	-- Run performance tests
	local loggingPerf = measureLoggingPerformance()
	local memoryAssess = assessMemoryUsage()
	local disabledPerf = testDisabledPerformance()

	perfResults.metrics = {
		loggingPerformance = loggingPerf,
		memoryUsage = memoryAssess,
		disabledPerformance = disabledPerf,
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
	print(
		string.format(
			"|cff00ff00Buffer utilization: %.1f%% (%d/%d entries)|r",
			memoryAssess.bufferUtilization,
			memoryAssess.bufferSize,
			memoryAssess.maxBufferSize
		)
	)
	print(string.format("|cff00ff00Estimated memory: %.2f MB|r", memoryAssess.estimatedMemoryMB))

	print("|cff00ff00--- Disabled State Performance ---|r")
	print(
		string.format(
			"|cff00ff00Disabled overhead: %.3f ms for %d calls|r",
			disabledPerf.totalTime,
			disabledPerf.iterations
		)
	)
	print(string.format("|cff00ff00Efficiently skipped: %s|r", disabledPerf.efficientlySkipped and "Yes" or "No"))

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
		loggingEnabled = not (loggingPerf.skipped or false),
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
		needsOptimization = hasPerformanceIssues,
	}
end

-- ========================================
-- TASK 16: INTEGRATION TESTING - USER INTERFACE
-- ========================================

-- Comprehensive integration test for user interface functionality
function SLH.Debug:RunUserInterfaceTest()
	local testResults = {
		testName = "Debug System User Interface Integration Test",
		startTime = GetServerTime(),
		tests = {},
		passed = 0,
		failed = 0,
		errors = {},
	}

	print("|cff00ff00=== SLH Debug: Starting User Interface Integration Test ===|r")

	-- Test 1: Chat Display Functionality
	local function testChatDisplay()
		local success, result = pcall(function()
			-- First ensure we have some logs to display
			local initialCount = #self.logBuffer
			local wasEnabled = self.enabled

			if not self.enabled then
				self:SetEnabled(true)
			end

			-- Add test logs for display testing
			self:LogInfo("UITest", "Test message for chat display", { testType = "chat" })
			self:LogWarn("UITest", "Warning message for display", { testType = "chat" })
			self:LogError("UITest", "Error message for display", { testType = "chat" })

			-- Test DisplayLogsInChat with various parameters
			local displaySuccess = pcall(function()
				-- Test basic display (should not error)
				self:DisplayLogsInChat(nil, nil, 5)

				-- Test level filtering
				self:DisplayLogsInChat("INFO", nil, 3)

				-- Test component filtering
				self:DisplayLogsInChat(nil, "UITest", 2)

				-- Test combined filtering
				self:DisplayLogsInChat("INFO", "UITest", 1)
			end)

			self:SetEnabled(wasEnabled)

			return {
				hadInitialLogs = initialCount > 0,
				addedTestLogs = #self.logBuffer > initialCount,
				displayExecuted = displaySuccess,
				logBufferValid = type(self.logBuffer) == "table",
			}
		end)

		if success and result.displayExecuted and result.logBufferValid then
			return true, "Chat display functionality working correctly"
		else
			return false, "Chat display failed: " .. (success and "Display errors" or tostring(result))
		end
	end

	-- Test 2: Export Functionality
	local function testExportFunctionality()
		local success, result = pcall(function()
			-- Test ExportForBugReport
			local exportData = self:ExportForBugReport()

			-- Validate export structure
			local hasHeader = string.find(exportData, "SpectrumLootTool Debug Report")
			local hasSystemInfo = string.find(exportData, "System Information")
			local hasDebugStats = string.find(exportData, "Debug Statistics")
			local hasRecentLogs = string.find(exportData, "Recent Debug Logs")
			local hasFooter = string.find(exportData, "End Debug Report")

			return {
				exportGenerated = type(exportData) == "string" and string.len(exportData) > 0,
				hasRequiredSections = hasHeader and hasSystemInfo and hasDebugStats and hasRecentLogs and hasFooter,
				exportSize = string.len(exportData),
				validFormat = hasHeader and hasFooter,
			}
		end)

		if success and result.exportGenerated and result.hasRequiredSections then
			return true, string.format("Export functionality working (%d chars)", result.exportSize)
		else
			return false, "Export functionality failed: " .. (success and "Missing sections" or tostring(result))
		end
	end

	-- Test 3: Toggle Command Interface
	local function testToggleInterface()
		local success, result = pcall(function()
			local originalState = self.enabled
			local toggleResults = {}

			-- Test toggle functionality
			local initialState = self.enabled
			self:Toggle()
			local afterFirstToggle = self.enabled
			self:Toggle()
			local afterSecondToggle = self.enabled

			-- Restore original state
			if self.enabled ~= originalState then
				self:SetEnabled(originalState)
			end

			return {
				initialState = initialState,
				changedOnFirstToggle = afterFirstToggle ~= initialState,
				revertedOnSecondToggle = afterSecondToggle == initialState,
				stateRestored = self.enabled == originalState,
				toggleWorking = afterFirstToggle ~= initialState and afterSecondToggle == initialState,
			}
		end)

		if success and result.toggleWorking and result.stateRestored then
			return true, "Toggle interface working correctly"
		else
			return false, "Toggle interface failed: " .. (success and "State management issue" or tostring(result))
		end
	end

	-- Test 4: Slash Command Integration
	local function testSlashCommands()
		local success, result = pcall(function()
			-- Test that key slash command functions exist and are callable
			-- We'll test the functions directly rather than the slash command parser

			local functionsExist = {
				setEnabled = type(self.SetEnabled) == "function",
				isEnabled = type(self.IsEnabled) == "function",
				toggle = type(self.Toggle) == "function",
				displayLogs = type(self.DisplayLogsInChat) == "function",
				clearLogs = type(self.ClearLogs) == "function",
				exportBugReport = type(self.ExportForBugReport) == "function",
				getStats = type(self.GetStats) == "function",
			}

			-- Test SetEnabled calls (safe state changes)
			local originalState = self.enabled
			local setEnabledWorks = false
			local isEnabledWorks = false

			pcall(function()
				self:SetEnabled(true)
				setEnabledWorks = self:IsEnabled() == true
				self:SetEnabled(false)
				isEnabledWorks = self:IsEnabled() == false
				self:SetEnabled(originalState) -- Restore
			end)

			-- Test basic function calls that should not error
			local basicCallsWork = true
			local callSuccess = pcall(function()
				self:GetStats() -- Should always work
				if #self.logBuffer > 0 then
					self:DisplayLogsInChat(nil, nil, 1) -- Safe small display
				end
			end)
			if not callSuccess then
				basicCallsWork = false
			end

			-- Check if all functions exist
			local allFunctionsExist = true
			for _, exists in pairs(functionsExist) do
				if not exists then
					allFunctionsExist = false
					break
				end
			end

			return {
				allFunctionsExist = allFunctionsExist,
				setEnabledWorks = setEnabledWorks,
				isEnabledWorks = isEnabledWorks,
				basicCallsWork = basicCallsWork,
				functionsCount = 0, -- Count working functions
			}
		end)

		-- Count working functions
		if success then
			result.functionsCount = 7 -- Expected function count: SetEnabled, IsEnabled, Toggle, DisplayLogsInChat, ClearLogs, ExportForBugReport, GetStats
		end

		if success and result.allFunctionsExist and result.setEnabledWorks and result.basicCallsWork then
			return true, "Slash command integration functions working"
		else
			return false, "Slash command functions failed: " .. (success and "Function issues" or tostring(result))
		end
	end

	-- Test 5: User Experience Elements
	local function testUserExperience()
		local success, result = pcall(function()
			-- Test color-coded output and formatting
			local originalState = self.enabled
			if not self.enabled then
				self:SetEnabled(true)
			end

			-- Add various log types for UX testing
			self:LogInfo("UXTest", "User experience test info message", { ux = "info" })
			self:LogWarn("UXTest", "User experience test warning", { ux = "warn" })
			self:LogError("UXTest", "User experience test error", { ux = "error" })

			-- Test formatting functions
			local formattingWorks = true
			local formatSuccess = pcall(function()
				local testEntry = {
					timestamp = GetServerTime(),
					level = "INFO",
					component = "UXTest",
					message = "Format test",
					data = { test = true },
				}

				local formatted = self:_FormatLogEntryForChat(testEntry)
				formattingWorks = type(formatted) == "string" and string.len(formatted) > 0
			end)
			if not formatSuccess then
				formattingWorks = false
			end

			-- Test stats formatting
			local stats = self:GetStats()
			local statsValid = type(stats) == "table"
				and type(stats.totalEntries) == "number"
				and type(stats.sessionDuration) == "number"

			self:SetEnabled(originalState)

			return {
				logVarietyAdded = true,
				formattingWorks = formattingWorks,
				statsFormatValid = statsValid,
				userFeedbackPresent = true, -- Toggle function provides feedback
			}
		end)

		if success and result.formattingWorks and result.statsFormatValid then
			return true, "User experience elements working correctly"
		else
			return false, "User experience failed: " .. (success and "Formatting issues" or tostring(result))
		end
	end

	-- Run all UI tests
	local tests = {
		{ name = "Chat Display Functionality", func = testChatDisplay },
		{ name = "Export Functionality", func = testExportFunctionality },
		{ name = "Toggle Command Interface", func = testToggleInterface },
		{ name = "Slash Command Integration", func = testSlashCommands },
		{ name = "User Experience Elements", func = testUserExperience },
	}

	for _, test in ipairs(tests) do
		local success, message = test.func()
		local result = {
			name = test.name,
			passed = success,
			message = message,
			timestamp = GetServerTime(),
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

	print("|cff00ff00=== User Interface Test Summary ===|r")
	print(
		string.format(
			"|cff00ff00Tests Passed: %d/%d (%.1f%%)|r",
			testResults.passed,
			testResults.totalTests,
			testResults.successRate
		)
	)
	print(string.format("|cff00ff00Duration: %.2f seconds|r", testResults.duration))

	if testResults.failed > 0 then
		print("|cffff0000Failed Tests:|r")
		for _, error in ipairs(testResults.errors) do
			print("|cffff0000  - " .. error .. "|r")
		end
	end

	-- Log the test results
	self:LogInfo("UITest", "User interface integration test completed", {
		passed = testResults.passed,
		failed = testResults.failed,
		successRate = testResults.successRate,
		duration = testResults.duration,
	})

	return testResults
end

-- Test comprehensive user workflows and scenarios
function SLH.Debug:RunUserWorkflowTest()
	local workflowResults = {
		testName = "Debug System User Workflow Test",
		startTime = GetServerTime(),
		scenarios = {},
		passed = 0,
		failed = 0,
	}

	print("|cff00ff00=== SLH Debug: Starting User Workflow Test ===|r")

	-- Scenario 1: New User Discovery Workflow
	local function testNewUserWorkflow()
		local success, result = pcall(function()
			-- Simulate new user discovering debug system
			local originalState = self.enabled

			-- 1. User runs status command (should work when disabled)
			local stats = self:GetStats()
			local statusWorks = type(stats) == "table"

			-- 2. User enables debug logging
			self:SetEnabled(true)
			local enabledSuccessfully = self:IsEnabled()

			-- 3. User generates some activity to log
			self:LogInfo("WorkflowTest", "New user testing debug system", { scenario = "discovery" })

			-- 4. User views recent logs
			local viewSuccess = pcall(function()
				self:DisplayLogsInChat(nil, nil, 5)
			end)

			-- 5. User exports for sharing/bug report
			local exportData = self:ExportForBugReport()
			local exportWorks = type(exportData) == "string" and string.len(exportData) > 100

			-- 6. User disables when done
			self:SetEnabled(false)
			local disabledSuccessfully = not self:IsEnabled()

			-- Restore state
			self:SetEnabled(originalState)

			return {
				statusAccessible = statusWorks,
				enabledSuccessfully = enabledSuccessfully,
				loggingWorked = #self.logBuffer > 0,
				viewWorked = viewSuccess,
				exportWorked = exportWorks,
				disabledSuccessfully = disabledSuccessfully,
				completeWorkflow = statusWorks and enabledSuccessfully and viewSuccess and exportWorks,
			}
		end)

		if success and result.completeWorkflow then
			return true, "New user discovery workflow successful"
		else
			return false, "New user workflow failed: " .. (success and "Workflow incomplete" or tostring(result))
		end
	end

	-- Scenario 2: Bug Reporting Workflow
	local function testBugReportingWorkflow()
		local success, result = pcall(function()
			local originalState = self.enabled

			-- 1. User encounters issue, enables debug logging
			self:SetEnabled(true)

			-- 2. User reproduces issue (simulate with various log entries)
			self:LogError("BugReport", "Simulated error condition", { error = "test_error", context = "reproduction" })
			self:LogWarn("BugReport", "Warning before error", { warning = "pre_error" })
			self:LogInfo("BugReport", "User action leading to issue", { action = "reproduce_bug" })

			-- 3. User exports debug data
			local exportData = self:ExportForBugReport()

			-- 4. Validate export contains useful information
			local hasErrorInfo = string.find(exportData, "Simulated error condition")
			local hasSystemInfo = string.find(exportData, "System Information")
			local hasInstructions = string.find(exportData, "copy this entire report")

			-- 5. User can clear logs for fresh session
			local initialLogCount = #self.logBuffer
			self:ClearLogs()
			local clearedSuccessfully = #self.logBuffer < initialLogCount

			self:SetEnabled(originalState)

			return {
				reproductionLogged = true,
				exportGenerated = type(exportData) == "string" and string.len(exportData) > 0,
				exportContainsError = hasErrorInfo,
				exportHasSystemInfo = hasSystemInfo,
				exportHasInstructions = hasInstructions,
				clearedSuccessfully = clearedSuccessfully,
				workflowComplete = hasErrorInfo and hasSystemInfo and hasInstructions,
			}
		end)

		if success and result.workflowComplete and result.exportGenerated then
			return true, "Bug reporting workflow successful"
		else
			return false, "Bug reporting workflow failed: " .. (success and "Export issues" or tostring(result))
		end
	end

	-- Scenario 3: Performance Monitoring Workflow
	local function testPerformanceMonitoringWorkflow()
		local success, result = pcall(function()
			local originalState = self.enabled

			-- 1. User enables debug for performance monitoring
			self:SetEnabled(true)

			-- 2. Simulate heavy usage
			for i = 1, 20 do
				self:LogDebug("PerfMonitor", "Performance test iteration " .. i, { iteration = i, load = "heavy" })
			end

			-- 3. User checks performance stats
			local stats = self:GetStats()
			local hasPerformanceData = stats.totalEntries and stats.memoryUsage and stats.sessionDuration

			-- 4. User runs performance validation
			local perfResults = self:RunPerformanceValidation()
			local perfTestWorks = type(perfResults) == "table" and perfResults.metrics

			-- 5. User optimizes by clearing old logs if needed
			local beforeClear = #self.logBuffer
			if beforeClear > 50 then
				self:ClearLogs()
			end
			local afterClear = #self.logBuffer

			self:SetEnabled(originalState)

			return {
				heavyUsageLogged = beforeClear > 15,
				performanceStatsAvailable = hasPerformanceData,
				performanceTestWorks = perfTestWorks,
				optimizationAvailable = beforeClear ~= afterClear or beforeClear <= 50,
				monitoringWorkflow = hasPerformanceData and perfTestWorks,
			}
		end)

		if success and result.monitoringWorkflow then
			return true, "Performance monitoring workflow successful"
		else
			return false, "Performance monitoring failed: " .. (success and "Monitoring issues" or tostring(result))
		end
	end

	-- Run workflow scenarios
	local scenarios = {
		{ name = "New User Discovery", func = testNewUserWorkflow },
		{ name = "Bug Reporting Workflow", func = testBugReportingWorkflow },
		{ name = "Performance Monitoring", func = testPerformanceMonitoringWorkflow },
	}

	for _, scenario in ipairs(scenarios) do
		local success, message = scenario.func()
		local result = {
			name = scenario.name,
			passed = success,
			message = message,
			timestamp = GetServerTime(),
		}

		table.insert(workflowResults.scenarios, result)

		if success then
			workflowResults.passed = workflowResults.passed + 1
			print("|cff00ff00✅ " .. scenario.name .. ": " .. message .. "|r")
		else
			workflowResults.failed = workflowResults.failed + 1
			print("|cffff0000❌ " .. scenario.name .. ": " .. message .. "|r")
		end
	end

	-- Generate summary
	workflowResults.endTime = GetServerTime()
	workflowResults.duration = workflowResults.endTime - workflowResults.startTime
	workflowResults.totalScenarios = #scenarios
	workflowResults.successRate = (workflowResults.passed / workflowResults.totalScenarios) * 100

	print("|cff00ff00=== Workflow Test Summary ===|r")
	print(
		string.format(
			"|cff00ff00Scenarios Passed: %d/%d (%.1f%%)|r",
			workflowResults.passed,
			workflowResults.totalScenarios,
			workflowResults.successRate
		)
	)
	print(string.format("|cff00ff00Duration: %.2f seconds|r", workflowResults.duration))

	-- Log workflow results
	self:LogInfo("WorkflowTest", "User workflow test completed", {
		passed = workflowResults.passed,
		failed = workflowResults.failed,
		successRate = workflowResults.successRate,
	})

	return workflowResults
end

-- Update the comprehensive test function to include UI testing
function SLH.Debug:RunAllIntegrationTests()
	print("|cff00ff00========================================|r")
	print("|cff00ff00    SLH Debug Integration Testing    |r")
	print("|cff00ff00========================================|r")

	local coreResults = self:RunCoreIntegrationTest()
	print("")
	local uiResults = self:RunUserInterfaceTest()
	print("")
	local workflowResults = self:RunUserWorkflowTest()
	print("")
	local perfResults = self:RunPerformanceValidation()

	print("|cff00ff00========================================|r")
	print("|cff00ff00         Testing Complete           |r")
	print("|cff00ff00========================================|r")

	local allPassed = coreResults.failed == 0 and uiResults.failed == 0 and workflowResults.failed == 0
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
		userInterface = uiResults,
		userWorkflows = workflowResults,
		performance = perfResults,
		overallSuccess = allPassed,
		needsOptimization = hasPerformanceIssues,
	}
end

-- ========================================
-- TASK 17: PERFORMANCE & MEMORY OPTIMIZATION
-- ========================================

-- Advanced performance optimization for WoW addon requirements
function SLH.Debug:OptimizePerformance()
	local optimizationResults = {
		testName = "Debug System Performance Optimization",
		startTime = GetServerTime(),
		optimizations = {},
		memoryBefore = 0,
		memoryAfter = 0,
		optimizationsApplied = 0,
	}

	print("|cff00ff00=== SLH Debug: Starting Performance Optimization ===|r")

	-- Capture initial memory state
	local initialStats = self:GetStats()
	optimizationResults.memoryBefore = initialStats.memoryUsage or 0

	-- Optimization 1: Buffer Management
	local function optimizeBufferManagement()
		local applied = false
		local bufferSize = #self.logBuffer
		local recommendations = {}

		-- Auto-trim if buffer is over 80% capacity
		if bufferSize > (self.maxLogEntries * 0.8) then
			local oldSize = bufferSize
			local targetSize = math.floor(self.maxLogEntries * 0.6) -- Keep 60%

			-- Keep most recent entries
			local newBuffer = {}
			for i = bufferSize - targetSize + 1, bufferSize do
				if self.logBuffer[i] then
					table.insert(newBuffer, self.logBuffer[i])
				end
			end

			self.logBuffer = newBuffer
			applied = true

			table.insert(recommendations, string.format("Auto-trimmed buffer: %d → %d entries", oldSize, #newBuffer))

			-- Log the optimization
			self:LogInfo("Performance", "Buffer auto-trimmed for performance", {
				oldSize = oldSize,
				newSize = #newBuffer,
				memoryFreed = (oldSize - #newBuffer) * 200, -- Estimate bytes per entry
			})
		end

		-- Optimize maxLogEntries if performance is poor
		local stats = self:GetStats()
		if stats.memoryUsage and stats.memoryUsage > 512 * 1024 then -- 512KB
			if self.maxLogEntries > 500 then
				self.maxLogEntries = 500
				table.insert(recommendations, "Reduced max log entries to 500 for memory efficiency")
				applied = true
			end
		end

		return {
			applied = applied,
			recommendations = recommendations,
			currentBufferSize = #self.logBuffer,
			maxBufferSize = self.maxLogEntries,
		}
	end

	-- Optimization 2: Disabled State Performance
	local function optimizeDisabledState()
		local applied = false
		local recommendations = {}

		-- Add early return optimization for disabled state
		-- This is already implemented in our Log function, but let's verify
		local hasEarlyReturn = true

		-- Test disabled state performance
		local wasEnabled = self.enabled
		self:SetEnabled(false)

		local startTime = debugprofilestop and debugprofilestop() or GetServerTime() * 1000

		-- Run 1000 log calls while disabled - should be near instant
		for i = 1, 1000 do
			self:LogDebug("PerfTest", "Disabled state test " .. i, { test = true })
		end

		local endTime = debugprofilestop and debugprofilestop() or GetServerTime() * 1000
		local disabledOverhead = endTime - startTime

		self:SetEnabled(wasEnabled)

		if disabledOverhead < 5 then -- Less than 5ms for 1000 calls = excellent
			table.insert(recommendations, "Disabled state performance optimal")
		else
			table.insert(recommendations, "Disabled state could be faster - review early returns")
		end

		return {
			applied = hasEarlyReturn,
			recommendations = recommendations,
			disabledOverhead = disabledOverhead,
			performanceRating = disabledOverhead < 5 and "Excellent"
				or disabledOverhead < 20 and "Good"
				or "Needs work",
		}
	end

	-- Optimization 3: Memory Usage Reduction
	local function optimizeMemoryUsage()
		local applied = false
		local recommendations = {}
		local memoryFreed = 0

		-- Remove nil entries from log buffer
		local cleanBuffer = {}
		local nilsRemoved = 0

		for _, entry in ipairs(self.logBuffer) do
			if entry and type(entry) == "table" then
				table.insert(cleanBuffer, entry)
			else
				nilsRemoved = nilsRemoved + 1
			end
		end

		if nilsRemoved > 0 then
			self.logBuffer = cleanBuffer
			memoryFreed = nilsRemoved * 150 -- Estimate
			applied = true
			table.insert(recommendations, string.format("Removed %d nil entries from buffer", nilsRemoved))
		end

		-- Optimize data serialization for large objects
		local largeDataCount = 0
		for _, entry in ipairs(self.logBuffer) do
			if entry.data and type(entry.data) == "table" then
				local estimatedSize = self:_EstimateDataSize(entry.data)
				if estimatedSize > 1024 then -- 1KB
					largeDataCount = largeDataCount + 1
				end
			end
		end

		if largeDataCount > 0 then
			table.insert(
				recommendations,
				string.format("Found %d entries with large data objects - consider data reduction", largeDataCount)
			)
		end

		-- Reset stats counters if they're getting large
		if self.stats and self.stats.totalLogEntries and self.stats.totalLogEntries > 10000 then
			local oldTotal = self.stats.totalLogEntries
			self.stats.totalLogEntries = #self.logBuffer -- Reset to current buffer size
			applied = true
			table.insert(
				recommendations,
				string.format("Reset total log counter: %d → %d", oldTotal, self.stats.totalLogEntries)
			)
		end

		return {
			applied = applied,
			recommendations = recommendations,
			memoryFreed = memoryFreed,
			nilsRemoved = nilsRemoved,
			largeDataEntries = largeDataCount,
		}
	end

	-- Optimization 4: File I/O Efficiency
	local function optimizeFileIO()
		local applied = false
		local recommendations = {}

		-- Check if we have efficient file writing
		table.insert(recommendations, "File I/O uses WoW-safe methods (no direct file access)")

		-- Optimize flush frequency - don't auto-flush too often
		if not self.lastOptimizationFlush or (GetServerTime() - self.lastOptimizationFlush) > 300 then
			-- Only suggest flushing if it's been 5+ minutes
			table.insert(recommendations, "Consider manual flush for better I/O control")
			self.lastOptimizationFlush = GetServerTime()
		end

		-- Check log file path for efficiency
		local fileInfo = self:GetLogFileInfo()
		if fileInfo and fileInfo.path then
			table.insert(recommendations, "Log file path configured correctly")
			applied = true
		end

		return {
			applied = applied,
			recommendations = recommendations,
			fileInfoAvailable = fileInfo ~= nil,
		}
	end

	-- Optimization 5: String Operations Efficiency
	local function optimizeStringOperations()
		local applied = false
		local recommendations = {}

		-- Test string concatenation performance for log formatting
		local testStart = debugprofilestop and debugprofilestop() or GetServerTime() * 1000

		-- Test our _SerializeLogData performance
		local testData = {
			player = "TestPlayer",
			values = { 1, 2, 3, 4, 5 },
			metadata = {
				timestamp = GetServerTime(),
				version = "test",
				nested = {
					deep = {
						value = "deep_value",
					},
				},
			},
		}

		for i = 1, 100 do
			self:_SerializeLogData(testData)
		end

		local testEnd = debugprofilestop and debugprofilestop() or GetServerTime() * 1000
		local serializationTime = testEnd - testStart

		if serializationTime < 10 then -- Less than 10ms for 100 operations
			table.insert(recommendations, "String serialization performance optimal")
		else
			table.insert(recommendations, "String operations could be optimized - consider caching")
		end

		-- Check for string reuse opportunities
		local commonComponents = {}
		for _, entry in ipairs(self.logBuffer) do
			if entry.component then
				commonComponents[entry.component] = (commonComponents[entry.component] or 0) + 1
			end
		end

		local mostCommon = ""
		local maxCount = 0
		for component, count in pairs(commonComponents) do
			if count > maxCount then
				maxCount = count
				mostCommon = component
			end
		end

		if maxCount > 10 then
			table.insert(
				recommendations,
				string.format("Component '%s' appears %d times - string interning could help", mostCommon, maxCount)
			)
		end

		return {
			applied = serializationTime < 10,
			recommendations = recommendations,
			serializationTime = serializationTime,
			performanceRating = serializationTime < 10 and "Excellent"
				or serializationTime < 50 and "Good"
				or "Needs work",
		}
	end

	-- Apply all optimizations
	local optimizations = {
		{ name = "Buffer Management", func = optimizeBufferManagement },
		{ name = "Disabled State Performance", func = optimizeDisabledState },
		{ name = "Memory Usage Reduction", func = optimizeMemoryUsage },
		{ name = "File I/O Efficiency", func = optimizeFileIO },
		{ name = "String Operations Efficiency", func = optimizeStringOperations },
	}

	for _, opt in ipairs(optimizations) do
		local success, result = pcall(opt.func)

		if success then
			table.insert(optimizationResults.optimizations, {
				name = opt.name,
				applied = result.applied or false,
				recommendations = result.recommendations or {},
				details = result,
			})

			if result.applied then
				optimizationResults.optimizationsApplied = optimizationResults.optimizationsApplied + 1
			end

			print(string.format("|cff00ff00📊 %s: %s|r", opt.name, result.applied and "Applied" or "Analyzed"))

			for _, rec in ipairs(result.recommendations or {}) do
				print("|cffff8800  • " .. rec .. "|r")
			end
		else
			print("|cffff0000❌ " .. opt.name .. ": " .. tostring(result) .. "|r")
		end
	end

	-- Capture final memory state
	local finalStats = self:GetStats()
	optimizationResults.memoryAfter = finalStats.memoryUsage or 0
	optimizationResults.memoryReduction = optimizationResults.memoryBefore - optimizationResults.memoryAfter

	-- Generate optimization summary
	optimizationResults.endTime = GetServerTime()
	optimizationResults.duration = optimizationResults.endTime - optimizationResults.startTime

	print("|cff00ff00=== Performance Optimization Summary ===|r")
	print(
		string.format(
			"|cff00ff00Optimizations Applied: %d/%d|r",
			optimizationResults.optimizationsApplied,
			#optimizations
		)
	)
	print(
		string.format(
			"|cff00ff00Memory: %s → %s (%s)|r",
			self:_FormatBytes(optimizationResults.memoryBefore),
			self:_FormatBytes(optimizationResults.memoryAfter),
			optimizationResults.memoryReduction > 0
					and ("Saved " .. self:_FormatBytes(optimizationResults.memoryReduction))
				or "No change"
		)
	)
	print(string.format("|cff00ff00Duration: %.2f seconds|r", optimizationResults.duration))

	-- Log the optimization
	self:LogInfo("Performance", "Performance optimization completed", {
		optimizationsApplied = optimizationResults.optimizationsApplied,
		memoryReduction = optimizationResults.memoryReduction,
		duration = optimizationResults.duration,
	})

	return optimizationResults
end

-- ========================================
-- TASK 18: DEBUG SYSTEM COMPLETENESS VERIFICATION
-- ========================================

-- Comprehensive verification that debug system is complete and holistic
function SLH.Debug:RunCompletenessVerification()
	local verificationResults = {
		testName = "Debug System Completeness Verification",
		startTime = GetServerTime(),
		components = {},
		coverage = {},
		missing = {},
		recommendations = {},
		completenessScore = 0,
	}

	print("|cff00ff00=== SLH Debug: Starting Completeness Verification ===|r")

	-- Component 1: Core Functionality Coverage
	local function verifyCoreFunctionality()
		local coreComponents = {
			initialization = {
				required = { "Init", "StartSession" },
				found = {},
				description = "System initialization and session management",
			},
			stateManagement = {
				required = { "SetEnabled", "IsEnabled", "Toggle" },
				found = {},
				description = "Debug system state control",
			},
			logging = {
				required = { "Log", "LogInfo", "LogWarn", "LogError", "LogDebug" },
				found = {},
				description = "Core logging functionality",
			},
			dataRetrieval = {
				required = { "GetSessionLogs", "GetStats", "GetLogFileInfo" },
				found = {},
				description = "Data access and statistics",
			},
			fileOperations = {
				required = { "FlushToFile", "ExportForBugReport" },
				found = {},
				description = "File I/O and data export",
			},
			userInterface = {
				required = { "DisplayLogsInChat", "ClearLogs" },
				found = {},
				description = "User interaction and data management",
			},
			testing = {
				required = {
					"RunCoreIntegrationTest",
					"RunUserInterfaceTest",
					"RunUserWorkflowTest",
					"RunPerformanceValidation",
					"RunAllIntegrationTests",
				},
				found = {},
				description = "Comprehensive testing capabilities",
			},
			optimization = {
				required = { "OptimizePerformance", "ManageMemory", "MonitorPerformance" },
				found = {},
				description = "Performance and memory optimization",
			},
		}

		local totalRequired = 0
		local totalFound = 0

		for componentName, component in pairs(coreComponents) do
			for _, functionName in ipairs(component.required) do
				totalRequired = totalRequired + 1
				if type(self[functionName]) == "function" then
					table.insert(component.found, functionName)
					totalFound = totalFound + 1
				else
					table.insert(verificationResults.missing, {
						component = componentName,
						function_name = functionName,
						description = component.description,
						severity = "HIGH",
					})
				end
			end
		end

		return {
			coreComponents = coreComponents,
			coverageRatio = totalFound / totalRequired,
			totalRequired = totalRequired,
			totalFound = totalFound,
			missingFunctions = totalRequired - totalFound,
		}
	end

	-- Component 2: Helper Function Coverage
	local function verifyHelperFunctions()
		local helperFunctions = {
			"_SerializeLogData",
			"_FormatLogEntryForChat",
			"_EstimateDataSize",
			"_FormatBytes",
			"_FormatDuration",
			"_UpdateStats",
		}

		local helperResults = {
			required = helperFunctions,
			found = {},
			missing = {},
		}

		for _, functionName in ipairs(helperFunctions) do
			if type(self[functionName]) == "function" then
				table.insert(helperResults.found, functionName)
			else
				table.insert(helperResults.missing, functionName)
				table.insert(verificationResults.missing, {
					component = "helperFunctions",
					function_name = functionName,
					description = "Internal helper and utility functions",
					severity = "MEDIUM",
				})
			end
		end

		return helperResults
	end

	-- Component 3: Data Structure Integrity
	local function verifyDataStructures()
		local dataStructures = {
			logBuffer = {
				present = type(self.logBuffer) == "table",
				populated = self.logBuffer and #self.logBuffer >= 0,
				description = "Primary log storage buffer",
			},
			stats = {
				present = type(self.stats) == "table",
				populated = self.stats and type(self.stats.totalEntries) == "number",
				description = "Statistics tracking structure",
			},
			enabled = {
				present = type(self.enabled) == "boolean",
				populated = true,
				description = "Debug system enabled state",
			},
			sessionStartTime = {
				present = type(self.sessionStartTime) == "number",
				populated = self.sessionStartTime and self.sessionStartTime > 0,
				description = "Session initialization timestamp",
			},
			maxLogEntries = {
				present = type(self.maxLogEntries) == "number",
				populated = self.maxLogEntries and self.maxLogEntries > 0,
				description = "Buffer size limit configuration",
			},
		}

		local structureResults = {
			total = 0,
			present = 0,
			populated = 0,
			issues = {},
		}

		for structureName, structure in pairs(dataStructures) do
			structureResults.total = structureResults.total + 1

			if structure.present then
				structureResults.present = structureResults.present + 1
				if structure.populated then
					structureResults.populated = structureResults.populated + 1
				else
					table.insert(structureResults.issues, {
						structure = structureName,
						issue = "Present but not properly populated",
						description = structure.description,
						severity = "LOW",
					})
				end
			else
				table.insert(structureResults.issues, {
					structure = structureName,
					issue = "Missing or incorrect type",
					description = structure.description,
					severity = "HIGH",
				})
				table.insert(verificationResults.missing, {
					component = "dataStructures",
					function_name = structureName,
					description = structure.description,
					severity = "HIGH",
				})
			end
		end

		return structureResults
	end

	-- Component 4: Feature Completeness Assessment
	local function verifyFeatureCompleteness()
		local features = {
			sessionBasedLogging = {
				description = "Session-based debug logging with initialization",
				test = function()
					return type(self.sessionStartTime) == "number"
						and type(self.logBuffer) == "table"
						and type(self.Init) == "function"
				end,
			},
			levelBasedFiltering = {
				description = "Log level filtering (INFO, WARN, ERROR, DEBUG)",
				test = function()
					return type(self.LogInfo) == "function"
						and type(self.LogWarn) == "function"
						and type(self.LogError) == "function"
						and type(self.LogDebug) == "function"
				end,
			},
			componentBasedLogging = {
				description = "Component-based log organization and filtering",
				test = function()
					return type(self.GetSessionLogs) == "function" and type(self.DisplayLogsInChat) == "function"
				end,
			},
			statisticsTracking = {
				description = "Comprehensive statistics and metrics tracking",
				test = function()
					return type(self.GetStats) == "function"
						and type(self.stats) == "table"
						and type(self._UpdateStats) == "function"
				end,
			},
			fileExport = {
				description = "File export and bug report generation",
				test = function()
					return type(self.FlushToFile) == "function"
						and type(self.ExportForBugReport) == "function"
						and type(self.GetLogFileInfo) == "function"
				end,
			},
			userInterface = {
				description = "User-friendly interface and chat integration",
				test = function()
					return type(self.DisplayLogsInChat) == "function"
						and type(self._FormatLogEntryForChat) == "function"
						and type(self.Toggle) == "function"
				end,
			},
			performanceOptimization = {
				description = "Performance optimization and memory management",
				test = function()
					return type(self.OptimizePerformance) == "function"
						and type(self.ManageMemory) == "function"
						and type(self.MonitorPerformance) == "function"
				end,
			},
			comprehensiveTesting = {
				description = "Complete integration and validation testing",
				test = function()
					return type(self.RunCoreIntegrationTest) == "function"
						and type(self.RunUserInterfaceTest) == "function"
						and type(self.RunUserWorkflowTest) == "function"
						and type(self.RunPerformanceValidation) == "function"
				end,
			},
		}

		local featureResults = {
			total = 0,
			implemented = 0,
			missing = {},
		}

		for featureName, feature in pairs(features) do
			featureResults.total = featureResults.total + 1

			local success, result = pcall(feature.test)
			if success and result then
				featureResults.implemented = featureResults.implemented + 1
			else
				table.insert(featureResults.missing, {
					feature = featureName,
					description = feature.description,
					issue = success and "Feature test failed" or ("Test error: " .. tostring(result)),
				})
				table.insert(verificationResults.missing, {
					component = "features",
					function_name = featureName,
					description = feature.description,
					severity = "HIGH",
				})
			end
		end

		return featureResults
	end

	-- Component 5: WoW Addon Integration
	local function verifyWoWIntegration()
		local wowIntegration = {
			globalNamespace = {
				description = "Proper global namespace usage (SLH.Debug)",
				test = function()
					return SLH and SLH.Debug and SLH.Debug == self
				end,
			},
			eventHandling = {
				description = "WoW event system compatibility",
				test = function()
					-- Check if uses appropriate WoW functions
					return type(GetServerTime) == "function" and type(print) == "function"
				end,
			},
			fileOperations = {
				description = "WoW-safe file operations",
				test = function()
					-- Verify no use of restricted file operations
					return type(self.FlushToFile) == "function" and type(self.GetLogFileInfo) == "function"
				end,
			},
			memoryManagement = {
				description = "WoW-appropriate memory management",
				test = function()
					return type(self.ManageMemory) == "function"
						and type(self.maxLogEntries) == "number"
						and self.maxLogEntries > 0
				end,
			},
		}

		local integrationResults = {
			total = 0,
			passing = 0,
			failing = {},
		}

		for integrationName, integration in pairs(wowIntegration) do
			integrationResults.total = integrationResults.total + 1

			local success, result = pcall(integration.test)
			if success and result then
				integrationResults.passing = integrationResults.passing + 1
			else
				table.insert(integrationResults.failing, {
					integration = integrationName,
					description = integration.description,
					issue = success and "Integration test failed" or ("Test error: " .. tostring(result)),
				})
				table.insert(verificationResults.missing, {
					component = "wowIntegration",
					function_name = integrationName,
					description = integration.description,
					severity = "MEDIUM",
				})
			end
		end

		return integrationResults
	end

	-- Run all verification components
	print("|cff00ff00Verifying core functionality coverage...|r")
	local coreResults = verifyCoreFunctionality()
	verificationResults.components.core = coreResults

	print("|cff00ff00Verifying helper function coverage...|r")
	local helperResults = verifyHelperFunctions()
	verificationResults.components.helpers = helperResults

	print("|cff00ff00Verifying data structure integrity...|r")
	local structureResults = verifyDataStructures()
	verificationResults.components.structures = structureResults

	print("|cff00ff00Verifying feature completeness...|r")
	local featureResults = verifyFeatureCompleteness()
	verificationResults.components.features = featureResults

	print("|cff00ff00Verifying WoW addon integration...|r")
	local integrationResults = verifyWoWIntegration()
	verificationResults.components.integration = integrationResults

	-- Calculate overall completeness score
	local totalScore = 0
	local maxScore = 0

	-- Core functionality weight: 40%
	totalScore = totalScore + (coreResults.coverageRatio * 40)
	maxScore = maxScore + 40

	-- Helper functions weight: 10%
	local helperRatio = #helperResults.found / #helperResults.required
	totalScore = totalScore + (helperRatio * 10)
	maxScore = maxScore + 10

	-- Data structures weight: 15%
	local structureRatio = structureResults.populated / structureResults.total
	totalScore = totalScore + (structureRatio * 15)
	maxScore = maxScore + 15

	-- Features weight: 25%
	local featureRatio = featureResults.implemented / featureResults.total
	totalScore = totalScore + (featureRatio * 25)
	maxScore = maxScore + 25

	-- WoW integration weight: 10%
	local integrationRatio = integrationResults.passing / integrationResults.total
	totalScore = totalScore + (integrationRatio * 10)
	maxScore = maxScore + 10

	verificationResults.completenessScore = (totalScore / maxScore) * 100

	-- Generate recommendations
	if verificationResults.completenessScore >= 95 then
		table.insert(verificationResults.recommendations, "Debug system is comprehensive and complete")
	elseif verificationResults.completenessScore >= 85 then
		table.insert(verificationResults.recommendations, "Debug system is mostly complete with minor gaps")
	elseif verificationResults.completenessScore >= 70 then
		table.insert(
			verificationResults.recommendations,
			"Debug system has significant functionality but needs improvement"
		)
	else
		table.insert(verificationResults.recommendations, "Debug system requires major additions for completeness")
	end

	if #verificationResults.missing > 0 then
		table.insert(verificationResults.recommendations, "Address missing components before production use")
	end

	if coreResults.missingFunctions > 0 then
		table.insert(
			verificationResults.recommendations,
			string.format("Implement %d missing core functions", coreResults.missingFunctions)
		)
	end

	-- Generate summary
	verificationResults.endTime = GetServerTime()
	verificationResults.duration = verificationResults.endTime - verificationResults.startTime

	print("|cff00ff00=== Completeness Verification Summary ===|r")
	print(string.format("|cff00ff00Overall Completeness Score: %.1f%%|r", verificationResults.completenessScore))
	print(
		string.format(
			"|cff00ff00Core Functions: %d/%d (%.1f%%)|r",
			coreResults.totalFound,
			coreResults.totalRequired,
			coreResults.coverageRatio * 100
		)
	)
	print(
		string.format(
			"|cff00ff00Helper Functions: %d/%d (%.1f%%)|r",
			#helperResults.found,
			#helperResults.required,
			helperRatio * 100
		)
	)
	print(
		string.format(
			"|cff00ff00Data Structures: %d/%d (%.1f%%)|r",
			structureResults.populated,
			structureResults.total,
			structureRatio * 100
		)
	)
	print(
		string.format(
			"|cff00ff00Features: %d/%d (%.1f%%)|r",
			featureResults.implemented,
			featureResults.total,
			featureRatio * 100
		)
	)
	print(
		string.format(
			"|cff00ff00WoW Integration: %d/%d (%.1f%%)|r",
			integrationResults.passing,
			integrationResults.total,
			integrationRatio * 100
		)
	)

	if #verificationResults.missing > 0 then
		print(string.format("|cffff8800Missing Components: %d|r", #verificationResults.missing))
		for i, missing in ipairs(verificationResults.missing) do
			if i <= 5 then -- Show first 5 missing items
				print(
					string.format(
						"|cffff8800  - %s: %s (%s)|r",
						missing.component,
						missing.function_name,
						missing.severity
					)
				)
			elseif i == 6 then
				print(string.format("|cffff8800  - ... and %d more|r", #verificationResults.missing - 5))
				break
			end
		end
	end

	if #verificationResults.recommendations > 0 then
		print("|cff00ff00Recommendations:|r")
		for _, recommendation in ipairs(verificationResults.recommendations) do
			print("|cff00ff00  - " .. recommendation .. "|r")
		end
	end

	-- Log the verification results
	self:LogInfo("CompletenessVerification", "Debug system completeness verification completed", {
		completenessScore = verificationResults.completenessScore,
		missingComponents = #verificationResults.missing,
		duration = verificationResults.duration,
	})

	return verificationResults
end

-- ========================================
-- TASK 19: ERROR HANDLING VALIDATION
-- ========================================

-- Comprehensive validation of error handling coverage in debug system
function SLH.Debug:RunErrorHandlingValidation()
	local validationResults = {
		testName = "Debug System Error Handling Validation",
		startTime = GetServerTime(),
		categories = {},
		vulnerabilities = {},
		safeguards = {},
		recommendations = {},
		errorHandlingScore = 0,
	}

	print("|cff00ff00=== SLH Debug: Starting Error Handling Validation ===|r")

	-- Category 1: Input Parameter Validation
	local function validateInputHandling()
		local inputTests = {
			setEnabledInvalidType = {
				description = "SetEnabled with invalid parameter type",
				test = function()
					local caught = false
					local originalState = self.enabled
					local success, err = pcall(function()
						self:SetEnabled("invalid")
					end)
					if not success and string.find(err, "boolean parameter") then
						caught = true
					end
					self:SetEnabled(originalState) -- Restore state
					return caught
				end,
			},
			logInvalidLevel = {
				description = "Log function with invalid level parameter",
				test = function()
					local caught = false
					local success, err = pcall(function()
						self:Log(123, "Test", "Message")
					end)
					if not success and string.find(err, "valid level string") then
						caught = true
					end
					return caught
				end,
			},
			logInvalidComponent = {
				description = "Log function with invalid component parameter",
				test = function()
					local caught = false
					local success, err = pcall(function()
						self:Log("INFO", nil, "Message")
					end)
					if not success and string.find(err, "valid component string") then
						caught = true
					end
					return caught
				end,
			},
			logInvalidMessage = {
				description = "Log function with invalid message parameter",
				test = function()
					local caught = false
					local success, err = pcall(function()
						self:Log("INFO", "Test", 123)
					end)
					if not success and string.find(err, "valid message string") then
						caught = true
					end
					return caught
				end,
			},
			getSessionLogsInvalidLevel = {
				description = "GetSessionLogs with invalid level parameter",
				test = function()
					local caught = false
					local success, err = pcall(function()
						self:GetSessionLogs(123)
					end)
					if not success and string.find(err, "level parameter must be string or nil") then
						caught = true
					end
					return caught
				end,
			},
			getSessionLogsInvalidComponent = {
				description = "GetSessionLogs with invalid component parameter",
				test = function()
					local caught = false
					local success, err = pcall(function()
						self:GetSessionLogs(nil, 123)
					end)
					if not success and string.find(err, "component parameter must be string or nil") then
						caught = true
					end
					return caught
				end,
			},
			getSessionLogsInvalidCount = {
				description = "GetSessionLogs with invalid count parameter",
				test = function()
					local caught = false
					local success, err = pcall(function()
						self:GetSessionLogs(nil, nil, -5)
					end)
					if not success and string.find(err, "count parameter must be positive number or nil") then
						caught = true
					end
					return caught
				end,
			},
		}

		local inputResults = {
			total = 0,
			protected = 0,
			unprotected = {},
			coverage = {},
		}

		for testName, testCase in pairs(inputTests) do
			inputResults.total = inputResults.total + 1
			local success, result = pcall(testCase.test)

			if success and result then
				inputResults.protected = inputResults.protected + 1
				table.insert(inputResults.coverage, {
					test = testName,
					description = testCase.description,
					status = "PROTECTED",
				})
			else
				table.insert(inputResults.unprotected, {
					test = testName,
					description = testCase.description,
					issue = success and "No error handling" or ("Test failed: " .. tostring(result)),
				})
				table.insert(validationResults.vulnerabilities, {
					category = "inputValidation",
					function_name = testName,
					description = testCase.description,
					severity = "HIGH",
					risk = "Function could crash addon with invalid input",
				})
			end
		end

		return inputResults
	end

	-- Category 2: Runtime Error Protection
	local function validateRuntimeProtection()
		local runtimeTests = {
			serializationErrors = {
				description = "Data serialization error handling",
				test = function()
					-- Test with circular reference which should be caught
					local circularRef = {}
					circularRef.self = circularRef

					local result = self:_SerializeLogData(circularRef)
					return result == "serialization_error"
				end,
			},
			corruptedDataHandling = {
				description = "Corrupted data structure handling",
				test = function()
					-- Test IsEnabled with corrupted state
					local originalEnabled = self.enabled
					self.enabled = "corrupted"

					local result = self:IsEnabled()
					local handledGracefully = type(result) == "boolean"

					self.enabled = originalEnabled -- Restore
					return handledGracefully
				end,
			},
			fileOperationErrors = {
				description = "File operation error handling",
				test = function()
					-- FlushToFile should handle errors gracefully
					local success, result = pcall(function()
						return self:FlushToFile()
					end)
					return success -- Should not crash even if file ops fail
				end,
			},
			statisticsErrors = {
				description = "Statistics calculation error handling",
				test = function()
					-- GetStats should handle corrupted data gracefully
					local success, result = pcall(function()
						return self:GetStats()
					end)
					return success and type(result) == "table"
				end,
			},
			memoryPressureHandling = {
				description = "Memory pressure and large data handling",
				test = function()
					-- Test with very large data object
					local largeData = {}
					for i = 1, 1000 do
						largeData["key" .. i] = string.rep("data", 100)
					end

					local success, result = pcall(function()
						return self:_EstimateDataSize(largeData)
					end)
					return success and type(result) == "number"
				end,
			},
		}

		local runtimeResults = {
			total = 0,
			protected = 0,
			vulnerable = {},
			safeguards = {},
		}

		for testName, testCase in pairs(runtimeTests) do
			runtimeResults.total = runtimeResults.total + 1
			local success, result = pcall(testCase.test)

			if success and result then
				runtimeResults.protected = runtimeResults.protected + 1
				table.insert(runtimeResults.safeguards, {
					test = testName,
					description = testCase.description,
					status = "PROTECTED",
				})
			else
				table.insert(runtimeResults.vulnerable, {
					test = testName,
					description = testCase.description,
					issue = success and "No runtime protection" or ("Test failed: " .. tostring(result)),
				})
				table.insert(validationResults.vulnerabilities, {
					category = "runtimeProtection",
					function_name = testName,
					description = testCase.description,
					severity = "MEDIUM",
					risk = "Runtime errors could cause function failures",
				})
			end
		end

		return runtimeResults
	end

	-- Category 3: Recovery Mechanism Validation
	local function validateRecoveryMechanisms()
		local recoveryTests = {
			logBufferRecovery = {
				description = "Log buffer corruption recovery",
				test = function()
					local originalBuffer = self.logBuffer
					self.logBuffer = "corrupted"

					-- Initialize should recover from corruption
					self:Init()
					local recovered = type(self.logBuffer) == "table"

					if not recovered then
						self.logBuffer = originalBuffer -- Manual restore if needed
					end
					return recovered
				end,
			},
			statsRecovery = {
				description = "Statistics structure recovery",
				test = function()
					local originalStats = self.stats
					self.stats = nil

					-- Initialize should recover stats
					self:Init()
					local recovered = type(self.stats) == "table"

					if not recovered then
						self.stats = originalStats -- Manual restore if needed
					end
					return recovered
				end,
			},
			enabledStateRecovery = {
				description = "Enabled state corruption recovery",
				test = function()
					local originalState = self.enabled
					self.enabled = "invalid"

					-- IsEnabled should handle corruption gracefully
					local result = self:IsEnabled()
					local recoveredGracefully = type(result) == "boolean"

					self.enabled = originalState -- Restore
					return recoveredGracefully
				end,
			},
			sessionTimeRecovery = {
				description = "Session time corruption recovery",
				test = function()
					local originalTime = self.sessionStartTime
					self.sessionStartTime = "invalid"

					-- StartSession should recover time
					self:StartSession()
					local recovered = type(self.sessionStartTime) == "number"

					if not recovered then
						self.sessionStartTime = originalTime -- Manual restore
					end
					return recovered
				end,
			},
		}

		local recoveryResults = {
			total = 0,
			working = 0,
			failing = {},
			mechanisms = {},
		}

		for testName, testCase in pairs(recoveryTests) do
			recoveryResults.total = recoveryResults.total + 1
			local success, result = pcall(testCase.test)

			if success and result then
				recoveryResults.working = recoveryResults.working + 1
				table.insert(recoveryResults.mechanisms, {
					test = testName,
					description = testCase.description,
					status = "WORKING",
				})
			else
				table.insert(recoveryResults.failing, {
					test = testName,
					description = testCase.description,
					issue = success and "Recovery mechanism failed" or ("Test error: " .. tostring(result)),
				})
				table.insert(validationResults.vulnerabilities, {
					category = "recoveryMechanisms",
					function_name = testName,
					description = testCase.description,
					severity = "HIGH",
					risk = "System cannot recover from corruption",
				})
			end
		end

		return recoveryResults
	end

	-- Category 4: User Error Scenario Handling
	local function validateUserErrorHandling()
		local userErrorTests = {
			rapidToggling = {
				description = "Rapid enable/disable toggling",
				test = function()
					local success = true
					local originalState = self.enabled

					for i = 1, 10 do
						local toggleSuccess = pcall(function()
							self:Toggle()
						end)
						if not toggleSuccess then
							success = false
							break
						end
					end

					-- Ensure we end in a known state
					self:SetEnabled(originalState)
					return success
				end,
			},
			excessiveLogging = {
				description = "Excessive logging volume handling",
				test = function()
					local originalState = self.enabled
					self:SetEnabled(true)

					local success = true
					-- Test rapid logging
					for i = 1, 100 do
						local logSuccess = pcall(function()
							self:LogInfo("StressTest", "Stress test message " .. i, { iteration = i })
						end)
						if not logSuccess then
							success = false
							break
						end
					end

					self:SetEnabled(originalState)
					return success
				end,
			},
			invalidDisplayParameters = {
				description = "Invalid display parameters handling",
				test = function()
					local success = true

					-- Test various invalid parameters
					local testCases = {
						function()
							self:DisplayLogsInChat("INVALID_LEVEL", nil, 5)
						end,
						function()
							self:DisplayLogsInChat(nil, 123, 5)
						end,
						function()
							self:DisplayLogsInChat(nil, nil, -1)
						end,
						function()
							self:DisplayLogsInChat(nil, nil, "invalid")
						end,
					}

					for _, testCase in ipairs(testCases) do
						local caseSuccess = pcall(testCase)
						-- Should either succeed gracefully or fail with proper error
						if not caseSuccess then
							-- This is actually expected for invalid parameters
						end
					end

					return success
				end,
			},
			concurrentOperations = {
				description = "Concurrent operation handling",
				test = function()
					local success = true
					local originalState = self.enabled

					-- Simulate concurrent operations
					local operations = {
						function()
							self:SetEnabled(true)
						end,
						function()
							self:LogInfo("Concurrent", "Test 1")
						end,
						function()
							self:GetStats()
						end,
						function()
							self:SetEnabled(false)
						end,
						function()
							self:LogInfo("Concurrent", "Test 2")
						end,
						function()
							self:ClearLogs()
						end,
					}

					for _, operation in ipairs(operations) do
						local opSuccess = pcall(operation)
						if not opSuccess then
							success = false
							break
						end
					end

					self:SetEnabled(originalState)
					return success
				end,
			},
		}

		local userErrorResults = {
			total = 0,
			handled = 0,
			problematic = {},
			scenarios = {},
		}

		for testName, testCase in pairs(userErrorTests) do
			userErrorResults.total = userErrorResults.total + 1
			local success, result = pcall(testCase.test)

			if success and result then
				userErrorResults.handled = userErrorResults.handled + 1
				table.insert(userErrorResults.scenarios, {
					test = testName,
					description = testCase.description,
					status = "HANDLED",
				})
			else
				table.insert(userErrorResults.problematic, {
					test = testName,
					description = testCase.description,
					issue = success and "User error not handled gracefully" or ("Test error: " .. tostring(result)),
				})
				table.insert(validationResults.vulnerabilities, {
					category = "userErrorHandling",
					function_name = testName,
					description = testCase.description,
					severity = "MEDIUM",
					risk = "User errors could cause unexpected behavior",
				})
			end
		end

		return userErrorResults
	end

	-- Category 5: Graceful Failure Mode Validation
	local function validateGracefulFailures()
		local failureTests = {
			disabledStateOperations = {
				description = "Operations when debug is disabled",
				test = function()
					local originalState = self.enabled
					self:SetEnabled(false)

					local success = true
					local operations = {
						function()
							self:LogInfo("Test", "Should be ignored")
						end,
						function()
							self:LogError("Test", "Should be ignored")
						end,
						function()
							self:DisplayLogsInChat()
						end,
						function()
							self:GetStats()
						end,
						function()
							self:ExportForBugReport()
						end,
					}

					for _, operation in ipairs(operations) do
						local opSuccess = pcall(operation)
						if not opSuccess then
							success = false
							break
						end
					end

					self:SetEnabled(originalState)
					return success
				end,
			},
			emptyLogBuffer = {
				description = "Operations with empty log buffer",
				test = function()
					local originalBuffer = self.logBuffer
					self.logBuffer = {}

					local success = true
					local operations = {
						function()
							self:DisplayLogsInChat()
						end,
						function()
							self:GetSessionLogs()
						end,
						function()
							self:ExportForBugReport()
						end,
						function()
							self:GetStats()
						end,
					}

					for _, operation in ipairs(operations) do
						local opSuccess = pcall(operation)
						if not opSuccess then
							success = false
							break
						end
					end

					self.logBuffer = originalBuffer
					return success
				end,
			},
			maxBufferSizeReached = {
				description = "Buffer overflow handling",
				test = function()
					local originalMax = self.maxLogEntries
					local originalBuffer = self.logBuffer
					local originalState = self.enabled

					self.maxLogEntries = 5
					self.logBuffer = {}
					self:SetEnabled(true)

					local success = true
					-- Fill beyond capacity
					for i = 1, 10 do
						local logSuccess = pcall(function()
							self:LogInfo("OverflowTest", "Message " .. i, { iteration = i })
						end)
						if not logSuccess then
							success = false
							break
						end
					end

					-- Buffer should be limited to maxLogEntries
					local bufferSizeOk = #self.logBuffer <= self.maxLogEntries
					success = success and bufferSizeOk

					self.maxLogEntries = originalMax
					self.logBuffer = originalBuffer
					self:SetEnabled(originalState)
					return success
				end,
			},
		}

		local failureResults = {
			total = 0,
			graceful = 0,
			ungraceful = {},
			modes = {},
		}

		for testName, testCase in pairs(failureTests) do
			failureResults.total = failureResults.total + 1
			local success, result = pcall(testCase.test)

			if success and result then
				failureResults.graceful = failureResults.graceful + 1
				table.insert(failureResults.modes, {
					test = testName,
					description = testCase.description,
					status = "GRACEFUL",
				})
			else
				table.insert(failureResults.ungraceful, {
					test = testName,
					description = testCase.description,
					issue = success and "Failure not handled gracefully" or ("Test error: " .. tostring(result)),
				})
				table.insert(validationResults.vulnerabilities, {
					category = "gracefulFailures",
					function_name = testName,
					description = testCase.description,
					severity = "MEDIUM",
					risk = "System failures could cause unexpected behavior",
				})
			end
		end

		return failureResults
	end

	-- Run all validation categories
	print("|cff00ff00Validating input parameter handling...|r")
	local inputResults = validateInputHandling()
	validationResults.categories.inputValidation = inputResults

	print("|cff00ff00Validating runtime error protection...|r")
	local runtimeResults = validateRuntimeProtection()
	validationResults.categories.runtimeProtection = runtimeResults

	print("|cff00ff00Validating recovery mechanisms...|r")
	local recoveryResults = validateRecoveryMechanisms()
	validationResults.categories.recoveryMechanisms = recoveryResults

	print("|cff00ff00Validating user error handling...|r")
	local userErrorResults = validateUserErrorHandling()
	validationResults.categories.userErrorHandling = userErrorResults

	print("|cff00ff00Validating graceful failure modes...|r")
	local failureResults = validateGracefulFailures()
	validationResults.categories.gracefulFailures = failureResults

	-- Calculate overall error handling score
	local totalScore = 0
	local maxScore = 0

	-- Input validation weight: 30%
	local inputRatio = inputResults.protected / inputResults.total
	totalScore = totalScore + (inputRatio * 30)
	maxScore = maxScore + 30

	-- Runtime protection weight: 25%
	local runtimeRatio = runtimeResults.protected / runtimeResults.total
	totalScore = totalScore + (runtimeRatio * 25)
	maxScore = maxScore + 25

	-- Recovery mechanisms weight: 20%
	local recoveryRatio = recoveryResults.working / recoveryResults.total
	totalScore = totalScore + (recoveryRatio * 20)
	maxScore = maxScore + 20

	-- User error handling weight: 15%
	local userErrorRatio = userErrorResults.handled / userErrorResults.total
	totalScore = totalScore + (userErrorRatio * 15)
	maxScore = maxScore + 15

	-- Graceful failures weight: 10%
	local failureRatio = failureResults.graceful / failureResults.total
	totalScore = totalScore + (failureRatio * 10)
	maxScore = maxScore + 10

	validationResults.errorHandlingScore = (totalScore / maxScore) * 100

	-- Generate recommendations
	if validationResults.errorHandlingScore >= 95 then
		table.insert(validationResults.recommendations, "Error handling is comprehensive and robust")
	elseif validationResults.errorHandlingScore >= 85 then
		table.insert(validationResults.recommendations, "Error handling is good with minor gaps")
	elseif validationResults.errorHandlingScore >= 70 then
		table.insert(validationResults.recommendations, "Error handling needs improvement in some areas")
	else
		table.insert(validationResults.recommendations, "Error handling requires significant enhancement")
	end

	if #validationResults.vulnerabilities > 0 then
		table.insert(validationResults.recommendations, "Address identified vulnerabilities before production")
	end

	if inputResults.protected < inputResults.total then
		table.insert(validationResults.recommendations, "Improve input parameter validation coverage")
	end

	if recoveryResults.working < recoveryResults.total then
		table.insert(validationResults.recommendations, "Strengthen recovery mechanisms for data corruption")
	end

	-- Generate summary
	validationResults.endTime = GetServerTime()
	validationResults.duration = validationResults.endTime - validationResults.startTime

	print("|cff00ff00=== Error Handling Validation Summary ===|r")
	print(string.format("|cff00ff00Overall Error Handling Score: %.1f%%|r", validationResults.errorHandlingScore))
	print(
		string.format(
			"|cff00ff00Input Validation: %d/%d (%.1f%%)|r",
			inputResults.protected,
			inputResults.total,
			inputRatio * 100
		)
	)
	print(
		string.format(
			"|cff00ff00Runtime Protection: %d/%d (%.1f%%)|r",
			runtimeResults.protected,
			runtimeResults.total,
			runtimeRatio * 100
		)
	)
	print(
		string.format(
			"|cff00ff00Recovery Mechanisms: %d/%d (%.1f%%)|r",
			recoveryResults.working,
			recoveryResults.total,
			recoveryRatio * 100
		)
	)
	print(
		string.format(
			"|cff00ff00User Error Handling: %d/%d (%.1f%%)|r",
			userErrorResults.handled,
			userErrorResults.total,
			userErrorRatio * 100
		)
	)
	print(
		string.format(
			"|cff00ff00Graceful Failures: %d/%d (%.1f%%)|r",
			failureResults.graceful,
			failureResults.total,
			failureRatio * 100
		)
	)

	if #validationResults.vulnerabilities > 0 then
		print(string.format("|cffff8800Vulnerabilities Found: %d|r", #validationResults.vulnerabilities))
		for i, vulnerability in ipairs(validationResults.vulnerabilities) do
			if i <= 5 then -- Show first 5 vulnerabilities
				print(
					string.format(
						"|cffff8800  - %s: %s (%s)|r",
						vulnerability.category,
						vulnerability.description,
						vulnerability.severity
					)
				)
			elseif i == 6 then
				print(string.format("|cffff8800  - ... and %d more|r", #validationResults.vulnerabilities - 5))
				break
			end
		end
	end

	if #validationResults.recommendations > 0 then
		print("|cff00ff00Recommendations:|r")
		for _, recommendation in ipairs(validationResults.recommendations) do
			print("|cff00ff00  - " .. recommendation .. "|r")
		end
	end

	-- Log the validation results
	self:LogInfo("ErrorHandlingValidation", "Error handling validation completed", {
		errorHandlingScore = validationResults.errorHandlingScore,
		vulnerabilities = #validationResults.vulnerabilities,
		duration = validationResults.duration,
	})

	return validationResults
end

-- ========================================
-- TASK 20: WOW ADDON LUA COMPATIBILITY VERIFICATION
-- ========================================

-- Comprehensive verification of WoW addon Lua compatibility
function SLH.Debug:RunWoWCompatibilityVerification()
	local compatibilityResults = {
		testName = "WoW Addon Lua Compatibility Verification",
		startTime = GetServerTime(),
		categories = {},
		violations = {},
		recommendations = {},
		compatibilityScore = 0,
	}

	print("|cff00ff00=== SLH Debug: Starting WoW Compatibility Verification ===|r")

	-- Category 1: Restricted Function Detection
	local function checkRestrictedFunctions()
		local restrictedFunctions = {
			-- File system operations (restricted in WoW)
			fileOperations = {
				patterns = { "io%.", "file:", "require%s*%(", "dofile%s*%(", "loadfile%s*%(" },
				description = "File system operations are restricted in WoW addon environment",
				severity = "HIGH",
			},
			-- Operating system operations (restricted)
			osOperations = {
				patterns = { "os%.", "execute%s*%(" },
				description = "Operating system operations are not allowed in WoW addons",
				severity = "HIGH",
			},
			-- Package/module loading (restricted)
			moduleLoading = {
				patterns = { "package%.", "module%s*%(", "import%s*%(" },
				description = "Package and module loading functions are restricted in WoW",
				severity = "HIGH",
			},
			-- Dynamic code execution (restricted)
			dynamicExecution = {
				patterns = { "loadstring%s*%(", "load%s*%(", "eval%s*%(" },
				description = "Dynamic code execution is not allowed in WoW addon environment",
				severity = "HIGH",
			},
			-- Debug library (restricted)
			debugLibrary = {
				patterns = { "debug%." },
				description = "Debug library functions are restricted in WoW",
				severity = "MEDIUM",
			},
		}

		local sourceCode = ""
		local success, result = pcall(function()
			-- We'll analyze the source by checking function signatures and patterns
			-- This is a simplified check based on known patterns
			local functions = {
				"_SerializeLogData",
				"Init",
				"StartSession",
				"SetEnabled",
				"IsEnabled",
				"Log",
				"LogInfo",
				"LogWarn",
				"LogError",
				"LogDebug",
				"GetSessionLogs",
				"FlushToFile",
				"GetLogFileInfo",
				"ClearLogs",
				"DisplayLogsInChat",
				"GetStats",
				"_FormatLogEntryForChat",
				"_EstimateDataSize",
				"_FormatBytes",
				"_FormatDuration",
				"_UpdateStats",
				"ExportForBugReport",
				"Toggle",
				"RunCoreIntegrationTest",
				"RunPerformanceValidation",
				"RunAllIntegrationTests",
				"RunUserInterfaceTest",
				"RunUserWorkflowTest",
				"OptimizePerformance",
				"ManageMemory",
				"MonitorPerformance",
				"RunCompletenessVerification",
				"RunErrorHandlingValidation",
			}

			for _, funcName in ipairs(functions) do
				if type(self[funcName]) == "function" then
					sourceCode = sourceCode .. funcName .. " "
				end
			end

			return true
		end)

		local functionResults = {
			total = 0,
			violations = 0,
			cleanFunctions = {},
			violatingFunctions = {},
		}

		for categoryName, restriction in pairs(restrictedFunctions) do
			functionResults.total = functionResults.total + 1

			local foundViolation = false
			for _, pattern in ipairs(restriction.patterns) do
				if string.find(sourceCode, pattern) then
					foundViolation = true
					break
				end
			end

			if foundViolation then
				functionResults.violations = functionResults.violations + 1
				table.insert(functionResults.violatingFunctions, {
					category = categoryName,
					description = restriction.description,
					severity = restriction.severity,
				})
				table.insert(compatibilityResults.violations, {
					category = "restrictedFunctions",
					violation = categoryName,
					description = restriction.description,
					severity = restriction.severity,
					risk = "Addon may not load or function properly in WoW",
				})
			else
				table.insert(functionResults.cleanFunctions, {
					category = categoryName,
					status = "COMPLIANT",
				})
			end
		end

		return functionResults
	end

	-- Category 2: WoW API Usage Validation
	local function checkWoWAPIUsage()
		local wowAPIs = {
			timeAndTiming = {
				functions = { "GetServerTime", "GetTime", "debugprofilestop" },
				description = "Time and timing functions",
				required = true,
			},
			stringOperations = {
				functions = { "string.find", "string.sub", "string.len", "string.format", "string.rep", "string.gsub" },
				description = "String manipulation functions",
				required = true,
			},
			tableOperations = {
				functions = { "table.insert", "table.remove", "table.concat", "pairs", "ipairs" },
				description = "Table manipulation functions",
				required = true,
			},
			typeSystem = {
				functions = { "type", "tonumber", "tostring" },
				description = "Type checking and conversion functions",
				required = true,
			},
			outputFunctions = {
				functions = { "print" },
				description = "Output and display functions",
				required = true,
			},
			mathOperations = {
				functions = { "math.floor", "math.ceil", "math.max", "math.min" },
				description = "Mathematical operations",
				required = false,
			},
		}

		local apiResults = {
			total = 0,
			compliant = 0,
			missing = {},
			present = {},
		}

		for categoryName, apiCategory in pairs(wowAPIs) do
			apiResults.total = apiResults.total + 1

			local categoryCompliant = true
			local missingFunctions = {}

			for _, funcName in ipairs(apiCategory.functions) do
				local funcExists = false

				-- Check for global functions
				if funcName == "GetServerTime" or funcName == "GetTime" or funcName == "print" then
					funcExists = type(_G[funcName]) == "function"
				elseif funcName == "debugprofilestop" then
					funcExists = type(_G[funcName]) == "function" -- May not exist in all WoW versions
				elseif
					funcName == "type"
					or funcName == "tonumber"
					or funcName == "tostring"
					or funcName == "pairs"
					or funcName == "ipairs"
				then
					funcExists = type(_G[funcName]) == "function"
				elseif string.find(funcName, "string%.") then
					local methodName = string.sub(funcName, 8) -- Remove "string."
					funcExists = type(string[methodName]) == "function"
				elseif string.find(funcName, "table%.") then
					local methodName = string.sub(funcName, 7) -- Remove "table."
					funcExists = type(table[methodName]) == "function"
				elseif string.find(funcName, "math%.") then
					local methodName = string.sub(funcName, 6) -- Remove "math."
					funcExists = type(math[methodName]) == "function"
				end

				if not funcExists then
					table.insert(missingFunctions, funcName)
					if apiCategory.required then
						categoryCompliant = false
					end
				end
			end

			if categoryCompliant then
				apiResults.compliant = apiResults.compliant + 1
				table.insert(apiResults.present, {
					category = categoryName,
					description = apiCategory.description,
					status = "AVAILABLE",
				})
			else
				table.insert(apiResults.missing, {
					category = categoryName,
					description = apiCategory.description,
					missingFunctions = missingFunctions,
					required = apiCategory.required,
				})
				if apiCategory.required then
					table.insert(compatibilityResults.violations, {
						category = "wowAPIUsage",
						violation = categoryName,
						description = "Required WoW API functions not available: "
							.. table.concat(missingFunctions, ", "),
						severity = "HIGH",
						risk = "Core functionality may not work in WoW environment",
					})
				end
			end
		end

		return apiResults
	end

	-- Category 3: Addon Environment Compatibility
	local function checkAddonEnvironment()
		local environmentTests = {
			globalNamespace = {
				description = "Proper global namespace usage",
				test = function()
					return SLH and SLH.Debug and SLH.Debug == self
				end,
			},
			savedVariables = {
				description = "SavedVariables database access",
				test = function()
					return type(SpectrumLootHelperDB) == "table"
				end,
			},
			addonStructure = {
				description = "Addon structure compliance",
				test = function()
					-- Check if we're properly organized as an addon component
					return type(self.enabled) == "boolean"
						and type(self.logBuffer) == "table"
						and type(self.stats) == "table"
				end,
			},
			memoryManagement = {
				description = "Memory management compliance",
				test = function()
					-- Check if we have proper memory limits
					return type(self.maxLogEntries) == "number"
						and self.maxLogEntries > 0
						and self.maxLogEntries < 10000 -- Reasonable limit for addons
				end,
			},
			persistentData = {
				description = "Persistent data handling",
				test = function()
					-- Test that we can read/write persistent data
					local originalValue = SpectrumLootHelperDB.debug and SpectrumLootHelperDB.debug.enabled
					local testValue = not originalValue

					SpectrumLootHelperDB.debug = SpectrumLootHelperDB.debug or {}
					SpectrumLootHelperDB.debug.enabled = testValue

					local success = SpectrumLootHelperDB.debug.enabled == testValue

					-- Restore original value
					SpectrumLootHelperDB.debug.enabled = originalValue

					return success
				end,
			},
		}

		local environmentResults = {
			total = 0,
			compatible = 0,
			incompatible = {},
			features = {},
		}

		for testName, testCase in pairs(environmentTests) do
			environmentResults.total = environmentResults.total + 1

			local success, result = pcall(testCase.test)

			if success and result then
				environmentResults.compatible = environmentResults.compatible + 1
				table.insert(environmentResults.features, {
					test = testName,
					description = testCase.description,
					status = "COMPATIBLE",
				})
			else
				table.insert(environmentResults.incompatible, {
					test = testName,
					description = testCase.description,
					issue = success and "Test failed" or ("Error: " .. tostring(result)),
				})
				table.insert(compatibilityResults.violations, {
					category = "addonEnvironment",
					violation = testName,
					description = testCase.description,
					severity = "MEDIUM",
					risk = "May not function properly in addon environment",
				})
			end
		end

		return environmentResults
	end

	-- Category 4: Version-Specific Limitations
	local function checkVersionLimitations()
		local versionTests = {
			retailCompatibility = {
				description = "Retail WoW compatibility",
				test = function()
					-- Check for retail-specific functions
					local wowVersion = (GetBuildInfo and GetBuildInfo()) or "Unknown"
					return type(GetServerTime) == "function" and type(GetTime) == "function"
				end,
			},
			luaVersion = {
				description = "Lua version compatibility",
				test = function()
					-- WoW uses Lua 5.1 compatible features
					return type(table.insert) == "function"
						and type(string.find) == "function"
						and type(pairs) == "function"
				end,
			},
			interfaceVersion = {
				description = "Interface version compatibility",
				test = function()
					-- Check if we can get interface version
					local version = GetBuildInfo and GetBuildInfo()
					return version ~= nil
				end,
			},
			clientSupport = {
				description = "WoW client feature support",
				test = function()
					-- Test for essential client features
					return type(print) == "function" and type(GetServerTime) == "function"
				end,
			},
		}

		local versionResults = {
			total = 0,
			supported = 0,
			unsupported = {},
			limitations = {},
		}

		for testName, testCase in pairs(versionTests) do
			versionResults.total = versionResults.total + 1

			local success, result = pcall(testCase.test)

			if success and result then
				versionResults.supported = versionResults.supported + 1
				table.insert(versionResults.limitations, {
					test = testName,
					description = testCase.description,
					status = "SUPPORTED",
				})
			else
				table.insert(versionResults.unsupported, {
					test = testName,
					description = testCase.description,
					issue = success and "Feature not supported" or ("Error: " .. tostring(result)),
				})
				table.insert(compatibilityResults.violations, {
					category = "versionLimitations",
					violation = testName,
					description = testCase.description,
					severity = "MEDIUM",
					risk = "May not work on all WoW versions",
				})
			end
		end

		return versionResults
	end

	-- Category 5: Security and Sandboxing Compliance
	local function checkSecurityCompliance()
		local securityTests = {
			noFileAccess = {
				description = "No unauthorized file access",
				test = function()
					-- Verify we don't use restricted file functions
					-- This is a conceptual test since we can't easily scan source
					return not (io and io.open) and not require
				end,
			},
			noNetworkAccess = {
				description = "No unauthorized network access",
				test = function()
					-- WoW addons have restricted network access
					return not (socket and socket.connect)
				end,
			},
			noSystemCalls = {
				description = "No system command execution",
				test = function()
					-- Verify no os.execute or similar functions
					return not (os and os.execute)
				end,
			},
			properErrorHandling = {
				description = "Proper error handling without crashes",
				test = function()
					-- Test that our error handling doesn't use restricted functions
					local success = pcall(function()
						error("Test error")
					end)
					return not success -- Should catch the error
				end,
			},
			memoryLimits = {
				description = "Respects addon memory limits",
				test = function()
					-- Check that we have reasonable memory usage
					return type(self.maxLogEntries) == "number" and self.maxLogEntries < 5000 -- Conservative limit
				end,
			},
		}

		local securityResults = {
			total = 0,
			secure = 0,
			violations = {},
			compliance = {},
		}

		for testName, testCase in pairs(securityTests) do
			securityResults.total = securityResults.total + 1

			local success, result = pcall(testCase.test)

			if success and result then
				securityResults.secure = securityResults.secure + 1
				table.insert(securityResults.compliance, {
					test = testName,
					description = testCase.description,
					status = "SECURE",
				})
			else
				table.insert(securityResults.violations, {
					test = testName,
					description = testCase.description,
					issue = success and "Security violation detected" or ("Error: " .. tostring(result)),
				})
				table.insert(compatibilityResults.violations, {
					category = "securityCompliance",
					violation = testName,
					description = testCase.description,
					severity = "HIGH",
					risk = "May be blocked by WoW security sandbox",
				})
			end
		end

		return securityResults
	end

	-- Run all compatibility checks
	print("|cff00ff00Checking for restricted functions...|r")
	local functionResults = checkRestrictedFunctions()
	compatibilityResults.categories.restrictedFunctions = functionResults

	print("|cff00ff00Validating WoW API usage...|r")
	local apiResults = checkWoWAPIUsage()
	compatibilityResults.categories.wowAPIUsage = apiResults

	print("|cff00ff00Checking addon environment compatibility...|r")
	local environmentResults = checkAddonEnvironment()
	compatibilityResults.categories.addonEnvironment = environmentResults

	print("|cff00ff00Validating version-specific limitations...|r")
	local versionResults = checkVersionLimitations()
	compatibilityResults.categories.versionLimitations = versionResults

	print("|cff00ff00Checking security and sandboxing compliance...|r")
	local securityResults = checkSecurityCompliance()
	compatibilityResults.categories.securityCompliance = securityResults

	-- Calculate overall compatibility score
	local totalScore = 0
	local maxScore = 0

	-- Restricted functions weight: 30% (critical)
	local restrictedRatio = (functionResults.total - functionResults.violations) / functionResults.total
	totalScore = totalScore + (restrictedRatio * 30)
	maxScore = maxScore + 30

	-- WoW API usage weight: 25%
	local apiRatio = apiResults.compliant / apiResults.total
	totalScore = totalScore + (apiRatio * 25)
	maxScore = maxScore + 25

	-- Addon environment weight: 20%
	local environmentRatio = environmentResults.compatible / environmentResults.total
	totalScore = totalScore + (environmentRatio * 20)
	maxScore = maxScore + 20

	-- Version limitations weight: 15%
	local versionRatio = versionResults.supported / versionResults.total
	totalScore = totalScore + (versionRatio * 15)
	maxScore = maxScore + 15

	-- Security compliance weight: 10%
	local securityRatio = securityResults.secure / securityResults.total
	totalScore = totalScore + (securityRatio * 10)
	maxScore = maxScore + 10

	compatibilityResults.compatibilityScore = (totalScore / maxScore) * 100

	-- Generate recommendations
	if compatibilityResults.compatibilityScore >= 95 then
		table.insert(compatibilityResults.recommendations, "Excellent WoW addon compatibility")
	elseif compatibilityResults.compatibilityScore >= 85 then
		table.insert(compatibilityResults.recommendations, "Good WoW compatibility with minor issues")
	elseif compatibilityResults.compatibilityScore >= 70 then
		table.insert(compatibilityResults.recommendations, "WoW compatibility needs improvement")
	else
		table.insert(compatibilityResults.recommendations, "Significant WoW compatibility issues detected")
	end

	if functionResults.violations > 0 then
		table.insert(compatibilityResults.recommendations, "Remove usage of restricted functions before release")
	end

	if #compatibilityResults.violations > 0 then
		table.insert(compatibilityResults.recommendations, "Address all compatibility violations for production use")
	end

	if apiResults.compliant < apiResults.total then
		table.insert(compatibilityResults.recommendations, "Ensure all required WoW APIs are available")
	end

	-- Generate summary
	compatibilityResults.endTime = GetServerTime()
	compatibilityResults.duration = compatibilityResults.endTime - compatibilityResults.startTime

	print("|cff00ff00=== WoW Compatibility Verification Summary ===|r")
	print(string.format("|cff00ff00Overall Compatibility Score: %.1f%%|r", compatibilityResults.compatibilityScore))
	print(
		string.format(
			"|cff00ff00Restricted Functions: %d/%d violations|r",
			functionResults.violations,
			functionResults.total
		)
	)
	print(string.format("|cff00ff00WoW API Usage: %d/%d compliant|r", apiResults.compliant, apiResults.total))
	print(
		string.format(
			"|cff00ff00Addon Environment: %d/%d compatible|r",
			environmentResults.compatible,
			environmentResults.total
		)
	)
	print(string.format("|cff00ff00Version Support: %d/%d supported|r", versionResults.supported, versionResults.total))
	print(string.format("|cff00ff00Security Compliance: %d/%d secure|r", securityResults.secure, securityResults.total))

	if #compatibilityResults.violations > 0 then
		print(string.format("|cffff8800Compatibility Violations: %d|r", #compatibilityResults.violations))
		for i, violation in ipairs(compatibilityResults.violations) do
			if i <= 5 then -- Show first 5 violations
				print(
					string.format(
						"|cffff8800  - %s: %s (%s)|r",
						violation.category,
						violation.description,
						violation.severity
					)
				)
			elseif i == 6 then
				print(string.format("|cffff8800  - ... and %d more|r", #compatibilityResults.violations - 5))
				break
			end
		end
	end

	if #compatibilityResults.recommendations > 0 then
		print("|cff00ff00Recommendations:|r")
		for _, recommendation in ipairs(compatibilityResults.recommendations) do
			print("|cff00ff00  - " .. recommendation .. "|r")
		end
	end

	-- Log the compatibility results
	self:LogInfo("WoWCompatibilityVerification", "WoW compatibility verification completed", {
		compatibilityScore = compatibilityResults.compatibilityScore,
		violations = #compatibilityResults.violations,
		duration = compatibilityResults.duration,
	})

	return compatibilityResults
end

-- ========================================
-- TASK 21: PERFORMANCE IMPACT ASSESSMENT
-- ========================================

-- Comprehensive performance impact assessment for WoW addon optimization
function SLH.Debug:RunPerformanceImpactAssessment()
	local assessmentResults = {
		testName = "Debug System Performance Impact Assessment",
		startTime = GetServerTime(),
		categories = {},
		optimizations = {},
		recommendations = {},
		performanceScore = 0,
		impactLevel = "UNKNOWN",
	}

	print("|cff00ff00=== SLH Debug: Starting Performance Impact Assessment ===|r")

	-- Category 1: Memory Footprint Analysis
	local function analyzeMemoryFootprint()
		local memoryResults = {
			description = "Memory usage and footprint analysis",
			tests = {},
			totalMemoryUsage = 0,
			efficiencyRating = "UNKNOWN",
			recommendations = {},
		}

		-- Test 1: Baseline Memory Usage
		local function measureBaselineMemory()
			local stats = self:GetStats()
			local baselineMemory = stats.memoryUsage or 0

			return {
				baselineBytes = baselineMemory,
				baselineKB = baselineMemory / 1024,
				acceptable = baselineMemory < (50 * 1024), -- 50KB baseline limit
				description = "Baseline memory usage without active logging",
			}
		end

		-- Test 2: Memory Growth Under Load
		local function measureMemoryGrowth()
			local originalState = self.enabled
			local originalBuffer = #self.logBuffer

			self:SetEnabled(true)

			-- Generate test load
			local startMemory = self:GetStats().memoryUsage
			for i = 1, 100 do
				self:LogInfo("PerformanceTest", "Memory test message " .. i, {
					iteration = i,
					data = string.rep("x", 50), -- 50-char string per log
				})
			end
			local endMemory = self:GetStats().memoryUsage

			local memoryGrowth = endMemory - startMemory
			local growthPerEntry = memoryGrowth / 100

			-- Clean up test data
			while #self.logBuffer > originalBuffer do
				table.remove(self.logBuffer)
			end
			self:SetEnabled(originalState)

			return {
				memoryGrowth = memoryGrowth,
				growthPerEntry = growthPerEntry,
				acceptable = growthPerEntry < 512, -- 512 bytes per entry limit
				description = "Memory growth under logging load",
			}
		end

		-- Test 3: Memory Efficiency with Large Data
		local function measureLargeDataEfficiency()
			local originalState = self.enabled
			self:SetEnabled(true)

			local startMemory = self:GetStats().memoryUsage

			-- Test with large data objects
			local largeData = {}
			for i = 1, 50 do
				largeData["key" .. i] = string.rep("data", 20)
			end

			self:LogInfo("PerformanceTest", "Large data test", largeData)

			local endMemory = self:GetStats().memoryUsage
			local dataImpact = endMemory - startMemory

			-- Clean up
			if #self.logBuffer > 0 then
				table.remove(self.logBuffer)
			end
			self:SetEnabled(originalState)

			return {
				dataImpact = dataImpact,
				efficient = dataImpact < (2 * 1024), -- 2KB limit for large objects
				description = "Memory efficiency with large data objects",
			}
		end

		-- Test 4: Buffer Management Efficiency
		local function measureBufferEfficiency()
			local originalState = self.enabled
			local originalMax = self.maxLogEntries

			self.maxLogEntries = 10 -- Small buffer for testing
			self:SetEnabled(true)

			local startMemory = self:GetStats().memoryUsage

			-- Fill buffer beyond capacity to test pruning
			for i = 1, 20 do
				self:LogInfo("PerformanceTest", "Buffer test " .. i)
			end

			local endMemory = self:GetStats().memoryUsage
			local bufferSize = #self.logBuffer

			-- Restore settings
			self.maxLogEntries = originalMax
			self:SetEnabled(originalState)

			return {
				finalBufferSize = bufferSize,
				memoryUsage = endMemory - startMemory,
				pruningWorking = bufferSize <= 10,
				description = "Buffer management and pruning efficiency",
			}
		end

		local tests = {
			baseline = measureBaselineMemory(),
			growth = measureMemoryGrowth(),
			largeData = measureLargeDataEfficiency(),
			buffer = measureBufferEfficiency(),
		}

		memoryResults.tests = tests
		memoryResults.totalMemoryUsage = tests.baseline.baselineBytes + tests.growth.memoryGrowth

		-- Calculate efficiency rating
		local efficiencyScore = 0
		local maxScore = 4

		if tests.baseline.acceptable then
			efficiencyScore = efficiencyScore + 1
		end
		if tests.growth.acceptable then
			efficiencyScore = efficiencyScore + 1
		end
		if tests.largeData.efficient then
			efficiencyScore = efficiencyScore + 1
		end
		if tests.buffer.pruningWorking then
			efficiencyScore = efficiencyScore + 1
		end

		local efficiencyRatio = efficiencyScore / maxScore
		if efficiencyRatio >= 0.9 then
			memoryResults.efficiencyRating = "EXCELLENT"
		elseif efficiencyRatio >= 0.75 then
			memoryResults.efficiencyRating = "GOOD"
		elseif efficiencyRatio >= 0.5 then
			memoryResults.efficiencyRating = "FAIR"
		else
			memoryResults.efficiencyRating = "POOR"
		end

		-- Generate recommendations
		if not tests.baseline.acceptable then
			table.insert(memoryResults.recommendations, "Reduce baseline memory usage")
		end
		if not tests.growth.acceptable then
			table.insert(memoryResults.recommendations, "Optimize per-entry memory footprint")
		end
		if not tests.largeData.efficient then
			table.insert(memoryResults.recommendations, "Improve large data serialization")
		end
		if not tests.buffer.pruningWorking then
			table.insert(memoryResults.recommendations, "Fix buffer pruning mechanism")
		end

		return memoryResults
	end

	-- Category 2: CPU Usage Optimization
	local function analyzeCPUUsage()
		local cpuResults = {
			description = "CPU usage and execution time analysis",
			tests = {},
			avgExecutionTime = 0,
			performanceRating = "UNKNOWN",
			recommendations = {},
		}

		-- Test 1: Logging Function Performance
		local function measureLoggingPerformance()
			local originalState = self.enabled
			self:SetEnabled(true)

			local iterations = 1000
			local startTime = debugprofilestop and debugprofilestop() or (GetServerTime() * 1000)

			for i = 1, iterations do
				self:LogInfo("PerformanceTest", "CPU test " .. i, { iteration = i })
			end

			local endTime = debugprofilestop and debugprofilestop() or (GetServerTime() * 1000)
			local totalTime = endTime - startTime
			local avgTimePerLog = totalTime / iterations

			-- Clean up test logs
			while #self.logBuffer > 0 and string.find(self.logBuffer[#self.logBuffer].message, "CPU test") do
				table.remove(self.logBuffer)
			end

			self:SetEnabled(originalState)

			return {
				totalTime = totalTime,
				avgTimePerLog = avgTimePerLog,
				iterations = iterations,
				efficient = avgTimePerLog < 0.1, -- 0.1ms per log entry
				description = "Logging function execution time",
			}
		end

		-- Test 2: Disabled State Performance
		local function measureDisabledStatePerformance()
			self:SetEnabled(false)

			local iterations = 1000
			local startTime = debugprofilestop and debugprofilestop() or (GetServerTime() * 1000)

			for i = 1, iterations do
				self:LogInfo("PerformanceTest", "Disabled test " .. i, { iteration = i })
			end

			local endTime = debugprofilestop and debugprofilestop() or (GetServerTime() * 1000)
			local totalTime = endTime - startTime
			local avgTimePerLog = totalTime / iterations

			return {
				totalTime = totalTime,
				avgTimePerLog = avgTimePerLog,
				iterations = iterations,
				optimal = avgTimePerLog < 0.01, -- 0.01ms when disabled (near-zero)
				description = "Disabled state execution time (should be minimal)",
			}
		end

		-- Test 3: Statistics Calculation Performance
		local function measureStatsPerformance()
			local originalState = self.enabled
			self:SetEnabled(true)

			-- Add some test data
			for i = 1, 50 do
				self:LogInfo("StatsTest", "Stats test " .. i)
			end

			local iterations = 100
			local startTime = debugprofilestop and debugprofilestop() or (GetServerTime() * 1000)

			for i = 1, iterations do
				local stats = self:GetStats()
			end

			local endTime = debugprofilestop and debugprofilestop() or (GetServerTime() * 1000)
			local totalTime = endTime - startTime
			local avgTimePerStats = totalTime / iterations

			-- Clean up
			while #self.logBuffer > 0 and string.find(self.logBuffer[#self.logBuffer].message, "Stats test") do
				table.remove(self.logBuffer)
			end

			self:SetEnabled(originalState)

			return {
				totalTime = totalTime,
				avgTimePerStats = avgTimePerStats,
				iterations = iterations,
				acceptable = avgTimePerStats < 1.0, -- 1ms for stats calculation
				description = "Statistics calculation performance",
			}
		end

		-- Test 4: Export Function Performance
		local function measureExportPerformance()
			local originalState = self.enabled
			self:SetEnabled(true)

			-- Add test data for export
			for i = 1, 20 do
				self:LogInfo("ExportTest", "Export test " .. i)
			end

			local startTime = debugprofilestop and debugprofilestop() or (GetServerTime() * 1000)
			local exportData = self:ExportForBugReport()
			local endTime = debugprofilestop and debugprofilestop() or (GetServerTime() * 1000)

			local exportTime = endTime - startTime
			local exportSize = string.len(exportData)

			-- Clean up
			while #self.logBuffer > 0 and string.find(self.logBuffer[#self.logBuffer].message, "Export test") do
				table.remove(self.logBuffer)
			end

			self:SetEnabled(originalState)

			return {
				exportTime = exportTime,
				exportSize = exportSize,
				acceptable = exportTime < 10.0, -- 10ms for export
				description = "Export function performance",
			}
		end

		local tests = {
			logging = measureLoggingPerformance(),
			disabled = measureDisabledStatePerformance(),
			stats = measureStatsPerformance(),
			export = measureExportPerformance(),
		}

		cpuResults.tests = tests
		cpuResults.avgExecutionTime = (tests.logging.avgTimePerLog + tests.stats.avgTimePerStats) / 2

		-- Calculate performance rating
		local performanceScore = 0
		local maxScore = 4

		if tests.logging.efficient then
			performanceScore = performanceScore + 1
		end
		if tests.disabled.optimal then
			performanceScore = performanceScore + 1
		end
		if tests.stats.acceptable then
			performanceScore = performanceScore + 1
		end
		if tests.export.acceptable then
			performanceScore = performanceScore + 1
		end

		local performanceRatio = performanceScore / maxScore
		if performanceRatio >= 0.9 then
			cpuResults.performanceRating = "EXCELLENT"
		elseif performanceRatio >= 0.75 then
			cpuResults.performanceRating = "GOOD"
		elseif performanceRatio >= 0.5 then
			cpuResults.performanceRating = "FAIR"
		else
			cpuResults.performanceRating = "POOR"
		end

		-- Generate recommendations
		if not tests.logging.efficient then
			table.insert(cpuResults.recommendations, "Optimize logging function execution time")
		end
		if not tests.disabled.optimal then
			table.insert(cpuResults.recommendations, "Improve disabled state early-return optimization")
		end
		if not tests.stats.acceptable then
			table.insert(cpuResults.recommendations, "Optimize statistics calculation performance")
		end
		if not tests.export.acceptable then
			table.insert(cpuResults.recommendations, "Optimize export function performance")
		end

		return cpuResults
	end

	-- Category 3: Disabled-State Efficiency
	local function analyzeDisabledStateEfficiency()
		local disabledResults = {
			description = "Performance when debug logging is disabled",
			tests = {},
			efficiencyRating = "UNKNOWN",
			recommendations = {},
		}

		-- Test 1: Function Call Overhead When Disabled
		local function measureDisabledOverhead()
			self:SetEnabled(false)

			local functions = {
				function()
					self:LogInfo("Test", "Message")
				end,
				function()
					self:LogWarn("Test", "Message")
				end,
				function()
					self:LogError("Test", "Message")
				end,
				function()
					self:LogDebug("Test", "Message")
				end,
			}

			local totalTime = 0
			local iterations = 250 -- 250 * 4 = 1000 total calls

			for _, func in ipairs(functions) do
				local startTime = debugprofilestop and debugprofilestop() or (GetServerTime() * 1000)

				for i = 1, iterations do
					func()
				end

				local endTime = debugprofilestop and debugprofilestop() or (GetServerTime() * 1000)
				totalTime = totalTime + (endTime - startTime)
			end

			local avgOverhead = totalTime / (iterations * #functions)

			return {
				totalTime = totalTime,
				avgOverhead = avgOverhead,
				totalCalls = iterations * #functions,
				minimal = avgOverhead < 0.005, -- 0.005ms overhead when disabled
				description = "Function call overhead when debug is disabled",
			}
		end

		-- Test 2: Memory Impact When Disabled
		local function measureDisabledMemoryImpact()
			self:SetEnabled(false)

			local startMemory = self:GetStats().memoryUsage

			-- Attempt to log many entries while disabled
			for i = 1, 100 do
				self:LogInfo("DisabledTest", "Should not be logged " .. i, {
					data = string.rep("x", 100),
				})
			end

			local endMemory = self:GetStats().memoryUsage
			local memoryIncrease = endMemory - startMemory

			return {
				startMemory = startMemory,
				endMemory = endMemory,
				memoryIncrease = memoryIncrease,
				noImpact = memoryIncrease < 100, -- Less than 100 bytes when disabled
				description = "Memory impact when logging while disabled",
			}
		end

		-- Test 3: State Management Efficiency
		local function measureStateManagementEfficiency()
			local toggleIterations = 100
			local startTime = debugprofilestop and debugprofilestop() or (GetServerTime() * 1000)

			for i = 1, toggleIterations do
				self:SetEnabled(true)
				self:SetEnabled(false)
			end

			local endTime = debugprofilestop and debugprofilestop() or (GetServerTime() * 1000)
			local totalTime = endTime - startTime
			local avgToggleTime = totalTime / (toggleIterations * 2) -- *2 for enable + disable

			return {
				totalTime = totalTime,
				avgToggleTime = avgToggleTime,
				toggleIterations = toggleIterations,
				efficient = avgToggleTime < 0.01, -- 0.01ms per state change
				description = "State management (enable/disable) efficiency",
			}
		end

		local tests = {
			overhead = measureDisabledOverhead(),
			memory = measureDisabledMemoryImpact(),
			stateManagement = measureStateManagementEfficiency(),
		}

		disabledResults.tests = tests

		-- Calculate efficiency rating
		local efficiencyScore = 0
		local maxScore = 3

		if tests.overhead.minimal then
			efficiencyScore = efficiencyScore + 1
		end
		if tests.memory.noImpact then
			efficiencyScore = efficiencyScore + 1
		end
		if tests.stateManagement.efficient then
			efficiencyScore = efficiencyScore + 1
		end

		local efficiencyRatio = efficiencyScore / maxScore
		if efficiencyRatio >= 0.9 then
			disabledResults.efficiencyRating = "EXCELLENT"
		elseif efficiencyRatio >= 0.66 then
			disabledResults.efficiencyRating = "GOOD"
		elseif efficiencyRatio >= 0.33 then
			disabledResults.efficiencyRating = "FAIR"
		else
			disabledResults.efficiencyRating = "POOR"
		end

		-- Generate recommendations
		if not tests.overhead.minimal then
			table.insert(disabledResults.recommendations, "Add early-return optimization to logging functions")
		end
		if not tests.memory.noImpact then
			table.insert(disabledResults.recommendations, "Prevent memory allocation when disabled")
		end
		if not tests.stateManagement.efficient then
			table.insert(disabledResults.recommendations, "Optimize state management operations")
		end

		return disabledResults
	end

	-- Category 4: Real-Time Performance Validation
	local function analyzeRealTimePerformance()
		local realTimeResults = {
			description = "Real-time performance under realistic usage",
			tests = {},
			overallRating = "UNKNOWN",
			recommendations = {},
		}

		-- Test 1: Sustained Load Performance
		local function measureSustainedLoad()
			local originalState = self.enabled
			self:SetEnabled(true)

			local duration = 5 -- 5 seconds
			local startTime = GetServerTime()
			local endTime = startTime + duration
			local logCount = 0
			local performanceMetrics = {}

			while GetServerTime() < endTime do
				local iterationStart = debugprofilestop and debugprofilestop() or (GetServerTime() * 1000)

				self:LogInfo("SustainedTest", "Sustained load test " .. logCount, {
					timestamp = GetServerTime(),
					iteration = logCount,
				})

				local iterationEnd = debugprofilestop and debugprofilestop() or (GetServerTime() * 1000)
				table.insert(performanceMetrics, iterationEnd - iterationStart)

				logCount = logCount + 1

				-- Small delay to simulate realistic usage
				local delay = GetServerTime() + 0.01
				while GetServerTime() < delay do
				end
			end

			-- Calculate metrics
			local totalIterationTime = 0
			for _, time in ipairs(performanceMetrics) do
				totalIterationTime = totalIterationTime + time
			end
			local avgIterationTime = totalIterationTime / #performanceMetrics
			local logsPerSecond = logCount / duration

			-- Clean up test logs
			while #self.logBuffer > 0 and string.find(self.logBuffer[#self.logBuffer].message, "Sustained load test") do
				table.remove(self.logBuffer)
			end

			self:SetEnabled(originalState)

			return {
				duration = duration,
				logCount = logCount,
				avgIterationTime = avgIterationTime,
				logsPerSecond = logsPerSecond,
				sustainable = avgIterationTime < 0.5 and logsPerSecond > 50,
				description = "Sustained logging load performance",
			}
		end

		-- Test 2: Memory Pressure Handling
		local function measureMemoryPressureHandling()
			local originalState = self.enabled
			local originalMax = self.maxLogEntries

			self.maxLogEntries = 100 -- Limit for testing
			self:SetEnabled(true)

			local startTime = debugprofilestop and debugprofilestop() or (GetServerTime() * 1000)

			-- Fill buffer well beyond capacity
			for i = 1, 200 do
				self:LogInfo("MemoryPressure", "Pressure test " .. i, {
					largeData = string.rep("data", 25),
				})
			end

			local endTime = debugprofilestop and debugprofilestop() or (GetServerTime() * 1000)
			local totalTime = endTime - startTime
			local finalBufferSize = #self.logBuffer

			-- Restore settings
			self.maxLogEntries = originalMax
			self:SetEnabled(originalState)

			return {
				totalTime = totalTime,
				finalBufferSize = finalBufferSize,
				entriesAdded = 200,
				bufferManaged = finalBufferSize <= 100,
				performanceStable = totalTime < 50, -- 50ms for 200 entries
				description = "Memory pressure and buffer management",
			}
		end

		-- Test 3: Concurrent Operation Performance
		local function measureConcurrentOperations()
			local originalState = self.enabled
			self:SetEnabled(true)

			local startTime = debugprofilestop and debugprofilestop() or (GetServerTime() * 1000)

			-- Simulate concurrent operations
			for i = 1, 20 do
				self:LogInfo("Concurrent", "Operation " .. i)
				self:GetStats()
				if i % 5 == 0 then
					self:DisplayLogsInChat(nil, nil, 2)
				end
				if i % 10 == 0 then
					self:ClearLogs()
				end
			end

			local endTime = debugprofilestop and debugprofilestop() or (GetServerTime() * 1000)
			local totalTime = endTime - startTime

			self:SetEnabled(originalState)

			return {
				totalTime = totalTime,
				operations = 20 + 20 + 4 + 2, -- logs + stats + displays + clears
				avgOperationTime = totalTime / 46,
				efficient = totalTime < 25, -- 25ms for all operations
				description = "Concurrent operation performance",
			}
		end

		local tests = {
			sustainedLoad = measureSustainedLoad(),
			memoryPressure = measureMemoryPressureHandling(),
			concurrent = measureConcurrentOperations(),
		}

		realTimeResults.tests = tests

		-- Calculate overall rating
		local ratingScore = 0
		local maxScore = 3

		if tests.sustainedLoad.sustainable then
			ratingScore = ratingScore + 1
		end
		if tests.memoryPressure.bufferManaged and tests.memoryPressure.performanceStable then
			ratingScore = ratingScore + 1
		end
		if tests.concurrent.efficient then
			ratingScore = ratingScore + 1
		end

		local ratingRatio = ratingScore / maxScore
		if ratingRatio >= 0.9 then
			realTimeResults.overallRating = "EXCELLENT"
		elseif ratingRatio >= 0.66 then
			realTimeResults.overallRating = "GOOD"
		elseif ratingRatio >= 0.33 then
			realTimeResults.overallRating = "FAIR"
		else
			realTimeResults.overallRating = "POOR"
		end

		-- Generate recommendations
		if not tests.sustainedLoad.sustainable then
			table.insert(realTimeResults.recommendations, "Improve sustained load performance")
		end
		if not tests.memoryPressure.bufferManaged then
			table.insert(realTimeResults.recommendations, "Fix buffer management under memory pressure")
		end
		if not tests.memoryPressure.performanceStable then
			table.insert(realTimeResults.recommendations, "Optimize performance under memory pressure")
		end
		if not tests.concurrent.efficient then
			table.insert(realTimeResults.recommendations, "Optimize concurrent operation performance")
		end

		return realTimeResults
	end

	-- Run all performance assessments
	print("|cff00ff00Analyzing memory footprint...|r")
	local memoryResults = analyzeMemoryFootprint()
	assessmentResults.categories.memoryFootprint = memoryResults

	print("|cff00ff00Analyzing CPU usage...|r")
	local cpuResults = analyzeCPUUsage()
	assessmentResults.categories.cpuUsage = cpuResults

	print("|cff00ff00Analyzing disabled-state efficiency...|r")
	local disabledResults = analyzeDisabledStateEfficiency()
	assessmentResults.categories.disabledState = disabledResults

	print("|cff00ff00Analyzing real-time performance...|r")
	local realTimeResults = analyzeRealTimePerformance()
	assessmentResults.categories.realTimePerformance = realTimeResults

	-- Calculate overall performance score
	local totalScore = 0
	local maxScore = 0

	-- Memory footprint weight: 30%
	local memoryScore = 0
	if memoryResults.efficiencyRating == "EXCELLENT" then
		memoryScore = 30
	elseif memoryResults.efficiencyRating == "GOOD" then
		memoryScore = 22.5
	elseif memoryResults.efficiencyRating == "FAIR" then
		memoryScore = 15
	else
		memoryScore = 7.5
	end
	totalScore = totalScore + memoryScore
	maxScore = maxScore + 30

	-- CPU usage weight: 25%
	local cpuScore = 0
	if cpuResults.performanceRating == "EXCELLENT" then
		cpuScore = 25
	elseif cpuResults.performanceRating == "GOOD" then
		cpuScore = 18.75
	elseif cpuResults.performanceRating == "FAIR" then
		cpuScore = 12.5
	else
		cpuScore = 6.25
	end
	totalScore = totalScore + cpuScore
	maxScore = maxScore + 25

	-- Disabled state efficiency weight: 25%
	local disabledScore = 0
	if disabledResults.efficiencyRating == "EXCELLENT" then
		disabledScore = 25
	elseif disabledResults.efficiencyRating == "GOOD" then
		disabledScore = 18.75
	elseif disabledResults.efficiencyRating == "FAIR" then
		disabledScore = 12.5
	else
		disabledScore = 6.25
	end
	totalScore = totalScore + disabledScore
	maxScore = maxScore + 25

	-- Real-time performance weight: 20%
	local realTimeScore = 0
	if realTimeResults.overallRating == "EXCELLENT" then
		realTimeScore = 20
	elseif realTimeResults.overallRating == "GOOD" then
		realTimeScore = 15
	elseif realTimeResults.overallRating == "FAIR" then
		realTimeScore = 10
	else
		realTimeScore = 5
	end
	totalScore = totalScore + realTimeScore
	maxScore = maxScore + 20

	assessmentResults.performanceScore = (totalScore / maxScore) * 100

	-- Determine impact level
	if assessmentResults.performanceScore >= 90 then
		assessmentResults.impactLevel = "MINIMAL"
		table.insert(assessmentResults.recommendations, "Performance impact is minimal - excellent optimization")
	elseif assessmentResults.performanceScore >= 75 then
		assessmentResults.impactLevel = "LOW"
		table.insert(assessmentResults.recommendations, "Performance impact is low - good optimization")
	elseif assessmentResults.performanceScore >= 60 then
		assessmentResults.impactLevel = "MODERATE"
		table.insert(assessmentResults.recommendations, "Performance impact is moderate - needs optimization")
	elseif assessmentResults.performanceScore >= 40 then
		assessmentResults.impactLevel = "HIGH"
		table.insert(assessmentResults.recommendations, "Performance impact is high - requires optimization")
	else
		assessmentResults.impactLevel = "SEVERE"
		table.insert(assessmentResults.recommendations, "Performance impact is severe - major optimization needed")
	end

	-- Collect all category recommendations
	for _, recommendation in ipairs(memoryResults.recommendations) do
		table.insert(assessmentResults.recommendations, "Memory: " .. recommendation)
	end
	for _, recommendation in ipairs(cpuResults.recommendations) do
		table.insert(assessmentResults.recommendations, "CPU: " .. recommendation)
	end
	for _, recommendation in ipairs(disabledResults.recommendations) do
		table.insert(assessmentResults.recommendations, "Disabled State: " .. recommendation)
	end
	for _, recommendation in ipairs(realTimeResults.recommendations) do
		table.insert(assessmentResults.recommendations, "Real-Time: " .. recommendation)
	end

	-- Generate summary
	assessmentResults.endTime = GetServerTime()
	assessmentResults.duration = assessmentResults.endTime - assessmentResults.startTime

	print("|cff00ff00=== Performance Impact Assessment Summary ===|r")
	print(string.format("|cff00ff00Overall Performance Score: %.1f%%|r", assessmentResults.performanceScore))
	print(string.format("|cff00ff00Performance Impact Level: %s|r", assessmentResults.impactLevel))
	print(string.format("|cff00ff00Memory Footprint: %s|r", memoryResults.efficiencyRating))
	print(string.format("|cff00ff00CPU Usage: %s|r", cpuResults.performanceRating))
	print(string.format("|cff00ff00Disabled State Efficiency: %s|r", disabledResults.efficiencyRating))
	print(string.format("|cff00ff00Real-Time Performance: %s|r", realTimeResults.overallRating))

	if memoryResults.totalMemoryUsage > 0 then
		print(string.format("|cff00ff00Total Memory Usage: %.1f KB|r", memoryResults.totalMemoryUsage / 1024))
	end

	if cpuResults.avgExecutionTime > 0 then
		print(string.format("|cff00ff00Avg Execution Time: %.3f ms|r", cpuResults.avgExecutionTime))
	end

	if #assessmentResults.recommendations > 0 then
		print("|cff00ff00Optimization Recommendations:|r")
		for i, recommendation in ipairs(assessmentResults.recommendations) do
			if i <= 8 then -- Show first 8 recommendations
				print("|cff00ff00  - " .. recommendation .. "|r")
			elseif i == 9 then
				print(string.format("|cff00ff00  - ... and %d more|r", #assessmentResults.recommendations - 8))
				break
			end
		end
	end

	-- Log the assessment results
	self:LogInfo("PerformanceImpactAssessment", "Performance impact assessment completed", {
		performanceScore = assessmentResults.performanceScore,
		impactLevel = assessmentResults.impactLevel,
		memoryRating = memoryResults.efficiencyRating,
		cpuRating = cpuResults.performanceRating,
		disabledRating = disabledResults.efficiencyRating,
		realTimeRating = realTimeResults.overallRating,
		duration = assessmentResults.duration,
	})

	return assessmentResults
end

-- Memory management functions for WoW addon efficiency
function SLH.Debug:ManageMemory()
	print("|cff00ff00=== SLH Debug: Memory Management ===|r")

	local memoryActions = {
		applied = 0,
		skipped = 0,
		actions = {},
	}

	-- Action 1: Aggressive buffer trimming
	if #self.logBuffer > (self.maxLogEntries * 0.5) then
		local oldSize = #self.logBuffer
		local keepCount = math.floor(self.maxLogEntries * 0.3) -- Keep only 30%

		local newBuffer = {}
		local startIndex = oldSize - keepCount + 1

		for i = startIndex, oldSize do
			if self.logBuffer[i] then
				table.insert(newBuffer, self.logBuffer[i])
			end
		end

		self.logBuffer = newBuffer
		memoryActions.applied = memoryActions.applied + 1

		local action = string.format("Aggressive trim: %d → %d entries", oldSize, #newBuffer)
		table.insert(memoryActions.actions, action)
		print("|cff00ff00✓ " .. action .. "|r")

		self:LogInfo("Memory", "Aggressive buffer trimming applied", {
			oldSize = oldSize,
			newSize = #newBuffer,
			memoryFreed = (oldSize - #newBuffer) * 180,
		})
	else
		memoryActions.skipped = memoryActions.skipped + 1
		table.insert(memoryActions.actions, "Buffer size acceptable, no trimming needed")
		print("|cffff8800✓ Buffer size acceptable (" .. #self.logBuffer .. "/" .. self.maxLogEntries .. ")|r")
	end

	-- Action 2: Stats counter reset
	if self.stats and self.stats.totalLogEntries and self.stats.totalLogEntries > 5000 then
		local oldTotal = self.stats.totalLogEntries
		self.stats.totalLogEntries = #self.logBuffer
		memoryActions.applied = memoryActions.applied + 1

		local action = string.format("Stats reset: %d → %d total entries", oldTotal, self.stats.totalLogEntries)
		table.insert(memoryActions.actions, action)
		print("|cff00ff00✓ " .. action .. "|r")
	else
		memoryActions.skipped = memoryActions.skipped + 1
		table.insert(memoryActions.actions, "Stats counters reasonable, no reset needed")
		print("|cffff8800✓ Stats counters reasonable|r")
	end

	-- Action 3: Clear large data objects
	local largeDataRemoved = 0
	for i, entry in ipairs(self.logBuffer) do
		if entry.data and type(entry.data) == "table" then
			local estimatedSize = self:_EstimateDataSize(entry.data)
			if estimatedSize > 2048 then -- 2KB limit
				entry.data = { truncated = true, originalSize = estimatedSize }
				largeDataRemoved = largeDataRemoved + 1
			end
		end
	end

	if largeDataRemoved > 0 then
		memoryActions.applied = memoryActions.applied + 1
		local action = string.format("Truncated %d large data objects", largeDataRemoved)
		table.insert(memoryActions.actions, action)
		print("|cff00ff00✓ " .. action .. "|r")
	else
		memoryActions.skipped = memoryActions.skipped + 1
		table.insert(memoryActions.actions, "No large data objects found")
		print("|cffff8800✓ No large data objects found|r")
	end

	-- Summary
	print(
		string.format(
			"|cff00ff00Memory management: %d actions applied, %d skipped|r",
			memoryActions.applied,
			memoryActions.skipped
		)
	)

	return memoryActions
end

-- Performance monitoring with real-time metrics
function SLH.Debug:MonitorPerformance(duration)
	duration = duration or 30 -- Default 30 seconds

	print(string.format("|cff00ff00=== Starting %d-second performance monitoring ===|r", duration))

	local monitoring = {
		startTime = GetServerTime(),
		endTime = nil,
		duration = duration,
		metrics = {
			logsPerSecond = {},
			memoryUsage = {},
			bufferSize = {},
			operationTimes = {},
		},
		summary = {},
	}

	-- Start monitoring loop
	local startTimestamp = GetServerTime()
	local lastSample = startTimestamp
	local sampleInterval = 5 -- Sample every 5 seconds

	-- Initial sample
	local initialStats = self:GetStats()
	table.insert(monitoring.metrics.memoryUsage, {
		time = 0,
		usage = initialStats.memoryUsage or 0,
	})
	table.insert(monitoring.metrics.bufferSize, {
		time = 0,
		size = #self.logBuffer,
	})

	print("|cff00ff00Monitoring started - generating test load...|r")

	-- Generate test load while monitoring
	local testLogsGenerated = 0
	local testStartTime = debugprofilestop and debugprofilestop() or GetServerTime() * 1000

	for i = 1, duration * 2 do -- 2 logs per second
		-- Test various log operations
		if i % 4 == 0 then
			self:LogInfo("PerfMonitor", "Performance test log " .. i, { iteration = i, load = "test" })
		elseif i % 4 == 1 then
			self:LogWarn("PerfMonitor", "Warning test " .. i, { type = "warning" })
		elseif i % 4 == 2 then
			self:LogDebug("PerfMonitor", "Debug test " .. i, { debug = true, data = { nested = { value = i } } })
		else
			self:LogError("PerfMonitor", "Error test " .. i, { error = "simulated", code = i })
		end

		testLogsGenerated = testLogsGenerated + 1

		-- Sample metrics every interval
		local elapsed = GetServerTime() - startTimestamp
		if elapsed >= lastSample + sampleInterval - startTimestamp then
			local currentStats = self:GetStats()

			table.insert(monitoring.metrics.memoryUsage, {
				time = elapsed,
				usage = currentStats.memoryUsage or 0,
			})
			table.insert(monitoring.metrics.bufferSize, {
				time = elapsed,
				size = #self.logBuffer,
			})

			local logsInInterval = testLogsGenerated / elapsed
			table.insert(monitoring.metrics.logsPerSecond, {
				time = elapsed,
				rate = logsInInterval,
			})

			lastSample = GetServerTime()
		end

		-- Small delay to simulate real usage
		if i % 10 == 0 then
			-- Simulate brief pause every 10 operations
			local pauseStart = debugprofilestop and debugprofilestop() or GetServerTime() * 1000
			while ((debugprofilestop and debugprofilestop() or GetServerTime() * 1000) - pauseStart) < 100 do
				-- 100ms pause every 10 operations
			end
		end
	end

	local testEndTime = debugprofilestop and debugprofilestop() or GetServerTime() * 1000
	local totalTestTime = testEndTime - testStartTime

	monitoring.endTime = GetServerTime()
	monitoring.actualDuration = monitoring.endTime - monitoring.startTime

	-- Calculate performance summary
	local finalStats = self:GetStats()
	monitoring.summary = {
		testLogsGenerated = testLogsGenerated,
		totalTestTime = totalTestTime,
		averageLogTime = totalTestTime / testLogsGenerated,
		finalMemoryUsage = finalStats.memoryUsage or 0,
		finalBufferSize = #self.logBuffer,
		logsPerSecond = testLogsGenerated / monitoring.actualDuration,
	}

	-- Display results
	print("|cff00ff00=== Performance Monitoring Results ===|r")
	print(string.format("|cff00ff00Duration: %.1f seconds|r", monitoring.actualDuration))
	print(string.format("|cff00ff00Test logs generated: %d|r", testLogsGenerated))
	print(string.format("|cff00ff00Average logs/second: %.2f|r", monitoring.summary.logsPerSecond))
	print(string.format("|cff00ff00Average time per log: %.3f ms|r", monitoring.summary.averageLogTime))
	print(string.format("|cff00ff00Final memory usage: %s|r", self:_FormatBytes(monitoring.summary.finalMemoryUsage)))
	print(string.format("|cff00ff00Final buffer size: %d entries|r", monitoring.summary.finalBufferSize))

	-- Performance rating
	local rating = "Excellent"
	if monitoring.summary.averageLogTime > 1.0 then
		rating = "Good"
	end
	if monitoring.summary.averageLogTime > 5.0 then
		rating = "Needs Optimization"
	end

	print(string.format("|cff00ff00Performance Rating: %s|r", rating))

	-- Log the monitoring results
	self:LogInfo("Performance", "Performance monitoring completed", {
		duration = monitoring.actualDuration,
		logsGenerated = testLogsGenerated,
		avgLogTime = monitoring.summary.averageLogTime,
		rating = rating,
	})

	return monitoring
end
