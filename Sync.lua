local ADDON_NAME, SLH = ...

SLH.Sync = {
    prefix = "SLH_SYNC",
    version = "2.1", -- Sync protocol version (updated for WoW version filtering)
    lastBroadcast = 0, -- Throttling
    BROADCAST_THROTTLE = 2, -- Minimum seconds between broadcasts
    currentWoWVersion = nil, -- Current WoW version for filtering
    LOG_RETENTION_DAYS = 30, -- Only sync logs from last 30 days
}

-- Initialize WoW version tracking
function SLH.Sync:InitializeWoWVersion()
    local success, result = pcall(function()
        local version, build, date, tocversion = GetBuildInfo()
        -- Create a version identifier from major.minor (e.g., "10.2" for 10.2.x)
        local major, minor = string.match(version, "(%d+)%.(%d+)")
        if major and minor then
            self.currentWoWVersion = major .. "." .. minor
        else
            -- Fallback to full version if parsing fails
            self.currentWoWVersion = version
        end
        
        if SLH.debugSync then
            print("|cff00ff00SLH Sync: WoW Version " .. self.currentWoWVersion .. " (Build: " .. build .. ")|r")
        end
        return true
    end)
    
    if not success then
        -- Fallback version if GetBuildInfo fails
        self.currentWoWVersion = "unknown"
        if SLH.debugSync then
            print("|cffff0000SLH Sync Error: Failed to get WoW version: " .. tostring(result) .. "|r")
        end
    end
end

-- Check if a log entry is relevant for current version
function SLH.Sync:IsEntryRelevant(entry)
    if not entry or type(entry) ~= "table" then
        return false
    end
    
    -- Initialize WoW version if not already done (defensive check)
    if not self.currentWoWVersion then
        self:InitializeWoWVersion()
    end
    
    -- Always include entries without version info (legacy compatibility)
    if not entry.wowVersion then
        return true
    end
    
    -- Include entries from current WoW version
    if entry.wowVersion == self.currentWoWVersion then
        return true
    end
    
    -- Check if entry is within retention period
    if entry.time and type(entry.time) == "number" then
        local currentTime = GetServerTime() -- Use WoW's server time function
        local entryAge = (currentTime - entry.time) / (24 * 60 * 60) -- Convert to days
        
        if entryAge <= self.LOG_RETENTION_DAYS then
            return true
        end
    end
    
    return false
end

-- Enhanced serialization with error handling and version filtering
function SLH.Sync:SerializeLog()
    -- Error handling: Check if database exists
    if not SLH or not SLH.db then 
        if SLH.debugSync then
            print("|cffff0000SLH Sync Error: Database not initialized|r")
        end
        return "" 
    end
    
    if not SLH.db.log then 
        if SLH.debugSync then
            print("|cffff0000SLH Sync Error: Log table not found|r")
        end
        return "" 
    end
    
    -- Initialize WoW version if not already done
    if not self.currentWoWVersion then
        self:InitializeWoWVersion()
    end
    
    local parts = {}
    local errorCount = 0
    local filteredCount = 0
    local totalCount = 0
    
    for i, entry in ipairs(SLH.db.log) do
        totalCount = totalCount + 1
        
        -- Validate entry data before serialization
        if entry and type(entry) == "table" then
            -- Check if entry is relevant for current version/timeframe
            if not self:IsEntryRelevant(entry) then
                filteredCount = filteredCount + 1
                -- Skip entries not relevant to current version (continue to next iteration)
            elseif entry.time and entry.player and entry.officer and entry.value and 
                   type(entry.time) == "number" and 
                   type(entry.player) == "string" and 
                   type(entry.officer) == "string" and 
                   type(entry.value) == "number" then
                
                -- Additional validation: Check for reasonable values
                if entry.time > 0 and entry.time < 2147483647 and -- Valid timestamp
                   string.len(entry.player) > 0 and string.len(entry.player) <= 50 and
                   string.len(entry.officer) > 0 and string.len(entry.officer) <= 50 and
                   entry.value >= -1000 and entry.value <= 1000 then -- Reasonable roll values
                    
                    local id = entry.id or string.format("%d_%s_%s_%d", entry.time, entry.player, entry.officer, entry.value)
                    
                    -- Escape pipe characters to prevent parsing issues
                    local safePlayer = string.gsub(tostring(entry.player), "|", "||")
                    local safeOfficer = string.gsub(tostring(entry.officer), "|", "||")
                    
                    -- Include WoW version in serialized data for version tracking
                    local entryVersion = entry.wowVersion or self.currentWoWVersion
                    
                    table.insert(parts, string.format("%s|%d|%s|%s|%d|%s", 
                        id, entry.time, safePlayer, safeOfficer, entry.value, entryVersion))
                else
                    errorCount = errorCount + 1
                    if SLH.debugSync then
                        print(string.format("|cffff0000SLH Sync Error: Invalid entry values at index %d|r", i))
                    end
                end
            else
                errorCount = errorCount + 1
                if SLH.debugSync then
                    print(string.format("|cffff0000SLH Sync Error: Missing or invalid entry fields at index %d|r", i))
                end
            end
        else
            errorCount = errorCount + 1
            if SLH.debugSync then
                print(string.format("|cffff0000SLH Sync Error: Invalid entry type at index %d|r", i))
            end
        end
    end
    
    if SLH.debugSync then
        local serializedCount = #parts
        print(string.format("|cff00ff00SLH Sync: Serialized %d/%d entries (filtered %d, errors %d)|r", 
            serializedCount, totalCount, filteredCount, errorCount))
    end
    
    return table.concat(parts, ";")
end

-- Enhanced merge with security validation and conflict resolution
function SLH.Sync:MergeLog(data, sender)
    -- Error handling: Validate input parameters
    if not data then 
        if SLH.debugSync then
            print("|cffff0000SLH Sync Error: No data provided to MergeLog|r")
        end
        return false 
    end
    
    if type(data) ~= "string" then
        if SLH.debugSync then
            print("|cffff0000SLH Sync Error: Data is not a string (type: " .. type(data) .. ")|r")
        end
        return false
    end
    
    if data == "" then 
        if SLH.debugSync then
            print("|cffff0000SLH Sync Error: Empty data string|r")
        end
        return false 
    end
    
    if not sender or type(sender) ~= "string" or sender == "" then
        if SLH.debugSync then
            print("|cffff0000SLH Sync Error: Invalid sender|r")
        end
        return false
    end
    
    -- Error handling: Check database state
    if not SLH or not SLH.db then
        if SLH.debugSync then
            print("|cffff0000SLH Sync Error: Database not initialized|r")
        end
        return false
    end
    
    if not SLH.db.log then
        if SLH.debugSync then
            print("|cffff0000SLH Sync Error: Log table not found, initializing|r")
        end
        SLH.db.log = {}
    end
    
    -- Security check: Verify sender is in our guild/raid
    local isValidSender = false
    local senderCheckError = nil
    
    -- Protect against API failures
    local success, result = pcall(function()
        return self:IsValidSender(sender)
    end)
    
    if success then
        isValidSender = result
    else
        senderCheckError = result
        if SLH.debugSync then
            print("|cffff0000SLH Sync Error: Sender validation failed: " .. tostring(senderCheckError) .. "|r")
        end
        return false
    end
    
    if not isValidSender then
        if SLH.debugSync then
            print("|cffff0000SLH Sync: Rejected message from non-guild/raid member: " .. sender .. "|r")
        end
        return false
    end
    
    -- CRITICAL SECURITY: Only Spectrum Federation officers can add new log entries
    -- This is silent by default - only shows error if debug is enabled or manual action
    local isOfficerSender = false
    local officerCheckError = nil
    
    -- Protect against API failures
    success, result = pcall(function()
        return self:IsOfficerSender(sender)
    end)
    
    if success then
        isOfficerSender = result
    else
        officerCheckError = result
        if SLH.debugSync then
            print("|cffff0000SLH Sync Error: Officer validation failed: " .. tostring(officerCheckError) .. "|r")
        end
        return false
    end
    
    if not isOfficerSender then
        if SLH.debugSync then
            print("|cffff0000SLH Sync Security: Rejected log entries from non-officer: " .. sender .. "|r")
        end
        return false
    end
    
    local receivedEntries = {}
    local validEntries = 0
    local parseErrors = 0
    
    -- Parse entries with comprehensive error handling
    local success, parseResult = pcall(function()
        for entry in string.gmatch(data, "([^;]+)") do
            if entry and entry ~= "" then
                -- Support both old format (5 fields) and new format (6 fields with version)
                local parts = {}
                for part in string.gmatch(entry, "([^|]+)") do
                    table.insert(parts, part)
                end
                
                if #parts >= 5 then
                    local id = parts[1]
                    local time = parts[2] 
                    local player = parts[3]
                    local officer = parts[4]
                    local value = parts[5]
                    local wowVersion = parts[6] -- Optional, may be nil
                    
                    if id and time and player and officer and value then
                        -- Unescape pipe characters with error handling
                        local unescapeSuccess, unescapedPlayer, unescapedOfficer = pcall(function()
                            local p = string.gsub(player, "||", "|")
                            local o = string.gsub(officer, "||", "|")
                            return p, o
                        end)
                        
                        if unescapeSuccess then
                            player = unescapedPlayer
                            officer = unescapedOfficer
                            
                            -- Validate data types and ranges with error handling
                            local numTime = tonumber(time)
                            local numValue = tonumber(value)
                            
                            if numTime and numValue and 
                               numTime > 0 and numTime < 2147483647 and -- Valid timestamp range
                               numValue >= -1000 and numValue <= 1000 and -- Reasonable roll values
                               string.len(player) > 0 and string.len(player) <= 50 and
                               string.len(officer) > 0 and string.len(officer) <= 50 and
                               string.len(id) > 0 and string.len(id) <= 100 then
                                
                                -- Additional security: Validate that the officer in the log entry is actually an officer
                                -- This prevents spoofing of officer names in log entries
                                local officerValidationSuccess, isValidOfficer = pcall(function()
                                    return self:IsOfficerSender(officer) or officer == sender
                                end)
                                
                                if officerValidationSuccess and isValidOfficer then
                                    -- Create entry with version information
                                    local logEntry = {
                                        id = id,
                                        time = numTime,
                                        player = player,
                                        officer = officer,
                                        value = numValue,
                                        source = sender, -- Track who sent this entry
                                        wowVersion = wowVersion or self.currentWoWVersion, -- Use received version or current
                                    }
                                    
                                    -- Only add entries that are relevant to current version/timeframe
                                    if self:IsEntryRelevant(logEntry) then
                                        table.insert(receivedEntries, logEntry)
                                        validEntries = validEntries + 1
                                    elseif SLH.debugSync then
                                        print("|cffff0000SLH Sync: Filtered out irrelevant entry from " .. (wowVersion or "unknown") .. "|r")
                                    end
                                elseif SLH.debugSync then
                                    if not officerValidationSuccess then
                                        print("|cffff0000SLH Sync Error: Officer validation failed for: " .. officer .. "|r")
                                    else
                                        print("|cffff0000SLH Sync Security: Rejected entry with invalid officer: " .. officer .. "|r")
                                    end
                                    parseErrors = parseErrors + 1
                                end
                            else
                                if SLH.debugSync then
                                    print("|cffff0000SLH Sync Error: Invalid data values in entry: " .. entry .. "|r")
                                end
                                parseErrors = parseErrors + 1
                            end
                        else
                            if SLH.debugSync then
                                print("|cffff0000SLH Sync Error: Failed to unescape entry: " .. entry .. "|r")
                            end
                            parseErrors = parseErrors + 1
                        end
                    else
                        if SLH.debugSync then
                            print("|cffff0000SLH Sync Error: Missing required fields in entry: " .. entry .. "|r")
                        end
                        parseErrors = parseErrors + 1
                    end
                else
                    if SLH.debugSync then
                        print("|cffff0000SLH Sync Error: Invalid entry format: " .. entry .. "|r")
                    end
                    parseErrors = parseErrors + 1
                end
            end
        end
    end)
    
    if not success then
        if SLH.debugSync then
            print("|cffff0000SLH Sync Error: Critical parsing failure: " .. tostring(parseResult) .. "|r")
        end
        return false
    end
    
    if validEntries == 0 then
        if SLH.debugSync then
            print("|cffff0000SLH Sync: No valid entries received from " .. sender .. 
                  (parseErrors > 0 and " (" .. parseErrors .. " parse errors)" or "") .. "|r")
        end
        return false
    end
    
    -- Create a set of existing log entry IDs for duplicate detection with error handling
    local existingIds = {}
    local existingIdErrors = 0
    
    local success, result = pcall(function()
        for i, entry in ipairs(SLH.db.log) do
            if entry and type(entry) == "table" then
                local id = entry.id or string.format("%d_%s_%s_%d", 
                    entry.time or 0, entry.player or "unknown", entry.officer or "unknown", entry.value or 0)
                existingIds[id] = entry.time or 0 -- Store timestamp for conflict resolution
                -- Add ID to entry if it doesn't have one (backward compatibility)
                if not entry.id then
                    entry.id = id
                end
            else
                existingIdErrors = existingIdErrors + 1
            end
        end
    end)
    
    if not success then
        if SLH.debugSync then
            print("|cffff0000SLH Sync Error: Failed to build existing IDs: " .. tostring(result) .. "|r")
        end
        return false
    end
    
    if existingIdErrors > 0 and SLH.debugSync then
        print("|cffff0000SLH Sync Warning: " .. existingIdErrors .. " invalid entries in existing log|r")
    end
    
    -- Add new entries with conflict resolution and error handling
    local added = 0
    local mergeErrors = 0
    
    for _, entry in ipairs(receivedEntries) do
        local success, result = pcall(function()
            local existingTime = existingIds[entry.id]
            
            if not existingTime then
                -- New entry, add it
                table.insert(SLH.db.log, entry)
                return "added"
            elseif existingTime < entry.time then
                -- Newer version of existing entry, update it
                for i, existing in ipairs(SLH.db.log) do
                    if existing and existing.id == entry.id then
                        SLH.db.log[i] = entry
                        return "updated"
                    end
                end
                return "not_found"
            else
                return "ignored"
            end
        end)
        
        if success then
            if result == "added" or result == "updated" then
                added = added + 1
            end
        else
            mergeErrors = mergeErrors + 1
            if SLH.debugSync then
                print("|cffff0000SLH Sync Error: Failed to merge entry " .. (entry.id or "unknown") .. ": " .. tostring(result) .. "|r")
            end
        end
    end
    
    -- If new entries were added, recalculate values and update UI with error handling
    if added > 0 then
        local success, result = pcall(function()
            if SLH.RecalculateFromLog then
                SLH:RecalculateFromLog()
            end
            if SLH.frame and SLH.frame:IsShown() and SLH.UpdateRoster then
                SLH:UpdateRoster()
            end
        end)
        
        if not success and SLH.debugSync then
            print("|cffff0000SLH Sync Error: Failed to update UI after merge: " .. tostring(result) .. "|r")
        end
        
        if SLH.debugSync then
            print("|cff00ff00SLH Sync: Merged " .. added .. " entries from officer " .. sender .. 
                  (mergeErrors > 0 and " (" .. mergeErrors .. " merge errors)" or "") .. "|r")
        end
    end
    
    return added > 0
end

-- Throttled broadcast to prevent spam
function SLH.Sync:BroadcastLog()
    local currentTime = GetTime()
    
    -- Error handling: Validate GetTime() result
    if not currentTime or type(currentTime) ~= "number" then
        if SLH.debugSync then
            print("|cffff0000SLH Sync Error: Failed to get current time|r")
        end
        return false
    end
    
    -- Throttle broadcasts to prevent spam
    if currentTime - self.lastBroadcast < self.BROADCAST_THROTTLE then
        if SLH.debugSync then
            print("|cffff0000SLH Sync: Broadcast throttled (too frequent)|r")
        end
        return false
    end
    
    -- SECURITY: Only Spectrum Federation officers should broadcast full logs
    -- Silent failure for non-officers since this is automatic behavior
    local isOfficer = false
    local officerCheckError = nil
    
    -- Protect against API failures
    local success, result = pcall(function()
        return SLH:IsOfficer("player")
    end)
    
    if success then
        isOfficer = result
    else
        officerCheckError = result
        if SLH.debugSync then
            print("|cffff0000SLH Sync Error: Officer check failed: " .. tostring(officerCheckError) .. "|r")
        end
        return false
    end
    
    if not isOfficer then
        if SLH.debugSync then
            print("|cffff0000SLH Sync Security: Non-officer attempted to broadcast|r")
        end
        return false
    end
    
    -- Get payload with error handling
    local payload = ""
    local serializeError = nil
    
    success, result = pcall(function()
        return self:SerializeLog()
    end)
    
    if success then
        payload = result
    else
        serializeError = result
        if SLH.debugSync then
            print("|cffff0000SLH Sync Error: Serialization failed: " .. tostring(serializeError) .. "|r")
        end
        return false
    end
    
    if not payload or payload == "" then
        if SLH.debugSync then
            print("|cffff0000SLH Sync: No data to broadcast|r")
        end
        return false
    end
    
    -- Create versioned message with error handling
    local versionedPayload = ""
    success, result = pcall(function()
        return self.version .. "|" .. payload
    end)
    
    if success then
        versionedPayload = result
    else
        if SLH.debugSync then
            print("|cffff0000SLH Sync Error: Failed to create versioned payload: " .. tostring(result) .. "|r")
        end
        return false
    end
    
    -- Validate payload size (WoW addon message limit is ~255 bytes per message)
    if string.len(versionedPayload) > 255 then
        if SLH.debugSync then
            print("|cffff0000SLH Sync Warning: Payload too large (" .. string.len(versionedPayload) .. " bytes), may be truncated|r")
        end
    end
    
    -- Send message with error handling
    local sendSuccess = false
    local sendError = nil
    
    success, result = pcall(function()
        return C_ChatInfo.SendAddonMessage(self.prefix .. "_LOG", versionedPayload, "RAID")
    end)
    
    if success then
        sendSuccess = result
    else
        sendError = result
        if SLH.debugSync then
            print("|cffff0000SLH Sync Error: SendAddonMessage failed: " .. tostring(sendError) .. "|r")
        end
        return false
    end
    
    if sendSuccess then
        self.lastBroadcast = currentTime
        if SLH.debugSync then
            print("|cff00ff00SLH Sync: Officer broadcast complete (" .. string.len(payload) .. " bytes)|r")
        end
    else
        if SLH.debugSync then
            print("|cffff0000SLH Sync: Broadcast failed (SendAddonMessage returned false)|r")
        end
    end
    
    return sendSuccess
end

-- Enhanced request with validation
function SLH.Sync:RequestLog()
    -- Error handling: Check if we're in a raid
    local inRaid = false
    local raidCheckError = nil
    
    local success, result = pcall(function()
        return IsInRaid()
    end)
    
    if success then
        inRaid = result
    else
        raidCheckError = result
        if SLH.debugSync then
            print("|cffff0000SLH Sync Error: Raid check failed: " .. tostring(raidCheckError) .. "|r")
        end
        return false
    end
    
    if not inRaid then
        if SLH.debugSync then
            print("|cffff0000SLH Sync: Cannot request sync - not in raid|r")
        end
        return false
    end
    
    -- Send request with error handling
    local sendSuccess = false
    local sendError = nil
    
    success, result = pcall(function()
        return C_ChatInfo.SendAddonMessage(self.prefix .. "_REQ", "REQUEST_LOG", "RAID")
    end)
    
    if success then
        sendSuccess = result
    else
        sendError = result
        if SLH.debugSync then
            print("|cffff0000SLH Sync Error: Request send failed: " .. tostring(sendError) .. "|r")
        end
        return false
    end
    
    if sendSuccess and SLH.debugSync then
        print("|cff00ff00SLH Sync: Requested log sync from raid|r")
    elseif not sendSuccess and SLH.debugSync then
        print("|cffff0000SLH Sync: Request failed (SendAddonMessage returned false)|r")
    end
    
    return sendSuccess
end

-- Validate if sender is a trusted source (guild member for basic validation)
function SLH.Sync:IsValidSender(sender)
    if not sender or sender == "" then
        return false
    end
    
    -- Always trust ourselves (shouldn't happen, but safety check)
    if sender == UnitName("player") then
        return true
    end
    
    -- Check if sender is in our guild with error handling
    local guildCheckSuccess = false
    local guildCheckError = nil
    
    local success, result = pcall(function()
        if IsInGuild() then
            local numMembers = GetNumGuildMembers()
            if numMembers and numMembers > 0 then
                for i = 1, numMembers do
                    local name = GetGuildRosterInfo(i)
                    if name and name == sender then
                        return true
                    end
                end
            end
        end
        return false
    end)
    
    if success then
        guildCheckSuccess = result
    else
        guildCheckError = result
        if SLH.debugSync then
            print("|cffff0000SLH Sync Error: Guild check failed for " .. sender .. ": " .. tostring(guildCheckError) .. "|r")
        end
    end
    
    if guildCheckSuccess then
        return true
    end
    
    -- If not in guild, check if in raid group (fallback) with error handling
    success, result = pcall(function()
        if IsInRaid() then
            local numMembers = GetNumGroupMembers()
            if numMembers and numMembers > 0 then
                for i = 1, numMembers do
                    local name = GetRaidRosterInfo(i)
                    if name and name == sender then
                        return true
                    end
                end
            end
        end
        return false
    end)
    
    if success then
        return result
    else
        if SLH.debugSync then
            print("|cffff0000SLH Sync Error: Raid check failed for " .. sender .. ": " .. tostring(result) .. "|r")
        end
        return false
    end
end

-- Validate if sender is a Spectrum Federation officer (can modify logs)
function SLH.Sync:IsOfficerSender(sender)
    if not sender or sender == "" then
        return false
    end
    
    -- Check if sender is ourselves and we're an officer with error handling
    if sender == UnitName("player") then
        local success, result = pcall(function()
            return SLH:IsOfficer("player")
        end)
        
        if success then
            return result
        else
            if SLH.debugSync then
                print("|cffff0000SLH Sync Error: Self officer check failed: " .. tostring(result) .. "|r")
            end
            return false
        end
    end
    
    -- Check if sender is a Spectrum Federation officer with comprehensive error handling
    local success, result = pcall(function()
        if IsInGuild() then
            local numMembers = GetNumGuildMembers()
            if numMembers and numMembers > 0 then
                for i = 1, numMembers do
                    local name, _, rankIndex, _, _, _, _, _, _, _, _, _, _, _, _, _, guildGUID = GetGuildRosterInfo(i)
                    if name and name == sender then
                        -- Verify they're in Spectrum Federation and have officer rank
                        local guild = GetGuildInfo(sender)
                        local isSpectrum = guild and string.find(guild, "Spectrum Federation")
                        local isOfficer = rankIndex and rankIndex <= SLH.OFFICER_RANK
                        
                        if SLH.debugSync then
                            print(string.format("|cffff0000SLH Sync Security: %s - Guild: '%s', Rank: %s, IsSpectrum: %s, IsOfficer: %s|r", 
                                sender, guild or "unknown", tostring(rankIndex), tostring(isSpectrum), tostring(isOfficer)))
                        end
                        
                        return isSpectrum and isOfficer
                    end
                end
            end
        end
        return false
    end)
    
    if success then
        return result
    else
        if SLH.debugSync then
            print("|cffff0000SLH Sync Error: Officer validation failed for " .. sender .. ": " .. tostring(result) .. "|r")
        end
        return false
    end
end

-- Debug function for sync troubleshooting
function SLH.Sync:ToggleDebug()
    SLH.debugSync = not SLH.debugSync
    print("|cff00ff00SLH Sync Debug: " .. (SLH.debugSync and "ENABLED" or "DISABLED") .. "|r")
    if SLH.debugSync then
        print("|cffff0000Use '/slh syncdebug off' to disable|r")
    end
end

-- Manual sync trigger for troubleshooting
function SLH.Sync:ForceBroadcast()
    -- Show user-facing error for manual commands only
    if not SLH:IsOfficer("player") then
        print("|cffff0000SLH: Only officers can force broadcast sync data|r")
        return false
    end
    
    self.lastBroadcast = 0 -- Reset throttle
    local success = self:BroadcastLog()
    print("|cff00ff00SLH Sync: Force broadcast " .. (success and "succeeded" or "failed") .. "|r")
    return success
end

-- Legacy functions for backward compatibility (now use log-based approach)
function SLH.Sync:Serialize()
    return self:SerializeLog()
end

function SLH.Sync:Deserialize(data)
    return self:MergeLog(data, "Unknown")
end

function SLH.Sync:Broadcast()
    return self:BroadcastLog()
end

function SLH.Sync:Request()
    return self:RequestLog()
end

-- Register message prefixes
C_ChatInfo.RegisterAddonMessagePrefix(SLH.Sync.prefix .. "_LOG")
C_ChatInfo.RegisterAddonMessagePrefix(SLH.Sync.prefix .. "_REQ")
C_ChatInfo.RegisterAddonMessagePrefix(SLH.Sync.prefix) -- Legacy support

local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:SetScript("OnEvent", function(_, _, prefix, message, channel, sender)
    -- Enhanced message handling with comprehensive error protection
    local success, result = pcall(function()
        if prefix == SLH.Sync.prefix .. "_REQ" and message == "REQUEST_LOG" then
            -- Allow anyone in guild/raid to request logs (non-officers can request)
            if SLH.Sync:IsValidSender(sender) then
                if SLH.debugSync then
                    print("|cff00ff00SLH Sync: Log request from " .. sender .. "|r")
                end
                -- Only officers respond to log requests (silent for automatic behavior)
                if SLH:IsOfficer("player") then
                    SLH.Sync:BroadcastLog()
                elseif SLH.debugSync then
                    print("|cffff0000SLH Sync: Cannot respond to request - not an officer|r")
                end
            elseif SLH.debugSync then
                print("|cffff0000SLH Sync: Rejected request from invalid sender: " .. sender .. "|r")
            end
            
        elseif prefix == SLH.Sync.prefix .. "_LOG" then
            -- Parse versioned message with error handling
            local version, data = nil, nil
            local parseSuccess, parseResult = pcall(function()
                return message:match("([^|]+)|(.+)")
            end)
            
            if parseSuccess then
                version, data = parseResult, select(2, message:match("([^|]+)|(.+)"))
            else
                if SLH.debugSync then
                    print("|cffff0000SLH Sync Error: Failed to parse message: " .. tostring(parseResult) .. "|r")
                end
                return
            end
            
            if version and data then
                if version == SLH.Sync.version then
                    SLH.Sync:MergeLog(data, sender)
                elseif SLH.debugSync then
                    print("|cffff0000SLH Sync: Version mismatch from " .. sender .. 
                          " (their: " .. version .. ", ours: " .. SLH.Sync.version .. ")|r")
                end
            else
                -- Fallback for unversioned messages (legacy support)
                SLH.Sync:MergeLog(message, sender)
            end
            
        elseif prefix == SLH.Sync.prefix then
            -- Legacy support for old sync format
            if message == "REQUEST" then
                if SLH.Sync:IsValidSender(sender) then
                    if SLH.debugSync then
                        print("|cff00ff00SLH Sync: Legacy request from " .. sender .. "|r")
                    end
                    -- Silent automatic response for officers only
                    if SLH:IsOfficer("player") then
                        SLH.Sync:BroadcastLog()
                    end
                end
            else
                SLH.Sync:MergeLog(message, sender)
            end
        end
    end)
    
    if not success then
        if SLH.debugSync then
            print("|cffff0000SLH Sync Error: Critical addon message handler failure: " .. tostring(result) .. "|r")
        end
    end
end)
