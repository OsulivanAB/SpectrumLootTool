local ADDON_NAME, SLH = ...

SLH.version = "0.2.0"
SLH.OFFICER_RANK = 2 -- configurable officer rank threshold

-- Initialize saved variables and basic database
function SLH:Init()
    SpectrumLootHelperDB = SpectrumLootHelperDB or { rolls = {}, log = {}, settings = {} }
    self.db = SpectrumLootHelperDB
    -- ensure settings table exists
    self.db.settings = self.db.settings or {}
    if self.db.settings.allowOutsideRaid == nil then self.db.settings.allowOutsideRaid = false end
    if self.db.settings.locked == nil then self.db.settings.locked = true end
    self.db.settings.position = self.db.settings.position or { point = "CENTER", x = 0, y = 0 }
    
    -- Initialize log system
    if self.Log then
        self.Log:Init()
    end
    
    -- Recalculate values from log in case of inconsistencies
    self:RecalculateFromLog()
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
    
    -- First, try GetGuildInfo which is the most reliable when available
    local guild, _, rankIndex = GetGuildInfo(unit)
    
    -- If GetGuildInfo fails, try alternative guild detection methods
    if not guild or not rankIndex then
        -- Try guild roster approach for player unit
        if unit == "player" and IsInGuild() then
            local numGuildMembers = GetNumGuildMembers()
            for i = 1, numGuildMembers do
                local name, _, rankIndex2, _, _, _, _, _, _, _, _, _, _, _, _, _, guildGUID = GetGuildRosterInfo(i)
                if name and name == UnitName("player") then
                    guild = GetGuildInfo("player") or "Spectrum Federation"  -- fallback
                    rankIndex = rankIndex2
                    break
                end
            end
        end
    end
    
    -- If still no guild data, return false but with debug info
    if not guild then
        if self.debugOfficer then
            print("|cffff0000SLH Debug: No guild data found for " .. (unit or "nil") .. "|r")
        end
        return false
    end
    
    if not rankIndex then
        if self.debugOfficer then
            print("|cffff0000SLH Debug: No rank index found for " .. (unit or "nil") .. " in guild " .. guild .. "|r")
        end
        return false
    end
    
    -- Enhanced guild name matching - be more flexible
    local isSpectrumFed = false
    local guildLower = string.lower(guild)
    
    -- Check various possible guild name formats
    if string.find(guildLower, "spectrum federation") or 
       string.find(guildLower, "spectrum") and string.find(guildLower, "federation") then
        isSpectrumFed = true
    end
    
    local isOfficer = isSpectrumFed and rankIndex <= self.OFFICER_RANK
    
    -- Debug output (can be enabled for troubleshooting)
    if self.debugOfficer then
        print(string.format("|cff00ff00SLH Debug: %s - Guild: '%s', Rank: %d, IsSpectrum: %s, IsOfficer: %s|r", 
            unit, guild, rankIndex, tostring(isSpectrumFed), tostring(isOfficer)))
    end
    
    return isOfficer
end

-- Debug function to help troubleshoot officer detection issues
function SLH:ToggleOfficerDebug()
    self.debugOfficer = not self.debugOfficer
    print("|cff00ff00SLH Officer Debug: " .. (self.debugOfficer and "ENABLED" or "DISABLED") .. "|r")
    if self.debugOfficer then
        print("|cffff0000Use '/slh debug off' to disable debug output|r")
        -- Immediately test officer status
        local isOff = self:IsOfficer("player")
        print("|cff00ff00Current officer status: " .. tostring(isOff) .. "|r")
    end
end

-- Force refresh of officer status and UI
function SLH:RefreshOfficerStatus()
    if self.frame and self.frame:IsShown() then
        self:UpdateRoster()
        print("|cff00ff00SLH: Officer status refreshed|r")
    end
end

-- Recalculate all roll values from the complete log history
function SLH:RecalculateFromLog()
    -- Clear current rolls
    self.db.rolls = {}
    
    -- Sort log entries by time to ensure proper order
    local sortedLog = {}
    for _, entry in ipairs(self.db.log) do
        table.insert(sortedLog, entry)
    end
    table.sort(sortedLog, function(a, b) return a.time < b.time end)
    
    -- Recalculate values by applying each log entry in chronological order
    for _, entry in ipairs(sortedLog) do
        if entry.player and entry.value then
            self.db.rolls[entry.player] = entry.value
        end
    end
end

-- Adjust a player's roll count and record the change
function SLH:AdjustRoll(playerName, delta, officer)
    local current = self.db.rolls[playerName] or 0
    local newValue = math.max(0, current + delta)
    self.db.rolls[playerName] = newValue
    
    -- Get current WoW version for tracking
    local wowVersion = "unknown"
    local success, result = pcall(function()
        local version = GetBuildInfo()
        local major, minor = string.match(version, "(%d+)%.(%d+)")
        if major and minor then
            return major .. "." .. minor
        else
            return version
        end
    end)
    
    if success then
        wowVersion = result
    end
    
    -- Create unique log entry with timestamp, officer info, and WoW version
    local logEntry = {
        time = GetServerTime(),
        player = playerName,
        officer = officer,
        value = newValue,
        wowVersion = wowVersion, -- Track WoW version for filtering
        id = string.format("%d_%s_%s_%d", GetServerTime(), playerName, officer, newValue), -- Unique ID with value
    }
    table.insert(self.db.log, logEntry)

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
frame:RegisterEvent("GUILD_ROSTER_UPDATE")  -- Guild data loaded/updated
frame:RegisterEvent("PLAYER_LOGIN")         -- Ensure guild data is available
frame:RegisterEvent("PLAYER_ENTERING_WORLD") -- World loading complete
frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        SLH:Init()
        local f = SLH:CreateMainFrame()
        if SLH:IsEnabled() then f:Show() else f:Hide() end
        if f:IsShown() then SLH:UpdateRoster() end
        print("|cff00ff00Spectrum Loot Helper loaded - Use '/slh help' for commands|r")
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" or 
           event == "GROUP_ROSTER_UPDATE" or event == "GUILD_ROSTER_UPDATE" or
           event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
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
SlashCmdList["SPECTRUMLOOTHELPER"] = function(msg)
    local args = {}
    for word in string.gmatch(msg or "", "%S+") do
        table.insert(args, string.lower(word))
    end
    
    -- Handle debug commands
    if args[1] == "debug" then
        if args[2] == "off" or args[2] == "disable" then
            SLH.debugOfficer = false
            print("|cff00ff00SLH Officer Debug: DISABLED|r")
        else
            SLH:ToggleOfficerDebug()
        end
        return
    end
    
    -- Handle refresh command
    if args[1] == "refresh" or args[1] == "reload" then
        SLH:RefreshOfficerStatus()
        return
    end
    
    -- Handle status command
    if args[1] == "status" then
        local isOfficer = SLH:IsOfficer("player")
        local guild = GetGuildInfo("player")
        print("|cff00ff00=== SLH Status ===|r")
        print("|cff00ff00Guild: " .. (guild or "None") .. "|r")
        print("|cff00ff00Officer: " .. tostring(isOfficer) .. "|r")
        print("|cff00ff00Version: " .. SLH.version .. "|r")
        
        -- Show WoW version from Log system
        if SLH.Log then
            local wowVersion = SLH.Log:GetCurrentWoWVersion()
            print("|cff00ff00WoW Version: " .. wowVersion .. "|r")
        end
        
        if SLH.db and SLH.db.log then
            local totalEntries = #SLH.db.log
            print("|cff00ff00Log Entries: " .. totalEntries .. "|r")
        end
        return
    end
    
    -- Handle help command
    if args[1] == "help" then
        print("|cff00ff00=== SLH Commands ===|r")
        print("|cff00ff00/slh - Toggle main window|r")
        print("|cff00ff00/slh status - Show addon status|r")
        print("|cff00ff00/slh debug - Toggle officer debug|r")
        print("|cff00ff00/slh refresh - Refresh officer status|r")
        return
    end
    
    -- Default behavior - toggle UI
    if not SLH:IsEnabled() then
        print("|cffff0000Spectrum Loot Helper only works in raid groups and out of combat.|r")
        print("|cffff0000Use '/slh help' for more commands|r")
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
