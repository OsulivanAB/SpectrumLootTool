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
- **Add Entry Function**: Implemented Database:AddEntry() with complete duplicate checking and schema application
- **Duplicate Prevention**: Entry addition checks for existing keys before adding to prevent data conflicts
- **Schema Application**: New entries use GetEntrySchema() template with proper defaults for all fields
- **Initial Data Support**: Optional initialData parameter allows setting VenariiCharges and Equipment on creation
- **Data Validation**: All initial data validated using ValidateVenariiCharges() and ValidateEquipment() before application
- **Timestamp Management**: LastUpdate automatically set to current time for all new entries
- **Entry Validation**: Complete entry validation using ValidateEntry() before saving to database
- **Migration Support**: Implemented Database:MigrateToNewWoWVersion() for WoW version transitions and expansion compatibility
- **Version Migration**: Comprehensive migration system creates fresh entries for new WoW versions with reset values
- **Charges Reset**: All Venarii charges reset to 0 for new version entries during migration process
- **Equipment Reset**: All 16 equipment slots reset to false for new version entries during migration
- **Data Preservation**: Old version data preserved for historical tracking and rollback capability
- **Migration Statistics**: Comprehensive migration reporting with entry counts, player statistics, and operation summary
- **Key Generation**: Automatic generation of new version player keys using updated WoW version information
- **Migration Validation**: Input parameter validation and database state checking before migration operations
- **Task 15 Complete**: Basic migration support fully implemented with data preservation and comprehensive reset functionality
- **Data Integrity Checking**: Implemented Database:CheckDataIntegrity() for comprehensive database validation and corruption detection
- **Schema Validation**: Complete validation of all database entries against schema requirements with detailed error reporting
- **Corruption Detection**: Automatic detection of corrupted entries, invalid data types, and structural integrity issues
- **Orphaned Entry Detection**: Identification of entries with malformed keys or invalid format patterns
- **Data Consistency Verification**: Cross-validation between player keys and entry data for consistency checking
- **Integrity Reporting**: Comprehensive integrity reports with issue categorization, severity levels, and detailed statistics
- **Multiple Version Support**: Proper handling and reporting of multiple WoW version entries per player
- **Success Rate Analytics**: Statistical analysis with success rates, issue counts, and performance metrics
- **Task 16 Complete**: Data integrity checking fully implemented with comprehensive validation and detailed reporting
- **Database Debug Statistics**: Implemented Database:GetDebugStats() for comprehensive database monitoring and performance analysis
- **Entry Statistics**: Complete statistics collection including total entries, memory usage, version distribution, and player analytics
- **Memory Usage Analysis**: Detailed memory consumption tracking with entry-level granularity and human-readable formatting
- **Version Distribution**: Comprehensive breakdown of entries by WoW version, players, and servers for trend analysis
- **Integrity Monitoring**: Real-time integrity checking with validation status, corruption detection, and health scoring
- **Performance Metrics**: Collection time tracking, entry size analysis, and performance optimization data
- **Health Status Assessment**: Automatic health status determination based on integrity rates and corruption levels
- **Summary Analytics**: Player count, server distribution, version tracking, and overall database health metrics
- **Helper Functions**: Memory formatting, unique key counting, and health status determination utilities
- **Task 17 Complete**: Database debug statistics fully implemented with comprehensive monitoring and performance analysis
- **Database Debug Export**: Implemented Database:ExportForDebug() for sanitized database export suitable for debugging and developer support
- **Sanitized Data Export**: Complete database export with sensitive information removed while preserving diagnostic value
- **Privacy Protection**: Player name hashing and data sanitization ensuring safe sharing with developers
- **System Information**: Comprehensive system context including WoW version, build info, realm, and addon version
- **Structured Export Format**: Human-readable export format with clear sections for statistics, samples, and diagnostics
- **Sample Entry Analysis**: Sanitized sample entries showing data structure patterns without exposing sensitive information
- **Distribution Analytics**: Version and server distribution analysis for trend identification and debugging
- **Integrity Reporting**: Detailed integrity issue reporting with sanitized key patterns and error descriptions
- **Export Diagnostics**: Performance metrics, privacy level indicators, and sanitization method documentation
- **Safe Sharing**: Export designed for safe sharing with developers while maintaining full diagnostic capability
- **Task 18 Complete**: Database debug export fully implemented with comprehensive sanitization and developer-friendly formatting
- **Database Schema Upgrade**: Implemented Database:UpgradeSchema() for safe database schema migrations between versions
- **Version Compatibility**: Comprehensive version compatibility checking with supported upgrade path validation
- **Data Backup System**: Complete database backup creation before schema upgrades with rollback capability for safety
- **Schema Change Application**: Version-specific schema changes with tracking and history management
- **Entry Migration**: Automated migration of existing entries to new schema formats with field-level transformations
- **Rollback Protection**: Automatic rollback of failed upgrades with complete data restoration from backup
- **Upgrade Statistics**: Detailed upgrade statistics tracking entries processed, changes applied, and migration success rates
- **Automatic Detection**: Integration with Database:Init() for automatic schema upgrade detection and execution
- **Upgrade History**: Complete schema upgrade history tracking with timestamps and change documentation
- **Error Recovery**: Comprehensive error handling with graceful degradation and detailed error reporting
- **Task 19 Complete**: Database schema upgrade system fully implemented with automatic detection, backup, and rollback capabilities
- **Database Utility Functions**: Implemented Database:ClearAllData() and Database:GetSize() for database maintenance and monitoring
- **Data Clearing System**: Comprehensive data clearing with safety confirmations, verification, and preservation of critical system metadata
- **Size Analysis System**: Detailed database size analysis with memory usage breakdown, entry statistics, and storage efficiency metrics
- **Clear Data Protection**: Safe data clearing with entry counting, metadata preservation, and operation history tracking
- **Size Monitoring**: Real-time size calculation with entry analysis, key statistics, and storage optimization recommendations
- **Efficiency Metrics**: Storage efficiency analysis with overhead calculation and optimization level assessment
- **Entry Size Distribution**: Comprehensive entry size analysis with distribution tracking and performance insights
- **Key Analysis**: Player key analysis with unique version, server, and player counting for database insights
- **Metadata Preservation**: Database clearing preserves schema version, upgrade history, and critical system information
- **Task 20 Complete**: Database utility functions fully implemented with comprehensive data management and monitoring capabilities
- **Event Registration & Module Integration**: Implemented comprehensive OnAddonLoaded event handler with proper database initialization
- **ADDON_LOADED Event Handler**: Enhanced OnAddonLoaded function automatically calls Database:Init() when addon loads
- **Event Frame Management**: Proper event frame creation with named frame "SLH_DatabaseEventFrame" for better debugging
- **Event Cleanup**: Automatic ADDON_LOADED event unregistration after successful initialization to prevent multiple calls
- **Database Constants Logging**: Comprehensive logging of DB_VERSION and EQUIPMENT_SLOTS constants during initialization
- **Event Handler Cleanup**: Added Database.CleanupEventHandlers() function for proper module shutdown and event cleanup
- **Initialization Status Tracking**: Detailed logging of initialization success/failure with comprehensive status reporting
- **Event-Driven Architecture**: Proper integration of database initialization with WoW addon event system
- **Initialization Safety**: Prevents multiple initialization calls through event unregistration after successful setup
- **Task 21 Complete**: Event registration and module integration fully implemented with proper cleanup and initialization
- **Database Performance Optimization**: Implemented comprehensive performance caching system for frequently accessed database functions
- **Player Key Caching**: Cached GetCurrentPlayerKey() results with 5-minute TTL to minimize WoW API calls during frequent operations
- **Schema Caching**: Cached GetEntrySchema() results to eliminate repeated schema generation with deep-copy protection
- **System Info Caching**: Cached GetRealmName() and GetBuildInfo() with intelligent refresh intervals for system stability
- **Cache Management**: Automatic cache invalidation and cleanup with configurable TTL for different data types
- **Optimized Functions**: Created GetCurrentPlayerKeyOptimized() and GetEntrySchemaOptimized() for high-performance operations
- **Memory Optimization**: Intelligent cache cleanup prevents memory bloat with automatic expiration of stale cache entries
- **Cache Statistics**: Added GetPerformanceCacheStats() for monitoring cache hit rates and performance metrics
- **Cache Control**: Implemented ClearPerformanceCache() for manual cache invalidation and testing scenarios
- **Task 23 Complete**: Database performance optimization fully implemented with caching system and memory management
- **Database Integration Testing**: Implemented comprehensive integration test suite for all database functions and module interactions
- **Core Function Integration Tests**: Complete testing of database initialization, player key generation, entry lifecycle, and validation functions
- **Advanced Function Integration Tests**: Testing of version management, data integrity, statistics, performance optimization, and schema upgrades
- **Module Integration Tests**: Verification of integration with Debug module, Core module, saved variables, and event system
- **Debug Logging Validation**: Comprehensive testing of component naming consistency, context data inclusion, and error logging functionality
- **Test Categories**: Four major test categories covering core functions, advanced functions, module integration, and debug logging
- **Automated Test Execution**: Single function RunIntegrationTests() executes all test categories with detailed reporting
- **Test Result Analysis**: Success rate calculation, issue tracking, and automated recommendations for improvement
- **Comprehensive Coverage**: Tests verify all database functions work together properly and integrate correctly with addon architecture
- **Task 24 Complete**: Integration testing fully implemented with comprehensive test coverage and automated validation
- **Database Persistence**: New entries saved to SpectrumLootHelperDB.playerData with proper error handling
- **Task 10 Complete**: Add new entry functionality fully implemented with validation, duplicate checking, and persistence
- **Retrieve Entry Function**: Implemented Database:GetEntry() with comprehensive entry retrieval and safe null handling
- **Safe Null Handling**: Returns nil for missing entries, invalid keys, or corrupted database structures
- **Database Structure Validation**: Checks for SpectrumLootHelperDB and playerData table availability before access
- **Entry Integrity Checking**: Optional entry validation against schema with warning logs for corrupted data
- **Comprehensive Logging**: Detailed logging for entry lookup attempts, results, and data integrity status
- **Error Recovery**: Graceful handling of missing database, invalid keys, and corrupted entries with proper fallbacks
- **Task 11 Complete**: Retrieve entry functionality fully implemented with safe null handling and integrity checking
- **Update Entry Function**: Implemented Database:UpdateEntry() with comprehensive partial update support and validation
- **Partial Updates**: Supports updating individual fields (VenariiCharges, Equipment slots) without affecting other data
- **Change Tracking**: Detailed tracking and logging of all field changes during update operations
- **Entry Existence Validation**: Checks for existing entries before attempting updates to prevent creation
- **Deep Copy Safety**: Safe deep copying of existing entries to prevent data corruption during updates
- **Update Data Validation**: Comprehensive validation of update data using ValidateVenariiCharges() and ValidateEquipment()
- **Equipment Slot Updates**: Supports partial equipment updates for individual slot modifications
- **Timestamp Management**: Automatic LastUpdate timestamp updating for all successful entry modifications
- **Pre-save Validation**: Complete entry validation using ValidateEntry() before saving updated data
- **Change Logging**: Detailed logging of all changed fields with old and new values for debugging
- **Task 12 Complete**: Update existing entry functionality fully implemented with partial updates and comprehensive validation
- **Delete Entry Function**: Implemented Database:DeleteEntry() with comprehensive existence checking and data cleanup
- **Entry Existence Validation**: Checks for entry existence before deletion to prevent errors on non-existent entries
- **Data Backup**: Creates complete backup copy of deleted entry for logging and potential recovery purposes
- **Database Cleanup**: Proper removal of entries from SpectrumLootHelperDB.playerData with verification
- **Deletion Verification**: Post-deletion verification to ensure entries are properly removed from database
- **Related Data Cleanup**: Framework for cleaning up any related data or cross-references (future-proofing)
- **Statistics Tracking**: Comprehensive logging of database statistics before and after deletion operations
- **Success/Failure Status**: Clear return values indicating deletion success or failure with detailed error messages
- **Task 13 Complete**: Delete entry functionality fully implemented with existence checking and comprehensive cleanup
- **Version Query Function**: Implemented Database:GetCurrentVersionEntries() with current WoW version filtering
- **Version Filtering**: Filters database entries by current WoW version using GetBuildInfo() API integration
- **Version Statistics**: Comprehensive version breakdown statistics with counts for all versions in database
- **Key Pattern Parsing**: Robust extraction of version information from player keys using pattern matching
- **Current Version Detection**: Automatic detection of current WoW version with major.minor format extraction
- **Database Structure Safety**: Safe handling of missing database or playerData table with proper fallbacks
- **Comprehensive Logging**: Detailed logging of version filtering results, statistics, and matching entries
- **Empty Database Handling**: Graceful handling of empty databases with appropriate return values
- **Task 14 Complete**: Current version entries retrieval fully implemented with version filtering and statistics
- **Database Persistence**: New entries saved to SpectrumLootHelperDB.playerData with proper error handling
- **Task 10 Complete**: Add new entry functionality fully implemented with validation, duplicate checking, and persistence
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
