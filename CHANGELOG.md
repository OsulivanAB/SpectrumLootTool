# Changelog

## 0.4.0 - Audit Logging System

### ✨ **New Features**

- **Audit Logging System**: Complete structured logging system for officer actions with comprehensive tracking
- **Officer Permission Gating**: Role-based access control using existing guild rank system (rank ≤ 2)
- **Unique Log ID Generation**: Hash-based identifiers with collision detection for reliable log entry tracking
- **Log Entry Management**: Create, retrieve, and delete audit log entries with full validation and error handling

### 🔧 **Technical Improvements**

- **Performance Optimization**: Cached player information, server names, and officer status with intelligent cache management
- **Database Integration**: Persistent storage in `SpectrumLootHelperDB.auditLog` with version tracking for future migrations
- **Comprehensive Testing**: Integration tests, functionality verification, and performance monitoring with detailed reporting
- **Error Handling**: Protected API calls with graceful degradation and comprehensive error logging throughout

### 🎯 **User Experience**

- **Combat-Aware Operations**: Reduced debug logging during combat scenarios for optimal gameplay performance
- **Memory Management**: Storage optimization features with configurable entry limits and automatic cleanup
- **Debug Integration**: Seamless integration with existing SLH.Debug system using "Logging" component identifier
- **Comprehensive Validation**: Parameter validation for field types ("Venari Charges"/"Gear Slot") and change values

### 🚀 **Infrastructure**

- **GitHub Actions Enhancement**: Improved release workflow with pre-release detection and better version handling
- **Core Integration**: Automatic initialization of logging system during addon startup with success tracking

## 0.3.4 - Enhanced Issue Reporting System

### ✨ **New Features**
- **GitHub Issue Forms**: Converted all issue templates from markdown to interactive GitHub forms
- **Structured Bug Reports**: New form-based bug reporting with required fields and validation
- **Enhanced Feature Requests**: Improved feature request form with priority levels and context categories
- **Streamlined Support**: Redesigned support form with self-help checklist and common solutions

### 🔧 **Technical Improvements**
- **Form Validation**: Added required field validation to ensure complete bug reports
- **Debug Log Integration**: Mandatory debug logs section in bug reports with clear instructions
- **User Experience**: Dropdown selections, checkboxes, and structured input fields for better data collection
- **Issue Routing**: Improved categorization and labeling for faster issue resolution

### 🎯 **User Experience**
- **Self-Service Support**: Built-in troubleshooting steps and common solutions in support template
- **Clear Instructions**: Step-by-step debug log collection guide in bug reports
- **Comprehensive Context**: Enhanced form fields capture system info, guild context, and technical details
- **Quality Assurance**: Required acknowledgment checkboxes ensure users understand submission requirements

## 0.3.3 - Show All Known Players Feature

### ✨ **New Features**
- **Show All Players Setting**: Added option to display all known players from the database instead of just current party/raid members
- **Comprehensive Player List**: View all players who have been tracked by the addon across different sessions
- **Enhanced Settings Panel**: New checkbox option "Show all known players (not just current group)" in addon settings

### 🔧 **Technical Improvements**
- Added `GetAllKnownPlayers()` function to retrieve unique players from database across servers and versions
- Enhanced `UpdateRoster()` function to support both group-only and all-players display modes
- Improved debug logging to track roster display mode changes
- Added automatic roster refresh when toggling the show all players setting

### 🎯 **User Experience**
- Players can now see historical loot data for all guild members, not just those currently online
- Setting is persistently saved and applies immediately when changed
- Maintains existing functionality when disabled (default behavior)

## 0.3.2 - GitHub Pages Documentation Deployment

### 🚀 **Infrastructure**
- **GitHub Pages Integration**: Added automated MkDocs deployment to GitHub Pages
- **Documentation Hosting**: Documentation is now automatically deployed to GitHub Pages on every merge to main
- **CI/CD Workflow**: New GitHub Actions workflow for building and deploying MkDocs site
- **Public Documentation Access**: Users can now access documentation at the project's GitHub Pages URL

### 🔧 **Technical Improvements**
- Enhanced development workflow with automated documentation deployment
- Improved documentation accessibility for end users and developers

## 0.3.1 - Documentation Enhancement

### 📚 **Documentation**
- **Database System Guide**: Added comprehensive documentation for the database system
- **In-Game Commands**: Complete reference for all database-related slash commands
- **Developer API**: Detailed API documentation for addon developers and integrations
- **Data Structure**: Full specification of player entry schema and equipment slots
- **Troubleshooting**: User guides for common issues and performance optimization
- **MkDocs Integration**: Updated site navigation to include database documentation

### 🔧 **Technical Improvements**
- Enhanced mkdocs.yml configuration for better documentation organization
- Improved user accessibility to database features and functionality

## 0.3.0 - Complete Database Module Implementation

### 🎯 **Major Features**
- **Complete Database System**: Implemented comprehensive database management module for player data persistence
- **Data Persistence**: Enhanced integration with SpectrumLootHelperDB saved variables system
- **WoW Version Support**: Automatic WoW version detection with major.minor format (prevents new entries per patch)
- **Event Integration**: Proper ADDON_LOADED event handling with automatic database initialization

### 🛠 **Database Operations**
- **Entry Management**: Full CRUD operations (Create, Read, Update, Delete) for player entries
- **Player Key Generation**: Automatic player key generation using PlayerName-ServerName-WoWVersion format
- **Data Validation**: Comprehensive validation for Venarii charges and 16-slot equipment data
- **Version Migration**: Automatic migration system for WoW expansion compatibility

### ⚡ **Performance & Reliability**
- **Performance Optimization**: Intelligent caching system for frequently accessed functions
- **Error Handling**: Comprehensive error handling with graceful degradation
- **Data Integrity**: Built-in corruption detection and integrity checking
- **Memory Management**: Optimized memory usage with automatic cache cleanup

### 📊 **Monitoring & Debugging**
- **Debug Statistics**: Real-time database statistics and health monitoring
- **Integration Testing**: Comprehensive test suite for all database functions
- **Data Export**: Sanitized data export for debugging and developer support
- **Validation Framework**: Automated validation for module completeness

### 🔧 **Technical Improvements**
- **Schema Upgrades**: Automatic database schema upgrade system with backup/rollback
- **Utility Functions**: Database size analysis and data management tools
- **Debug Logging**: Consistent debug logging throughout with "Database" component naming
- **Entry Schema**: Standardized entry structure with proper defaults and timestamp management

### ⚠️ **Important Notes**
- Database module provides foundation for future sync system implementation
- All existing player data is preserved during upgrade
- Enhanced debug system with comprehensive logging and monitoring

---

## 0.2.0 - Sync System Removal
- **Breaking Change**: Removed entire synchronization system to prepare for fresh implementation
- **Code Cleanup**: Removed Sync.lua file and all sync-related functionality from Core.lua
- **Simplified Commands**: Removed sync-related slash commands (/slh syncdebug, /slh syncforce, /slh syncreq, /slh cleanup, /slh sectest)
- **Streamlined Status**: Simplified /slh status command to show basic addon information
- **Local Operation**: Addon now operates locally only - roll count changes are not shared between players
- **Preparation**: Clean foundation for rebuilding sync functionality with improved architecture
- **Enhanced Debug System**: Added comprehensive Debug.lua module for session-based debugging and bug reports
- **Debug Commands**: Added /slh debuglog commands for debug logging management

## 0.1.17 - Permanent Fix for Officer Arrow Visibility Bug
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
