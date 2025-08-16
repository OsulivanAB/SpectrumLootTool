local ADDON_NAME, SLH = ...

-- Log management module for tracking Best-in-Slot roll count changes
SLH.Log = {
    version = "1.0", -- Log system version
    currentWoWVersion = nil, -- Current WoW major.minor version for filtering
}

-- Initialize the log system
function SLH.Log:Init()
    -- Initialize WoW version detection and caching
    self:GetCurrentWoWVersion()
    
    -- Placeholder for additional log system initialization
    -- Will handle:
    -- - Log database structure validation
    -- - Legacy log migration if needed
end

-- Get current WoW version for log filtering (major.minor format)
function SLH.Log:GetCurrentWoWVersion()
    -- Use cached version if already detected
    if self.currentWoWVersion then
        return self.currentWoWVersion
    end
    
    -- Detect and cache WoW version using WoW API
    local success, result = pcall(function()
        local version, build, date, tocversion = GetBuildInfo()
        
        -- Extract major.minor version from full version string
        -- Example: "10.2.5.52902" -> "10.2"
        local major, minor = string.match(version, "(%d+)%.(%d+)")
        if major and minor then
            return major .. "." .. minor
        else
            -- Fallback: if pattern matching fails, try to extract first two numbers
            local parts = {}
            for part in string.gmatch(version, "(%d+)") do
                table.insert(parts, part)
                if #parts == 2 then break end
            end
            
            if #parts >= 2 then
                return parts[1] .. "." .. parts[2]
            else
                -- Last resort: return full version if we can't parse it
                return version
            end
        end
    end)
    
    if success and result then
        -- Cache the detected version
        self.currentWoWVersion = result
        return result
    else
        -- Error handling: return fallback version
        local fallbackVersion = "unknown"
        self.currentWoWVersion = fallbackVersion
        
        -- Optional debug output (can be removed in production)
        if SLH and SLH.debugLog then
            print("|cffff0000SLH Log: Failed to detect WoW version, using fallback: " .. fallbackVersion .. "|r")
        end
        
        return fallbackVersion
    end
end

-- Force refresh WoW version detection (useful for debugging or version changes)
function SLH.Log:RefreshWoWVersion()
    -- Store the previous version for comparison
    local previousVersion = self.currentWoWVersion
    
    -- Clear cached version to force re-detection
    self.currentWoWVersion = nil
    
    -- Detect the new version
    local newVersion = self:GetCurrentWoWVersion()
    
    -- Check if version actually changed
    local versionChanged = (previousVersion ~= newVersion)
    
    -- Handle version change event
    if versionChanged then
        self:OnVersionChanged(previousVersion, newVersion)
    end
    
    -- Log version refresh if debug logging is enabled
    if SLH and SLH.debugLog then
        if versionChanged then
            local prevStr = previousVersion or "none"
            print("|cff00ff00SLH Log: WoW version changed from " .. prevStr .. " to " .. newVersion .. "|r")
        else
            print("|cff00ff00SLH Log: WoW version refreshed (no change): " .. newVersion .. "|r")
        end
    end
    
    -- Return detailed information about the refresh operation
    return {
        success = (newVersion ~= "unknown"),
        previousVersion = previousVersion,
        newVersion = newVersion,
        changed = versionChanged,
        timestamp = GetServerTime() -- WoW API function for server timestamp
    }
end

-- Handle WoW version changes (called internally when version changes)
function SLH.Log:OnVersionChanged(oldVersion, newVersion)
    -- Store version change event for debugging and potential future use
    if not self.versionChangeHistory then
        self.versionChangeHistory = {}
    end
    
    local changeEvent = {
        timestamp = GetServerTime(),
        oldVersion = oldVersion,
        newVersion = newVersion
    }
    
    table.insert(self.versionChangeHistory, changeEvent)
    
    -- Keep only last 10 version changes to prevent memory bloat
    while #self.versionChangeHistory > 10 do
        table.remove(self.versionChangeHistory, 1)
    end
    
    -- Notify Core system if it exists and has a version change handler
    if SLH and SLH.OnWoWVersionChanged then
        local success, err = pcall(SLH.OnWoWVersionChanged, oldVersion, newVersion)
        if not success and SLH.debugLog then
            print("|cffff0000SLH Log: Error notifying core of version change: " .. tostring(err) .. "|r")
        end
    end
    
    -- Future functionality: This is where we could trigger:
    -- - Log cleanup for old versions
    -- - Sync system notification
    -- - UI updates
    -- - Roll count resets (if major.minor version changed)
end

-- Add a new log entry for roll count changes
function SLH.Log:AddEntry(playerName, officerName, newValue, oldValue)
    -- Placeholder for adding log entries
    -- Parameters:
    -- - playerName: The player whose roll count changed
    -- - officerName: The officer who made the change
    -- - newValue: The new roll count value
    -- - oldValue: The previous roll count value (optional, for better tracking)
    
    -- Will create log entry with:
    -- - Timestamp (server time)
    -- - Player name
    -- - Officer who made the change
    -- - New value
    -- - WoW version for filtering
    -- - Unique ID for sync deduplication
end

-- Get log entries for a specific player
function SLH.Log:GetPlayerEntries(playerName, wowVersion)
    -- Placeholder for retrieving player-specific log entries
    -- Parameters:
    -- - playerName: Player to get entries for
    -- - wowVersion: Optional WoW version filter (defaults to current)
    
    -- Will return filtered array of log entries
    return {}
end

-- Get all log entries for current WoW version
function SLH.Log:GetCurrentVersionEntries()
    -- Placeholder for getting all relevant log entries
    -- Will filter by current WoW major.minor version
    return {}
end

-- Clean up old log entries (retention policy)
function SLH.Log:CleanupOldEntries(retentionDays)
    -- Placeholder for log cleanup functionality
    -- Parameters:
    -- - retentionDays: Number of days to retain logs (optional, defaults to config)
    
    -- Will remove:
    -- - Entries older than retention period
    -- - Entries from different WoW major.minor versions (optional)
end

-- Validate log entry structure
function SLH.Log:ValidateEntry(entry)
    -- Placeholder for log entry validation
    -- Will check required fields and data types
    return false
end

-- Get log statistics for debugging/status
function SLH.Log:GetStats()
    -- Get current WoW version for stats
    local currentVersion = self:GetCurrentWoWVersion()
    
    -- Include version change history in stats
    local versionChanges = 0
    local lastVersionChange = nil
    if self.versionChangeHistory then
        versionChanges = #self.versionChangeHistory
        if versionChanges > 0 then
            lastVersionChange = self.versionChangeHistory[versionChanges]
        end
    end
    
    -- Placeholder for log statistics
    -- Will return:
    -- - Total entries
    -- - Entries for current WoW version
    -- - Current WoW version
    -- - Version change tracking
    -- - Oldest/newest entry timestamps
    -- - Memory usage estimate
    return {
        totalEntries = 0,
        currentVersionEntries = 0,
        currentWoWVersion = currentVersion,
        versionChanges = versionChanges,
        lastVersionChange = lastVersionChange,
        oldestEntry = nil,
        newestEntry = nil
    }
end

-- Get version change history for debugging
function SLH.Log:GetVersionChangeHistory()
    -- Return copy of version change history to prevent external modification
    if not self.versionChangeHistory then
        return {}
    end
    
    local history = {}
    for i, event in ipairs(self.versionChangeHistory) do
        history[i] = {
            timestamp = event.timestamp,
            oldVersion = event.oldVersion,
            newVersion = event.newVersion
        }
    end
    
    return history
end

-- Export log data (for future sync functionality)
function SLH.Log:Export(wowVersion)
    -- Placeholder for log data export
    -- Will serialize log entries for sharing/sync
    return {}
end

-- Import log data (for future sync functionality) 
function SLH.Log:Import(data, source)
    -- Placeholder for log data import
    -- Parameters:
    -- - data: Serialized log entries
    -- - source: Source player/system for conflict resolution
    
    -- Will handle:
    -- - Data validation
    -- - Duplicate detection
    -- - Conflict resolution
    -- - Merge with existing log
end

-- Recalculate roll counts from log history
function SLH.Log:RecalculateRollCounts(wowVersion)
    -- Placeholder for recalculating roll counts from log
    -- Will process all log entries to rebuild current roll count state
    -- This ensures data consistency and supports offline changes
    return {}
end
