# Spectrum Loot Helper

Spectrum Loot Helper tracks Best-in-Slot roll counts for the Spectrum Federation guild.

## Installation

### WowUp (Recommended)

1. Open WowUp
2. Go to **Addons** → **Install from URL**
3. Enter the repository URL: `https://github.com/OsulivanAB/SpectrumLootTool`
4. Click **Install**
5. WowUp will automatically download and install the addon
6. The addon will auto-update when new releases are available

### Manual Installation

1. Download the latest release ZIP file from the [Releases page](https://github.com/OsulivanAB/SpectrumLootTool/releases)
2. Extract the ZIP file
3. Copy the `SpectrumLootTool` folder to your World of Warcraft AddOns directory:
   - **Windows**: `World of Warcraft\_retail_\Interface\AddOns\`
   - **Mac**: `Applications/World of Warcraft/_retail_/Interface/AddOns/`
4. Restart World of Warcraft or reload your UI (`/reload`)

## Usage

- Use `/slh` in-game to toggle the addon window.
- Officer rank threshold can be edited in `Core.lua` via `OFFICER_RANK`.
- Roll count changes automatically sync with other raid members.
- Officers see arrow buttons next to each player to adjust roll counts.
- In-game, open **Options > AddOns > Spectrum Loot Helper** and enable **Outside Raid** to use the addon while not in a raid group.
- When enabled outside raids, the window still lists your character so you can monitor your own roll count while solo.
- Unlock the frame in **Options > AddOns > Spectrum Loot Helper** to drag it to a preferred position. The addon remembers where you place it.

## Development

Source code resides in the repository root. The addon is organized into
separate Lua files for core logic, data syncing, and UI.

### For Developers

This repository is configured for WowUp compatibility with automated releases:

- **CI Validation**: Every push and pull request validates addon structure and version consistency
- **Automated Releases**: Creating a git tag (e.g., `v0.1.13`) automatically packages and releases the addon
- **WowUp Integration**: Released ZIP files are properly structured for WowUp consumption

For setup instructions, see the guides in `.devcontainer/`:
- `manual_github_actions_setup.md` - One-time GitHub setup
- `local_tasks_guide.md` - Development workflow and maintenance

## Compatibility

- **World of Warcraft**: Retail (current patch)
- **Interface Version**: 100207 (updated with WoW patches)
- **WowUp**: Fully compatible - use repository URL for installation
