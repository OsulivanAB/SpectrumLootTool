local ADDON_NAME, SLH = ...

SLH.version = "0.1.0"
SLH.OFFICER_RANK = 2 -- configurable officer rank threshold

-- Initialize saved variables and basic database
function SLH:Init()
    SpectrumLootHelperDB = SpectrumLootHelperDB or { rolls = {}, log = {} }
    self.db = SpectrumLootHelperDB
    if self.Sync then
        self.Sync:Request()
    end
end

-- Determine if the given unit is an officer in Spectrum Federation
function SLH:IsOfficer(unit)
    unit = unit or "player"
    local guild, _, rankIndex = GetGuildInfo(unit)
    return guild == "Spectrum Federation" and rankIndex and rankIndex <= self.OFFICER_RANK
end

-- Adjust a player's roll count and record the change
function SLH:AdjustRoll(playerName, delta, officer)
    local current = self.db.rolls[playerName] or 0
    local newValue = math.max(0, current + delta)
    self.db.rolls[playerName] = newValue
    table.insert(self.db.log, {
        time = GetServerTime(),
        player = playerName,
        officer = officer,
        value = newValue,
    })
    if self.Sync then
        self.Sync:Broadcast()
    end
end

-- Event handling
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event, addon)
    if event == "ADDON_LOADED" and addon == ADDON_NAME then
        SLH:Init()
        print("|cff00ff00Spectrum Loot Helper loaded|r")
    end
end)

-- Simple slash command to toggle the UI
SLASH_SPECTRUMLOOTHELPER1 = "/slh"
SlashCmdList["SPECTRUMLOOTHELPER"] = function()
    local f = SLH:CreateMainFrame()
    if f:IsShown() then f:Hide() else f:Show() end
end
