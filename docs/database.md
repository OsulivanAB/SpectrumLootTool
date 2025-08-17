# Database System

The Spectrum Loot Helper includes a comprehensive database system for persistent player data storage. This system manages player information including equipment, Venarii charges, and other critical raid data.

## Overview

The Database module provides:
- **Persistent Storage**: All data is automatically saved to your WoW saved variables
- **Version Management**: Automatic handling of WoW version updates and expansions
- **Data Validation**: Comprehensive validation to ensure data integrity
- **Performance Optimization**: Intelligent caching for frequently accessed data

## In-Game Commands

### Database Information
```
/slh database info
```
Displays current database statistics including:
- Total player entries
- Database version
- Memory usage
- Cache performance

### Database Validation
```
/slh database validate
```
Runs a comprehensive validation check on all stored data and reports any issues.

### Database Export
```
/slh database export
```
Exports sanitized database information for debugging purposes (sensitive data is anonymized).

### Database Reset
```
/slh database reset
```
**⚠️ WARNING**: Completely clears all database entries. This action cannot be undone!

### Performance Optimization
```
/slh database optimize
```
Manually triggers database optimization including cache cleanup and performance tuning.

## API Functions for Developers

If you're developing addon extensions or want to integrate with the database, these functions are available:

### Core Database Operations

#### Initialize Database
```lua
SLH.Database:Init()
```
Initializes the database system. Called automatically when the addon loads.

#### Get Player Key
```lua
local playerKey = SLH.Database:GetCurrentPlayerKey()
```
Returns the unique key for the current player in format: `PlayerName-ServerName-WoWVersion`

#### Add New Entry
```lua
local success, result = SLH.Database:AddEntry(playerName, serverName, wowVersion, initialData)
```
Creates a new player entry with the specified data.

#### Retrieve Entry
```lua
local playerData = SLH.Database:GetEntry(playerKey)
```
Retrieves stored data for a specific player.

#### Update Entry
```lua
local success, result = SLH.Database:UpdateEntry(playerName, serverName, wowVersion, updateData)
```
Updates existing player data with new information.

#### Delete Entry
```lua
local success, result = SLH.Database:DeleteEntry(playerKey)
```
Removes a player entry from the database.

### Data Validation Functions

#### Validate Venarii Charges
```lua
local isValid = SLH.Database:ValidateVenariiCharges(charges)
```
Validates that Venarii charges are within acceptable ranges (0-99).

#### Validate Equipment
```lua
local isValid = SLH.Database:ValidateEquipment(equipmentData)
```
Validates equipment data structure for all 16 equipment slots.

#### Validate Complete Entry
```lua
local isValid, errors = SLH.Database:ValidateEntry(entryData)
```
Performs comprehensive validation on a complete player data entry.

### Utility Functions

#### Get Database Statistics
```lua
local stats = SLH.Database:GetDebugStats()
```
Returns detailed statistics about database performance and usage.

#### Check Data Integrity
```lua
local isHealthy, issues = SLH.Database:CheckDataIntegrity()
```
Performs a health check on all stored data and reports any corruption.

#### Get Database Size
```lua
local size = SLH.Database:GetSize()
```
Returns the current number of entries in the database.

#### Clear All Data
```lua
SLH.Database:ClearAllData()
```
**⚠️ WARNING**: Removes all stored data. Use with extreme caution!

## Data Structure

### Player Entry Schema
Each player entry contains:
```lua
{
    playerName = "CharacterName",
    serverName = "ServerName", 
    wowVersion = "11.0",
    timestamp = 1234567890,
    venariiCharges = 25,
    equipment = {
        [1] = { -- Head slot
            itemLink = "[Item Link]",
            needsUpgrade = true,
            -- Additional equipment data
        },
        -- ... entries for all 16 equipment slots
    },
    metadata = {
        lastUpdated = 1234567890,
        version = "0.3.0"
    }
}
```

### Equipment Slots
The system tracks all 16 equipment slots:
1. Head, 2. Neck, 3. Shoulder, 4. Shirt, 5. Chest
6. Waist, 7. Legs, 8. Feet, 9. Wrist, 10. Hands
11. Finger 1, 12. Finger 2, 13. Trinket 1, 14. Trinket 2
15. Back, 16. Main Hand, 17. Off Hand, 18. Ranged

## Version Management

The database automatically handles WoW version updates:
- **Major.Minor Format**: Uses format like "11.0" instead of full patch versions
- **Automatic Migration**: Seamlessly migrates data when expansions release
- **Backward Compatibility**: Maintains compatibility with older data formats

## Performance Features

### Caching System
- Frequently accessed player keys are cached for faster retrieval
- Cache is automatically managed and cleared when needed
- Performance statistics available via `/slh database info`

### Memory Optimization
- Efficient data storage minimizes memory footprint
- Automatic cleanup of temporary data
- Optimized for raid environments with many players

## Troubleshooting

### Common Issues

**Database Not Loading**
- Ensure addon is enabled and loaded properly
- Check for Lua errors in game console
- Try `/slh database validate` to check for corruption

**Performance Issues** 
- Run `/slh database optimize` to clean up cache
- Consider reducing debug logging level
- Check available addon memory in game

**Data Corruption**
- Run `/slh database validate` to identify issues
- Export data with `/slh database export` before making changes
- Contact addon developers with exported data for assistance

### Debug Information
For troubleshooting, provide:
1. Output from `/slh database info`
2. Output from `/slh database validate`  
3. Any relevant error messages from `/console scriptErrors 1`

## Safety Features

- **Automatic Backups**: Critical operations create automatic backups
- **Validation Checks**: All data is validated before storage
- **Error Handling**: Graceful degradation when issues occur
- **Data Sanitization**: Exported data removes sensitive information

The database system is designed to be robust, performant, and safe for use in demanding raid environments while providing powerful tools for data management and debugging.
