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
    
    -- Initialize debug system
    if self.Debug then
        self.Debug:Init()
        self.Debug:StartSession()
        self.Debug:LogInfo("Core", "Addon initialized", { version = self.version })
        self.Debug:LogInfo("Core", "Debug system fully implemented with performance optimization", { 
            coreTests = { "/slh debuglog test core", "/slh debuglog test perf" },
            uiTests = { "/slh debuglog test ui", "/slh debuglog test workflow" },
            optimization = { "/slh debuglog optimize run", "/slh debuglog optimize memory", "/slh debuglog optimize monitor" },
            comprehensiveTest = "/slh debuglog test all"
        })
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
    local allowOutsideRaid = self.db.settings.allowOutsideRaid
    
    local enabled = false
    if allowOutsideRaid then
        enabled = not inCombat
    else
        enabled = inRaid and not inCombat
    end
    
    self.Debug:LogDebug("Core", "Addon enablement check", {
        inRaid = inRaid,
        inCombat = inCombat,
        allowOutsideRaid = allowOutsideRaid,
        enabled = enabled
    })
    
    return enabled
end

-- Determine if the given unit is an officer in Spectrum Federation
function SLH:IsOfficer(unit)
    unit = unit or "player"
    
    self.Debug:LogDebug("Core", "Checking officer status", {
        unit = unit
    })
    
    -- First, try GetGuildInfo which is the most reliable when available
    local guild, _, rankIndex = GetGuildInfo(unit)
    
    -- If GetGuildInfo fails, try alternative guild detection methods
    if not guild or not rankIndex then
        self.Debug:LogDebug("Core", "GetGuildInfo failed, trying alternative methods", {
            unit = unit,
            guild = guild,
            rankIndex = rankIndex
        })
        
        -- Try guild roster approach for player unit
        if unit == "player" and IsInGuild() then
            local numGuildMembers = GetNumGuildMembers()
            for i = 1, numGuildMembers do
                local name, _, rankIndex2, _, _, _, _, _, _, _, _, _, _, _, _, _, guildGUID = GetGuildRosterInfo(i)
                if name and name == UnitName("player") then
                    guild = GetGuildInfo("player") or "Spectrum Federation"  -- fallback
                    rankIndex = rankIndex2
                    self.Debug:LogDebug("Core", "Found player in guild roster", {
                        playerName = name,
                        guild = guild,
                        rankIndex = rankIndex
                    })
                    break
                end
            end
        end
    end
    
    -- If still no guild data, return false but with debug info
    if not guild then
        self.Debug:LogWarn("Core", "No guild data found for unit", {
            unit = unit
        })
        if self.debugOfficer then
            print("|cffff0000SLH Debug: No guild data found for " .. (unit or "nil") .. "|r")
        end
        return false
    end
    
    if not rankIndex then
        self.Debug:LogWarn("Core", "No rank index found for unit", {
            unit = unit,
            guild = guild
        })
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
    
    self.Debug:LogDebug("Core", "Officer status determined", {
        unit = unit,
        guild = guild,
        rankIndex = rankIndex,
        isSpectrumFed = isSpectrumFed,
        isOfficer = isOfficer,
        officerRankThreshold = self.OFFICER_RANK
    })
    
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
    self.Debug:LogInfo("Core", "Refreshing officer status", {
        frameExists = self.frame ~= nil,
        frameShown = self.frame and self.frame:IsShown() or false
    })
    
    if self.frame and self.frame:IsShown() then
        self:UpdateRoster()
        print("|cff00ff00SLH: Officer status refreshed|r")
        self.Debug:LogDebug("Core", "Officer status refresh completed", {})
    else
        self.Debug:LogDebug("Core", "Officer status refresh skipped - frame not shown", {})
    end
end

-- Recalculate all roll values from the complete log history
function SLH:RecalculateFromLog()
    self.Debug:LogInfo("Core", "Starting roll recalculation from log", {
        currentRollCount = self.db.rolls and table.getn(self.db.rolls) or 0,
        logEntryCount = self.db.log and #self.db.log or 0
    })
    
    -- Clear current rolls
    self.db.rolls = {}
    
    -- Sort log entries by time to ensure proper order
    local sortedLog = {}
    for _, entry in ipairs(self.db.log) do
        table.insert(sortedLog, entry)
    end
    table.sort(sortedLog, function(a, b) return a.time < b.time end)
    
    self.Debug:LogDebug("Core", "Log entries sorted chronologically", {
        sortedEntryCount = #sortedLog
    })
    
    -- Recalculate values by applying each log entry in chronological order
    local processedEntries = 0
    for _, entry in ipairs(sortedLog) do
        if entry.player and entry.value then
            self.db.rolls[entry.player] = entry.value
            processedEntries = processedEntries + 1
        end
    end
    
    self.Debug:LogInfo("Core", "Roll recalculation completed", {
        processedEntries = processedEntries,
        finalRollCount = self.db.rolls and table.getn(self.db.rolls) or 0
    })
end

-- Adjust a player's roll count and record the change
function SLH:AdjustRoll(playerName, delta, officer)
    -- Debug logging for roll adjustment
    if self.Debug then
        self.Debug:LogDebug("Core", "AdjustRoll called", { 
            player = playerName, 
            delta = delta, 
            officer = officer 
        })
    end
    
    local oldValue = self.db.rolls[playerName] or 0
    local newValue = math.max(0, oldValue + delta)
    self.db.rolls[playerName] = newValue
    
    -- Debug logging for the actual change
    if self.Debug then
        self.Debug:LogInfo("Core", "Player roll count adjusted", {
            player = playerName,
            officer = officer,
            oldValue = oldValue,
            newValue = newValue,
            delta = delta
        })
    end
    
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
    
    -- Create unique log entry with new standardized format
    local timestamp = GetServerTime()
    local logEntry = {
        logEntryID = string.format("%d_%s_%s", timestamp, playerName, officer), -- Unique ID
        timestamp = timestamp,
        playerName = playerName,
        officerName = officer,
        oldValue = oldValue, -- Previous value
        newValue = newValue,
        wowVersion = wowVersion, -- Track WoW version for filtering
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
        
        -- Show debug system status
        if SLH.Debug then
            local debugStats = SLH.Debug:GetStats()
            print("|cff00ff00Debug Logging: " .. (debugStats.enabled and "Enabled" or "Disabled") .. "|r")
            if debugStats.enabled and debugStats.totalLogEntries > 0 then
                print("|cff00ff00Debug Entries: " .. debugStats.totalLogEntries .. "|r")
            end
        end
        
        return
    end
    
    -- Handle version refresh command
    if args[1] == "refreshversion" or args[1] == "versionrefresh" then
        if SLH.Log then
            local result = SLH.Log:RefreshWoWVersion()
            if result.success then
                if result.changed then
                    print("|cff00ff00SLH: WoW version changed from " .. (result.previousVersion or "none") .. " to " .. result.newVersion .. "|r")
                else
                    print("|cff00ff00SLH: WoW version refreshed (no change): " .. result.newVersion .. "|r")
                end
            else
                print("|cffff0000SLH: Failed to refresh WoW version|r")
            end
        else
            print("|cffff0000SLH Log module not loaded|r")
        end
        return
    end
    
    -- Handle debug logging commands
    if args[1] == "debuglog" or args[1] == "debuglogging" then
        if not SLH.Debug then
            print("|cffff0000SLH Debug module not loaded|r")
            return
        end
        
        if args[2] == "on" or args[2] == "enable" then
            SLH.Debug:SetEnabled(true)
            print("|cff00ff00SLH Debug logging enabled|r")
        elseif args[2] == "off" or args[2] == "disable" then
            SLH.Debug:SetEnabled(false)
            print("|cff00ff00SLH Debug logging disabled|r")
        elseif args[2] == "toggle" then
            SLH.Debug:Toggle()
        elseif args[2] == "show" or args[2] == "view" then
            local count = tonumber(args[3]) or 10
            SLH.Debug:DisplayLogsInChat(nil, nil, count)
        elseif args[2] == "clear" then
            SLH.Debug:ClearLogs()
            print("|cff00ff00SLH Debug logs cleared|r")
        elseif args[2] == "export" then
            local export = SLH.Debug:ExportForBugReport()
            print("|cff00ff00SLH Debug log exported (copy from debug file)|r")
        elseif args[2] == "stats" then
            local stats = SLH.Debug:GetStats()
            print("|cff00ff00=== SLH Debug Stats ===|r")
            print("|cff00ff00Enabled: " .. (stats.enabled and "Yes" or "No") .. "|r")
            print("|cff00ff00Session Entries: " .. stats.totalLogEntries .. "|r")
            if stats.sessionDuration > 0 then
                print("|cff00ff00Session Duration: " .. stats.sessionDuration .. "s|r")
            end
        elseif args[2] == "test" then
            -- Task 15 & 16: Integration Testing Commands
            if args[3] == "core" then
                SLH.Debug:RunCoreIntegrationTest()
            elseif args[3] == "ui" or args[3] == "interface" then
                SLH.Debug:RunUserInterfaceTest()
            elseif args[3] == "workflow" or args[3] == "workflows" then
                SLH.Debug:RunUserWorkflowTest()
            elseif args[3] == "performance" or args[3] == "perf" then
                SLH.Debug:RunPerformanceValidation()
            elseif args[3] == "all" then
                SLH.Debug:RunAllIntegrationTests()
            else
                print("|cff00ff00=== SLH Debug Integration Tests ===|r")
                print("|cff00ff00/slh debuglog test core - Run core functionality test|r")
                print("|cff00ff00/slh debuglog test ui - Run user interface test|r")
                print("|cff00ff00/slh debuglog test workflow - Run user workflow test|r")
                print("|cff00ff00/slh debuglog test perf - Run performance validation|r")
                print("|cff00ff00/slh debuglog test all - Run all integration tests|r")
            end
        elseif args[2] == "optimize" or args[2] == "performance" then
            -- Task 17: Performance Optimization Commands
            if args[3] == "run" or args[3] == "apply" then
                SLH.Debug:OptimizePerformance()
            elseif args[3] == "memory" or args[3] == "mem" then
                SLH.Debug:ManageMemory()
            elseif args[3] == "monitor" then
                local duration = tonumber(args[4]) or 30
                SLH.Debug:MonitorPerformance(duration)
            else
                print("|cff00ff00=== SLH Debug Performance Optimization ===|r")
                print("|cff00ff00/slh debuglog optimize run - Apply performance optimizations|r")
                print("|cff00ff00/slh debuglog optimize memory - Manage memory usage|r")
                print("|cff00ff00/slh debuglog optimize monitor [seconds] - Monitor performance|r")
            end
        elseif args[2] == "verify" or args[2] == "completeness" or args[2] == "check" then
            -- Task 18: Debug System Completeness Verification
            SLH.Debug:RunCompletenessVerification()
        elseif args[2] == "errors" or args[2] == "errorhandling" or args[2] == "validate" then
            -- Task 19: Error Handling Validation
            SLH.Debug:RunErrorHandlingValidation()
        elseif args[2] == "wow" or args[2] == "compatibility" or args[2] == "compat" then
            -- Task 20: WoW Addon Lua Compatibility Verification
            SLH.Debug:RunWoWCompatibilityVerification()
        elseif args[2] == "performance" or args[2] == "perf" or args[2] == "impact" then
            -- Task 21: Performance Impact Assessment
            SLH.Debug:RunPerformanceImpactAssessment()
        else
            print("|cff00ff00=== SLH Debug Commands ===|r")
            print("|cff00ff00/slh debuglog on/off - Enable/disable debug logging|r")
            print("|cff00ff00/slh debuglog toggle - Toggle debug logging|r")
            print("|cff00ff00/slh debuglog show [count] - Show recent debug logs|r")
            print("|cff00ff00/slh debuglog clear - Clear debug logs|r")
            print("|cff00ff00/slh debuglog export - Export logs for bug report|r")
            print("|cff00ff00/slh debuglog stats - Show debug statistics|r")
            print("|cff00ff00/slh debuglog test - Integration testing commands|r")
            print("|cff00ff00/slh debuglog optimize - Performance optimization commands|r")
            print("|cff00ff00/slh debuglog verify - Run completeness verification|r")
            print("|cff00ff00/slh debuglog errors - Run error handling validation|r")
            print("|cff00ff00/slh debuglog wow - Run WoW compatibility verification|r")
            print("|cff00ff00/slh debuglog performance - Run performance impact assessment|r")
        end
        return
    end
    
    -- Handle help command
    if args[1] == "help" then
        print("|cff00ff00=== SLH Commands ===|r")
        print("|cff00ff00/slh - Toggle main window|r")
        print("|cff00ff00/slh status - Show addon status|r")
        print("|cff00ff00/slh debug - Toggle officer debug|r")
        print("|cff00ff00/slh debuglog - Debug logging commands|r")
        print("|cff00ff00/slh refresh - Refresh officer status|r")
        print("|cff00ff00/slh refreshversion - Refresh WoW version detection|r")
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
