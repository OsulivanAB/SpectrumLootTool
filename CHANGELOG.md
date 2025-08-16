# Changelog

## 0.2.0 - Sync System Removal
- **Database Module**: Implemented Database:Init() function for proper database initialization
- **Database Foundation**: Set up SpectrumLootHelperDB.playerData table structure with version tracking
- **Database Integration**: Added Database:Init() call to Core:Init() for proper module initialization
- **Event System**: Implemented Database module event frame registration for ADDON_LOADED event
- **Error Handling**: Added comprehensive error handling and structure validation to Database:Init()
- **Debug Logging**: Added extensive debug logging throughout Database:Init() following project standards
- **Task 1 Complete**: Database initialization and constants properly implemented per strategy
- **Saved Variables**: Enhanced integration with SpectrumLootHelperDB for write capability testing
- **Persistence Validation**: Added addon reload/logout persistence tracking with lastDatabaseAccess timestamp
- **Write Testing**: Implemented saved variables write capability validation in Database:Init()
- **Task 2 Complete**: Saved variables integration fully implemented with persistence and validation
- **Entry Schema**: Implemented Database:GetEntrySchema() function with complete player entry structure
- **Schema Defaults**: Equipment slots default to false, VenariiCharges to 0, includes LastUpdate timestamp
- **Equipment Slots**: All 16 equipment slots properly defined in schema using EQUIPMENT_SLOTS constant
- **Task 3 Complete**: Entry schema creation fully implemented with proper defaults and structure
- **Player Keys**: Implemented Database:GenerateKey() function with PlayerName-ServerName-WoWVersion format
- **Key Validation**: Input parameter validation with nil/empty checking and comprehensive error handling
- **Name Sanitization**: Player and server name cleaning with whitespace and special character removal
- **Version Parsing**: WoW version major.minor extraction (e.g., "10.2.5" -> "10.2")
- **Task 4 Complete**: Player key generation fully implemented with validation and sanitization
- **Current Player Key**: Implemented Database:GetCurrentPlayerKey() using WoW APIs UnitName, GetRealmName, GetBuildInfo
- **Loading State Handling**: Graceful handling of addon loading states with nil returns and warning logs
- **API Integration**: Complete integration with WoW player, server, and version detection APIs
- **Task 5 Complete**: Current player key retrieval fully implemented with loading state handling
- **Venarii Validation**: Implemented Database:ValidateVenariiCharges() with non-negative integer validation
- **Charges Validation**: Number type checking, non-negative validation, and integer validation
- **Task 6 Complete**: Venarii charges validation fully implemented with error details
- **Equipment Validation**: Implemented Database:ValidateEquipment() with complete 16-slot boolean validation
- **Slot Validation**: All equipment slots checked for boolean values with missing slot detection
- **Equipment Structure**: Proper table validation with extra slot warnings and comprehensive error reporting
- **Task 7 Complete**: Equipment validation fully implemented with all 16 slots and boolean checking
- **Entry Validation**: Implemented Database:ValidateEntry() using ValidateVenariiCharges and ValidateEquipment
- **Comprehensive Validation**: Complete entry structure validation with schema checking and field validation
- **Validation Integration**: Full integration of component validation functions with error aggregation
- **Task 8 Complete**: Complete entry validation fully implemented with integrated component validation
- **Error Handling Framework**: Implemented SafeExecute wrapper with pcall for graceful error handling
- **Try-Catch Patterns**: Added comprehensive error handling to all implemented functions (Tasks 1-8)
- **Error Logging**: Enhanced error logging with Debug module integration for all caught exceptions
- **Graceful Degradation**: All functions now handle errors gracefully with appropriate fallbacks and logging
- **Task 9 Complete**: Basic error handling added to all functions with try-catch patterns and error logging
- **Equipment Validation**: Implemented Database:ValidateEquipment() with comprehensive slot validation
- **Slot Type Checking**: All 16 equipment slots validated as booleans with required slot existence checks
- **Extra Slot Detection**: Warning logs for unknown slots while maintaining validation success
- **Task 7 Complete**: Equipment data validation fully implemented with detailed error reporting
- **Complete Entry Validation**: Implemented Database:ValidateEntry() using both validation functions
- **Schema Structure Validation**: Entry structure checking with LastUpdate timestamp validation
- **Integrated Validation**: Uses ValidateVenariiCharges() and ValidateEquipment() for comprehensive validation
- **Field Validation**: Required field existence and type checking with detailed error messages
- **Task 8 Complete**: Complete entry validation fully implemented with comprehensive error handling
- **BREAKING CHANGE**: Removed entire synchronization system to prepare for fresh implementation
- **Code Cleanup**: Removed Sync.lua file and all sync-related functionality from Core.lua
- **Simplified Commands**: Removed sync-related slash commands (/slh syncdebug, /slh syncforce, /slh syncreq, /slh cleanup, /slh sectest)
- **Streamlined Status**: Simplified /slh status command to show basic addon information
- **Local Operation**: Addon now operates locally only - roll count changes are not shared between players
- **Preparation**: Clean foundation for rebuilding sync functionality with improved architecture
- **New Log Module**: Added Log.lua placeholder file for future log management system
- **New Debug System**: Added Debug.lua module for session-based debugging and bug reports
- **Debug Features**: File-based debug logging, in-game log viewing, slash commands for debug control
- **Debug Commands**: Added /slh debuglog commands for debug logging management
- **Architecture**: Structured log system with WoW version tracking, entry validation, and future sync compatibility
- **Debug System Init**: Implemented Debug:Init() function for system bootstrap and state management
- **Saved Variables**: Integrated debug settings with SpectrumLootHelperDB for persistent storage
- **Debug State Management**: Implemented Debug:SetEnabled() with validation, persistence, and user feedback
- **State Toggle**: Debug logging can now be enabled/disabled with proper state management
- **User Feedback**: Added colored chat messages for debug state changes
- **Debug State Query**: Implemented Debug:IsEnabled() for fast, reliable state checking throughout system
- **Defensive Programming**: Added state validation to prevent corruption and ensure reliability
- **File System Utilities**: Implemented Debug:GetLogFileInfo() for file path management and status checking
- **WoW Compatibility**: Designed file operations to work within WoW's limited file system access
- **Phase 1 Foundation**: Completed Tasks 1-4, establishing solid debug system foundation
- **Core Logging Engine**: Implemented Debug:Log() central logging function with proper memory management
- **Convenience Logging**: Added type-safe wrapper functions (LogInfo, LogWarn, LogError, LogDebug)
- **File Persistence**: Implemented Debug:FlushToFile() for persisting logs to WoW saved variables
- **Log Retrieval**: Implemented Debug:GetSessionLogs() with filtering, sorting, and performance optimization
- **Session Management**: Added Debug:StartSession() and Debug:ClearLogs() for session lifecycle control
- **System Statistics**: Implemented Debug:GetStats() with comprehensive health and usage information
- **Performance Metrics**: Added memory usage calculation, categorization, and performance analytics
- **Human-Readable Formatting**: Added helper functions for bytes and duration formatting
- **Real-time Analysis**: Statistics calculated dynamically from current session state
- **WoW Context Integration**: Included WoW version, player, and realm information in stats
- **Core Logging Engine Complete**: Finished Tasks 5-11, completing Phase 3 implementation
- **In-Game Log Display**: Implemented Debug:DisplayLogsInChat() for WoW chat window display
- **Color-Coded Output**: Added log level color coding (ERROR=red, WARN=orange, INFO=green, DEBUG=gray)
- **Chat Formatting**: Professional WoW addon chat formatting with headers, footers, and alignment
- **Filter Integration**: Seamless integration with existing GetSessionLogs() filtering capabilities
- **Pagination Support**: Configurable entry count with pagination information display
- **Session Time Display**: Human-readable session time formatting for log entries
- **Data Context**: Optional display of log data with length limiting to prevent chat spam
- **User Interface Foundation**: Started Phase 4 implementation with Task 12 complete
- **Dev Container Enhancement**: Added Lua 5.3 and luac to dev container for syntax checking and testing
- **Development Tools**: Updated local development guide with Lua syntax validation commands
- **CI Enhancement**: Added automated Lua syntax checking to GitHub Actions CI pipeline
- **PR Quality Gate**: All pull requests now require valid Lua syntax before merge
- **Automated Testing**: CI validates syntax of all .lua files and TOC-referenced files
- **Release Guidance**: Added comprehensive GitHub release guidance document for Copilot assistance
- **Changelog Optimization**: Included Copilot commands for release preparation and changelog cleanup
- **Semantic Versioning**: Added optimized Copilot command for semantic versioning validation and correction
- **Version Decision Matrix**: Created detailed guidelines for MAJOR/MINOR/PATCH version increment decisions
- **GitIgnore Validation**: Added dynamic Copilot command to validate against .gitignore file references
- **Content Filtering**: Ensures no ignored files are mentioned in changelogs or commit messages
- **Note**: This version will not sync data between players - use only for testing or single-player scenarios

## 0.1.17 - Permanent Fix for Officer Arrow Visibility Bug
- **MAJOR BUG FIX**: Completely overhauled officer detection system to permanently resolve recurring arrow visibility issues
- **Enhanced Guild Detection**: Added fallback mechanisms when `GetGuildInfo()` returns incomplete data
- **Flexible Guild Matching**: Improved guild name matching to handle various server name formats
- **Debug System**: Added comprehensive debugging tools - use `/slh debug` to troubleshoot officer detection
- **Additional Events**: Added `GUILD_ROSTER_UPDATE`, `PLAYER_LOGIN`, and `PLAYER_ENTERING_WORLD` event handlers
- **Manual Refresh**: Right-click main window or use `/slh refresh` to manually refresh officer status
- **Extended Commands**: Added `/slh status`, `/slh help`, and `/slh debug` for better troubleshooting
- **Robust Recovery**: System now automatically recovers when guild data becomes available after login
- **Persistent Solution**: This addresses the root cause and should prevent future occurrences of missing arrows

## 0.1.16 - WowUp Icon Support Enhancement
- **WowUp Icon Fix**: Added `.pkgmeta` file to enable proper icon display in WowUp
- **Package Metadata**: WowUp will now show custom addon icon instead of GitHub avatar
- **Improved User Experience**: Better visual identification for WowUp users
- **Enhanced Packaging**: Updated release workflow to include `.pkgmeta` for proper addon manager integration

## 0.1.15 - Added Addon Icon
- **New Feature**: Added custom addon icon for better visual identification
- **Icon Integration**: Updated TOC file to include IconTexture directive for addon managers
- **File Management**: Renamed image file to standard `icon.png` format
- **WowUp Enhancement**: Icon will now display in WowUp and other compatible addon managers

## 0.1.14 - Officer Arrow Visibility Fix
- **Bug Fix**: Fixed issue where officer arrows (up/down buttons) were not showing for guild officers
- **Improved Guild Detection**: Enhanced guild name matching to handle server suffixes (e.g., "Spectrum Federation - Garona")
- **Better Error Handling**: Added defensive programming to prevent crashes when guild data is unavailable
- **Code Cleanup**: Removed problematic debug output that wasn't displaying properly in chat

## 0.1.13 - WowUp Compatibility and Automated Releases
- **WowUp Integration**: Repository fully configured for WowUp addon manager distribution
- **Automated Releases**: GitHub Actions workflows for CI validation and automated packaging
- **Release Automation**: Helper scripts for streamlined version management and releases
- **Enhanced Documentation**: Comprehensive setup guides and development workflows
- **Version Validation**: Automated checks prevent version mismatches and broken releases
- **ZIP Packaging**: Automated creation of WowUp-compatible release packages
- **Installation Support**: Users can now install via WowUp using repository URL

## 0.1.12 - Log-based synchronization system
- **Major rework**: Implemented log-based synchronization system
- Changes are now synced as log entries rather than final values
- Multiple players can make changes offline and sync properly when rejoining
- Added RecalculateFromLog() function to rebuild values from complete log history
- Added unique IDs to log entries to prevent duplicates during sync
- Backward compatibility maintained for existing data

## 0.1.11 - Improved data synchronization
- Enhanced sync logic to trigger when players join/leave raid groups (GROUP_ROSTER_UPDATE)
- Improved sync data handling to only update UI when data actually changes
- Added sync trigger documentation to copilot instructions

## 0.1.10 - Officer rank threshold adjustment
- Changed officer rank threshold from 3 to 2 (now ranks 0-2 can use adjustment controls)
- Updated documentation to reflect new officer permissions

## 0.1.9 - Debug improvements and bug fixes
- Added debug output to help troubleshoot officer permission issues
- Updated version number in Core.lua to match .toc file
- Fixed potential issue with guild rank detection for arrow button visibility

## 0.1.8 - UI layout improvements
- Changed up/down arrow buttons from vertical stack to side-by-side layout for better spacing and less cramped appearance.

## 0.1.7 - Officer adjustment buttons
- Officers now have up and down arrow buttons to modify each player's roll count from the main UI.

## 0.1.6 - Solo roster display
- UI now shows the player's own entry when not in a raid and the outside raid option is enabled.
- Roster automatically refreshes when group membership or roll counts change.

## 0.1.5 - Movable frame
- Frame position can be locked or unlocked and dragged around the screen.
- Saved user-chosen frame position between sessions.

## 0.1.4 - Conditional frame visibility
- Main UI frame hides only during combat or when outside raids without the override setting.

## 0.1.3 - Options category visible
- Registered addon options with the modern Settings API so it appears under Options > AddOns.

## 0.1.2 - Root addon folder
- Moved addon `.toc` and Lua files to the repository root so the game detects the addon when cloned.

## 0.1.1 - Added outside raid toggle
- Added settings option to enable the addon outside raid groups.
- Core logic now disables the UI unless in a raid and out of combat.

## 0.1.0 - First Version
- Initial skeleton of Spectrum Loot Helper addon.
- Basic UI frame toggled with `/slh`.
- Database and officer check stubs.
- Introduced data sync module to share roll counts across the raid.
- Use addon namespace to avoid polluting the global table.
