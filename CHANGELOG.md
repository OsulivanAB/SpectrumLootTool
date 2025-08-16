# Changelog

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
