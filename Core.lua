local ADDON_NAME, SLH = ...

SLH.version = "0.1.6"
SLH.OFFICER_RANK = 3 -- configurable officer rank threshold

-- Initialize saved variables and basic database
function SLH:Init()
    SpectrumLootHelperDB = SpectrumLootHelperDB or { rolls = {}, log = {}, settings = {} }
    self.db = SpectrumLootHelperDB
    -- ensure settings table exists
    self.db.settings = self.db.settings or {}
    if self.db.settings.allowOutsideRaid == nil then self.db.settings.allowOutsideRaid = false end
    if self.db.settings.locked == nil then self.db.settings.locked = true end
    self.db.settings.position = self.db.settings.position or { point = "CENTER", x = 0, y = 0 }
    if self.Sync then
        self.Sync:Request()
    end
    if self.CreateOptions then
        self:CreateOptions()
    end
end

-- Determine if the addon should be active
function SLH:IsEnabled()
    local inRaid = IsInRaid()
    local inCombat = UnitAffectingCombat("player")
    if self.db.settings.allowOutsideRaid then
        return not inCombat
    end
    return inRaid and not inCombat
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
    if self.frame then
        self:UpdateRoster()
    end
end

-- Event handling
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        SLH:Init()
        local f = SLH:CreateMainFrame()
        if SLH:IsEnabled() then f:Show() else f:Hide() end
        if f:IsShown() then SLH:UpdateRoster() end
        print("|cff00ff00Spectrum Loot Helper loaded|r")
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" or event == "GROUP_ROSTER_UPDATE" then
        if SLH.frame then
            if SLH:IsEnabled() then
                SLH.frame:Show()
            else
                SLH.frame:Hide()
            end
            if SLH.frame:IsShown() then
                SLH:UpdateRoster()
            end
        end
    end
end)

-- Simple slash command to toggle the UI
SLASH_SPECTRUMLOOTHELPER1 = "/slh"
SlashCmdList["SPECTRUMLOOTHELPER"] = function()
    if not SLH:IsEnabled() then
        print("|cffff0000Spectrum Loot Helper only works in raid groups and out of combat.|r")
        return
    end
    local f = SLH:CreateMainFrame()
    if f:IsShown() then
        f:Hide()
    else
        f:Show()
        SLH:UpdateRoster()
    end
end
