local ADDON_NAME, SLH = ...

SLH.Sync = {
    prefix = "SLH_SYNC",
}

-- Serialize the log entries into a compact string
function SLH.Sync:SerializeLog()
    if not SLH.db or not SLH.db.log then return "" end
    local parts = {}
    for _, entry in ipairs(SLH.db.log) do
        if entry.time and entry.player and entry.officer and entry.value then
            local id = entry.id or string.format("%d_%s_%s_%d", entry.time, entry.player, entry.officer, entry.value)
            table.insert(parts, string.format("%s|%d|%s|%s|%d", 
                id, entry.time, entry.player, entry.officer, entry.value))
        end
    end
    return table.concat(parts, ";")
end

-- Merge received log entries with local log and recalculate values
function SLH.Sync:MergeLog(data)
    if type(data) ~= "string" or data == "" then return end
    
    local receivedEntries = {}
    for entry in string.gmatch(data, "([^;]+)") do
        local id, time, player, officer, value = entry:match("([^|]+)|(%d+)|([^|]+)|([^|]+)|(%d+)")
        if id and time and player and officer and value then
            table.insert(receivedEntries, {
                id = id,
                time = tonumber(time),
                player = player,
                officer = officer,
                value = tonumber(value),
            })
        end
    end
    
    -- Create a set of existing log entry IDs for duplicate detection
    local existingIds = {}
    for _, entry in ipairs(SLH.db.log) do
        local id = entry.id or string.format("%d_%s_%s_%d", entry.time, entry.player, entry.officer, entry.value)
        existingIds[id] = true
        -- Add ID to entry if it doesn't have one (backward compatibility)
        if not entry.id then
            entry.id = id
        end
    end
    
    -- Add new entries that don't already exist
    local added = false
    for _, entry in ipairs(receivedEntries) do
        if not existingIds[entry.id] then
            table.insert(SLH.db.log, entry)
            added = true
        end
    end
    
    -- If new entries were added, recalculate values and update UI
    if added then
        SLH:RecalculateFromLog()
        if SLH.frame and SLH.frame:IsShown() then
            SLH:UpdateRoster()
        end
    end
end

-- Broadcast the complete log to the raid group
function SLH.Sync:BroadcastLog()
    local payload = self:SerializeLog()
    if payload ~= "" then
        C_ChatInfo.SendAddonMessage(self.prefix .. "_LOG", payload, "RAID")
    end
end

-- Request a log sync from other raid members
function SLH.Sync:RequestLog()
    C_ChatInfo.SendAddonMessage(self.prefix .. "_REQ", "REQUEST_LOG", "RAID")
end

-- Legacy functions for backward compatibility (now use log-based approach)
function SLH.Sync:Serialize()
    return self:SerializeLog()
end

function SLH.Sync:Deserialize(data)
    return self:MergeLog(data)
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
    if prefix == SLH.Sync.prefix .. "_REQ" and message == "REQUEST_LOG" and SLH:IsOfficer("player") then
        -- Officer responds to log requests with their complete log
        SLH.Sync:BroadcastLog()
    elseif prefix == SLH.Sync.prefix .. "_LOG" then
        -- Merge received log entries
        SLH.Sync:MergeLog(message)
    elseif prefix == SLH.Sync.prefix then
        -- Legacy support for old sync format
        if message == "REQUEST" and SLH:IsOfficer("player") then
            SLH.Sync:BroadcastLog()
        else
            SLH.Sync:MergeLog(message)
        end
    end
end)
