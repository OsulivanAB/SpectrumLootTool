local ADDON_NAME, SLH = ...

SLH.Sync = {
    prefix = "SLH_SYNC",
}

-- Serialize the current database into a compact string
function SLH.Sync:Serialize()
    if not SLH.db or not SLH.db.rolls then return "" end
    local parts = {}
    for player, value in pairs(SLH.db.rolls) do
        table.insert(parts, player .. "=" .. value)
    end
    return table.concat(parts, ";")
end

-- Apply received data to the local database
function SLH.Sync:Deserialize(data)
    if type(data) ~= "string" or data == "" then return end
    for entry in string.gmatch(data, "([^;]+)") do
        local name, value = entry:match("([^=]+)=(%d+)")
        if name and value then
            SLH.db.rolls[name] = tonumber(value)
        end
    end
end

-- Broadcast the full database to the raid group
function SLH.Sync:Broadcast()
    local payload = self:Serialize()
    if payload ~= "" then
        C_ChatInfo.SendAddonMessage(self.prefix, payload, "RAID")
    end
end

-- Request a sync from other raid members
function SLH.Sync:Request()
    C_ChatInfo.SendAddonMessage(self.prefix, "REQUEST", "RAID")
end

C_ChatInfo.RegisterAddonMessagePrefix(SLH.Sync.prefix)
local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:SetScript("OnEvent", function(_, _, prefix, message, channel, sender)
    if prefix ~= SLH.Sync.prefix then return end
    if message == "REQUEST" and SLH:IsOfficer("player") then
        SLH.Sync:Broadcast()
    else
        SLH.Sync:Deserialize(message)
    end
end)
