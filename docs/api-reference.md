# API Reference

Complete API documentation for developers integrating with SpectrumLootTool or creating extensions.

## 🔌 Core API

### SLH Namespace

All SpectrumLootTool functions are available under the global `SLH` namespace.

```lua
-- Check if addon is loaded
if SLH then
    -- Addon is available
    print("SpectrumLootTool loaded, version: " .. SLH.version)
end
```

### Basic Functions

#### SLH:Toggle()
Toggle the main interface visibility.

```lua
-- Show/hide the interface
SLH:Toggle()

-- Force show
SLH:Show()

-- Force hide  
SLH:Hide()
```

#### SLH:GetVersion()
Returns the current addon version.

```lua
local version = SLH:GetVersion()
print("Running version: " .. version)
```

## 👥 Player Management

### Getting Player Data

#### SLH:GetPlayer(name)
Retrieve player information and roll count.

```lua
local playerData = SLH:GetPlayer("PlayerName")
if playerData then
    print("Roll count: " .. playerData.rollCount)
    print("Class: " .. playerData.class)
    print("Last seen: " .. playerData.lastSeen)
end
```

#### SLH:GetAllPlayers()
Get data for all known players.

```lua
local allPlayers = SLH:GetAllPlayers()
for name, data in pairs(allPlayers) do
    print(name .. " has " .. data.rollCount .. " rolls")
end
```

### Modifying Player Data

#### SLH:SetPlayer(name, count)
Set a player's roll count (officer only).

```lua
-- Set PlayerName to 5 rolls
SLH:SetPlayer("PlayerName", 5)
```

#### SLH:AdjustPlayer(name, amount)
Adjust a player's roll count by amount (officer only).

```lua
-- Add 2 rolls to PlayerName
SLH:AdjustPlayer("PlayerName", 2)

-- Remove 1 roll from PlayerName  
SLH:AdjustPlayer("PlayerName", -1)
```

## 🏛️ Guild Integration

### Permission Checking

#### SLH:IsOfficer()
Check if current player has officer permissions.

```lua
if SLH:IsOfficer() then
    print("You have officer permissions")
    -- Show officer-only UI elements
end
```

#### SLH:CanModify()
Check if current player can modify roll counts.

```lua
if SLH:CanModify() then
    -- Allow roll count adjustments
end
```

### Guild Information

#### SLH:GetGuildInfo()
Get current guild information.

```lua
local guildInfo = SLH:GetGuildInfo()
if guildInfo then
    print("Guild: " .. guildInfo.name)
    print("Rank: " .. guildInfo.rank)
end
```

## 📊 Data Management

### Database Operations

#### SLH:GetDatabase()
Access the underlying database.

```lua
local db = SLH:GetDatabase()
-- Access player data: db.players
-- Access settings: db.settings
```

#### SLH:SaveData()
Force save current data to disk.

```lua
SLH:SaveData()
print("Data saved successfully")
```

#### SLH:ResetData(type)
Reset specific data types.

```lua
-- Reset all roll counts
SLH:ResetData("rolls")

-- Reset all player data
SLH:ResetData("players")

-- Reset everything
SLH:ResetData("all")
```

## 🔄 Event System

### Registering for Events

#### SLH:RegisterCallback(event, callback)
Register for SLH events.

```lua
local function onRollChanged(playerName, newCount, oldCount)
    print(playerName .. " roll count: " .. oldCount .. " -> " .. newCount)
end

SLH:RegisterCallback("ROLL_CHANGED", onRollChanged)
```

### Available Events

#### ROLL_CHANGED
Fired when a player's roll count changes.

**Arguments:**
- `playerName` (string): Name of the player
- `newCount` (number): New roll count
- `oldCount` (number): Previous roll count

#### PLAYER_JOINED
Fired when a player joins the tracking list.

**Arguments:**
- `playerName` (string): Name of the player
- `playerData` (table): Complete player data

#### PLAYER_LEFT  
Fired when a player leaves the tracking list.

**Arguments:**
- `playerName` (string): Name of the player

#### OFFICER_STATUS_CHANGED
Fired when officer status changes.

**Arguments:**
- `isOfficer` (boolean): New officer status

## 🎨 UI Integration

### Frame Access

#### SLH:GetMainFrame()
Get reference to the main interface frame.

```lua
local mainFrame = SLH:GetMainFrame()
if mainFrame then
    -- Modify frame properties
    mainFrame:SetAlpha(0.8)
end
```

#### SLH:CreateCustomFrame()
Create a custom frame with SLH styling.

```lua
local customFrame = SLH:CreateCustomFrame("MyCustomFrame", UIParent)
customFrame:SetSize(200, 100)
customFrame:SetPoint("CENTER")
```

### Styling Functions

#### SLH:ApplyClassColor(fontString, class)
Apply class colors to text.

```lua
local text = frame:CreateFontString()
SLH:ApplyClassColor(text, "PALADIN")  -- Makes text pink
```

#### SLH:GetClassColor(class)
Get class color values.

```lua
local r, g, b = SLH:GetClassColor("MAGE")
-- Returns RGB values for mage blue
```

## 🔍 Debugging & Logging

### Log Functions

#### SLH:Log(level, message)
Write to the addon log.

```lua
SLH:Log("INFO", "Custom integration loaded")
SLH:Log("DEBUG", "Processing player data")
SLH:Log("ERROR", "Failed to load configuration")
```

#### SLH:GetLogLevel()
Get current logging level.

```lua
local level = SLH:GetLogLevel()
if level == "DEBUG" then
    -- Detailed logging is enabled
end
```

### Debug Functions

#### SLH:DumpData(data)
Pretty-print data structures.

```lua
local playerData = SLH:GetPlayer("TestPlayer")
SLH:DumpData(playerData)  -- Prints formatted table
```

#### SLH:ValidateData()
Check data integrity.

```lua
local isValid, errors = SLH:ValidateData()
if not isValid then
    for _, error in ipairs(errors) do
        print("Data error: " .. error)
    end
end
```

## 🔗 Communication

### Addon Communication

#### SLH:SendMessage(target, message)
Send messages to other SLH users.

```lua
-- Send to specific player
SLH:SendMessage("PlayerName", "Custom message data")

-- Send to all raid members
SLH:SendMessage("RAID", "Broadcast message")
```

#### SLH:RegisterMessageHandler(handler)
Handle incoming messages.

```lua
local function messageHandler(sender, message)
    print("Received from " .. sender .. ": " .. message)
end

SLH:RegisterMessageHandler(messageHandler)
```

## 📋 Configuration API

### Settings Management

#### SLH:GetSetting(key)
Get configuration value.

```lua
local showOffline = SLH:GetSetting("showOfflinePlayers")
local frameScale = SLH:GetSetting("ui.scale")
```

#### SLH:SetSetting(key, value)
Set configuration value.

```lua
SLH:SetSetting("showOfflinePlayers", true)
SLH:SetSetting("ui.scale", 1.2)
```

#### SLH:ResetSettings()
Reset all settings to defaults.

```lua
SLH:ResetSettings()
print("Settings reset to defaults")
```

## 🔌 Extension Development

### Creating Extensions

Example addon that integrates with SLH:

```lua
-- MyExtension.lua
local MyExt = {}

-- Wait for SLH to load
local function OnAddonLoaded(event, addonName)
    if addonName == "SpectrumLootTool" then
        if SLH then
            MyExt:Initialize()
        end
    end
end

function MyExt:Initialize()
    -- Register for roll changes
    SLH:RegisterCallback("ROLL_CHANGED", function(player, new, old)
        self:OnRollChanged(player, new, old)
    end)
    
    -- Add custom UI elements
    self:CreateUI()
end

function MyExt:OnRollChanged(player, newCount, oldCount)
    -- Custom logic when rolls change
    if newCount == 0 then
        print(player .. " is now eligible for loot!")
    end
end

function MyExt:CreateUI()
    -- Create custom interface
    local frame = SLH:CreateCustomFrame("MyExtensionFrame", UIParent)
    -- Add custom functionality
end

-- Register for addon load events
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", OnAddonLoaded)
```

### Best Practices

1. **Always check if SLH exists** before calling functions
2. **Use the event system** instead of polling for changes  
3. **Respect officer permissions** when modifying data
4. **Handle errors gracefully** with pcall/xpcall
5. **Use proper logging levels** for debug output

---

!!! note "API Stability"
    This API is stable for the current major version. Breaking changes will be documented in release notes and deprecated functions will show warnings before removal.
