# Spectrum Loot Helper

Spectrum Loot Helper tracks Best-in-Slot roll counts for the Spectrum Federation guild.

## Installation via WoWUP

1. Open WoWUP.
2. Choose **Addons** > **Install from URL**.
3. Enter the GitHub repository URL for this project.
4. WoWUP downloads the addon and places it in your addons directory.

Manual installation is also possible by cloning or copying this repository
directly into your `Interface/AddOns` folder. The resulting `SpectrumLootTool`
directory contains the addon's `.toc` and Lua files.

## Usage

- Use `/slh` in-game to toggle the addon window.
- Officer rank threshold can be edited in `Core.lua` via `OFFICER_RANK`.
- Roll count changes automatically sync with other raid members.
- In the Blizzard Interface Options, enable **Outside Raid** to use the addon while not in a raid group.

## Development

Source code resides in the repository root. The addon is organized into
separate Lua files for core logic, data syncing, and UI.
