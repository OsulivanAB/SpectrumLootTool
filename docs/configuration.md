# Configuration

Customize SpectrumLootTool to fit your raid team's needs with these comprehensive configuration options.

## 🎛️ Settings Overview

Access addon settings through **Options** → **AddOns** → **Spectrum Loot Helper** or use the command:

```
/slh config
```

## 📍 Frame & Interface Settings

### Position & Movement

#### Unlock Frame
- **Default**: Locked
- **Description**: When enabled, allows you to drag the interface to any position on screen
- **Usage**: Enable temporarily to reposition, then disable to prevent accidental movement

#### Auto-Position
- **Default**: Enabled
- **Description**: Automatically positions interface in an optimal location
- **Options**: 
  - Top-left corner
  - Top-right corner  
  - Bottom-left corner
  - Bottom-right corner
  - Center screen

#### Scale
- **Default**: 100%
- **Range**: 50% - 200%
- **Description**: Adjusts the size of the interface
- **Command**: `/slh scale 150` (for 150% size)

### Visibility Options

#### Show Outside Raid
- **Default**: Disabled
- **Description**: Display interface when not in a raid group
- **Use Cases**:
  - Solo testing and configuration
  - Small group dungeons
  - Officer meetings outside raids

#### Auto-Hide in Combat
- **Default**: Enabled
- **Description**: Automatically hides interface during combat encounters
- **Note**: Interface will reappear when combat ends

#### Transparency
- **Default**: 0% (fully opaque)
- **Range**: 0% - 90%
- **Description**: Makes interface semi-transparent
- **Command**: `/slh alpha 0.8` (for 80% opacity)

## 👥 Player Display Settings

### Player Filtering

#### Show All Players
- **Default**: Disabled (current group only)
- **Description**: When enabled, shows all players from database regardless of online status
- **Benefits**:
  - View historical roll data
  - Plan loot distribution for absent players
  - Maintain continuity across raid sessions

#### Class Color Names
- **Default**: Enabled
- **Description**: Colors player names according to their WoW class
- **Classes Supported**: All retail WoW classes with authentic colors

#### Show Offline Players
- **Default**: Enabled when "Show All Players" is active
- **Description**: Include offline guild members in the display
- **Visual**: Offline players appear with dimmed names

### Roll Display Options

#### Show Zero Counts
- **Default**: Enabled
- **Description**: Display players with 0 roll counts
- **Alternative**: Hide players with no rolls to reduce clutter

#### Sort Method
- **Options**:
  - **Alphabetical** (A-Z by player name)
  - **Roll Count** (lowest to highest)
  - **Reverse Roll Count** (highest to lowest)
  - **Join Order** (order players joined the group)

## ⚔️ Officer Controls

!!! warning "Officer Rank Required"
    These settings only appear if you have rank 0-2 in Spectrum Federation guild.

### Adjustment Controls

#### Show Arrow Buttons
- **Default**: Enabled for officers
- **Description**: Display ↑/↓ buttons next to player names
- **Function**: Click to increment/decrement roll counts

#### Button Sensitivity
- **Default**: Single click
- **Options**:
  - Single click (immediate adjustment)
  - Double click (prevent accidental changes)
  - Right-click confirmation

#### Quick Adjustment Amount
- **Default**: 1 roll per click
- **Range**: 1-5 rolls
- **Description**: How many rolls each button click adjusts
- **Command**: `/slh clickvalue 2` (for 2 rolls per click)

### Synchronization

#### Auto-Sync Changes
- **Default**: Enabled
- **Description**: Automatically broadcast changes to other addon users
- **Network**: Uses addon communication channels

#### Sync Permissions
- **Default**: Officer+ only
- **Description**: Who can make and receive synchronization updates
- **Security**: Prevents unauthorized roll modifications

## 🔍 Debug & Logging

### Logging Levels

#### Debug Level
- **Default**: Info
- **Options**:
  - **Error**: Only critical errors
  - **Warning**: Errors and warnings
  - **Info**: General information messages
  - **Debug**: Detailed debugging information
  - **Trace**: Extremely verbose logging

#### Log to Chat
- **Default**: Enabled
- **Description**: Display log messages in chat window
- **Channel**: Uses a dedicated chat channel or system messages

#### Log to File
- **Default**: Disabled
- **Description**: Save logs to SavedVariables for export
- **File**: Stored in WoW's SavedVariables folder

### Performance Settings

#### Update Frequency
- **Default**: Real-time
- **Options**:
  - Real-time (immediate updates)
  - Every 5 seconds
  - Every 10 seconds
  - Manual refresh only

#### Memory Management
- **Default**: Auto-cleanup enabled
- **Description**: Automatically removes old data to prevent memory leaks
- **Threshold**: Cleans data older than 30 days

## 🎨 Appearance Customization

### Theme Options

#### Color Scheme
- **Default**: WoW Default
- **Options**:
  - WoW Default (blue/gold theme)
  - Dark Mode (dark backgrounds)
  - High Contrast (accessibility)
  - Custom Colors (user-defined)

#### Font Settings
- **Default**: System font
- **Options**:
  - Friz Quadrata (WoW default)
  - Arial
  - Morpheus (WoW header font)
  - Custom font (if available)

#### Border Style
- **Default**: WoW dialog style
- **Options**:
  - WoW Dialog (standard)
  - Thin border
  - No border
  - Custom texture

## 📊 Data Management

### Database Settings

#### Data Retention
- **Default**: 90 days
- **Range**: 7 days - 1 year
- **Description**: How long to keep roll count history
- **Command**: `/slh retention 30` (for 30 days)

#### Backup Settings
- **Default**: Auto-backup enabled
- **Description**: Automatically backs up data to prevent loss
- **Frequency**: Daily backups, keep last 7

#### Reset Options
Various reset commands for data management:

```bash
/slh reset current    # Reset current session only
/slh reset player PlayerName    # Reset specific player
/slh reset all        # Reset all data (requires confirmation)
```

## 🔧 Advanced Configuration

### Command Aliases
Create custom shortcuts for frequently used commands:

```bash
/slh alias "rs" "reset current"    # /slh rs = /slh reset current
/slh alias "st" "status"           # /slh st = /slh status
```

### Macro Integration
Example macros for common operations:

```bash
# Toggle interface with status check
/run if SLH then SLH:Toggle() else print("SLH not loaded") end

# Quick officer roll adjustment
/run if SLH and SLH:IsOfficer() then SLH:AdjustPlayer("TargetName", -1) end
```

### Profile Management
Save and load different configurations:

```bash
/slh profile save "RaidNight"      # Save current settings
/slh profile load "RaidNight"      # Load saved settings
/slh profile list                  # Show available profiles
```

## 🚨 Troubleshooting Config

### Reset to Defaults
If settings become corrupted:

```bash
/slh config reset     # Reset to default settings
/reload               # Reload UI to apply changes
```

### Export/Import Settings
Share configurations with other officers:

```bash
/slh config export    # Creates exportable string
/slh config import "ConfigString"    # Import shared config
```

### Diagnostic Commands
Debug configuration issues:

```bash
/slh config validate  # Check for configuration errors
/slh config debug     # Show detailed config information
```

---

!!! tip "Save Your Settings"
    Configuration changes are automatically saved to your character's SavedVariables. Use `/reload` if settings don't seem to apply immediately.
