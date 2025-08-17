# SpectrumLootTool

<div align="center">

![Spectrum Loot Helper Icon](icon.png)

**A comprehensive loot distribution and tracking addon for the Spectrum Federation guild**

[![Latest Release](https://img.shields.io/github/v/release/OsulivanAB/SpectrumLootTool)](https://github.com/OsulivanAB/SpectrumLootTool/releases)
[![WoW Interface](https://img.shields.io/badge/WoW-Retail-blue)](https://github.com/OsulivanAB/SpectrumLootTool)
[![WowUp Compatible](https://img.shields.io/badge/WowUp-Compatible-green)](https://wowup.io/)

</div>

---

## 📋 Overview

SpectrumLootTool is a specialized World of Warcraft addon designed for the **Spectrum Federation** guild (Garona-US) to streamline loot distribution during raids. The addon tracks Best-in-Slot (BiS) roll counts across all raid members with real-time synchronization, ensuring fair and transparent loot distribution.

### ✨ Key Features

- 🎲 **BiS Roll Tracking** - Automatic tracking of Best-in-Slot roll counts per player
- 🔄 **Real-time Sync** - Instant synchronization of roll data across all raid members
- 👑 **Officer Controls** - Dedicated interface for officers to manage roll counts
- 🖱️ **Drag & Drop Interface** - Movable, resizable frame with persistent positioning
- 🏠 **Outside Raid Support** - Optional usage outside of raid groups for personal tracking
- 🎯 **Guild Integration** - Designed specifically for Spectrum Federation workflows

## 🚀 Installation

### WowUp (Recommended)

The easiest way to install and keep SpectrumLootTool updated:

1. **Install WowUp** from [wowup.io](https://wowup.io/) if you haven't already
2. Open WowUp and navigate to **Addons** → **Install from URL**
3. Enter the repository URL: `https://github.com/OsulivanAB/SpectrumLootTool`
4. Click **Install**
5. 🎉 **Done!** The addon will auto-update with new releases

### Manual Installation

For users preferring manual installation:

1. Visit our [Releases page](https://github.com/OsulivanAB/SpectrumLootTool/releases)
2. Download the latest release ZIP file
3. Extract the contents to your WoW AddOns directory:
   - **Windows**: `World of Warcraft\_retail_\Interface\AddOns\`
   - **Mac**: `Applications/World of Warcraft/_retail_/Interface/AddOns/`
4. Restart World of Warcraft or use `/reload` in-game

## 🎮 Usage Guide

### Basic Commands

- **`/slh`** - Toggle the main addon window
- **`/slh debuglog on/off`** - Enable/disable debug logging
- **`/slh debuglog show`** - Display recent debug logs

### Interface Features

#### For All Users
- **View Roll Counts** - See current BiS roll counts for all raid members
- **Real-time Updates** - Watch roll counts update automatically as they change
- **Position Control** - Drag the window to your preferred screen location

#### For Officers
- **Adjust Roll Counts** - Use arrow buttons to increase/decrease player roll counts
- **Manage Distribution** - Override roll counts when needed for fair distribution
- **Access Controls** - Officer privileges based on guild rank settings

### Configuration Options

Access addon settings via **Options** → **AddOns** → **Spectrum Loot Helper**:

- **Outside Raid** - Enable to use the addon when not in a raid group
- **Unlock Frame** - Allow dragging the window to reposition it
- **Debug Logging** - Control debug output levels for troubleshooting

## 📚 Documentation

For detailed documentation, development guides, and advanced configuration:

**📖 [View Full Documentation](https://osulivanab.github.io/SpectrumLootTool/)**

The documentation site includes:
- Complete feature explanations
- Database system architecture
- Development and contribution guidelines
- Troubleshooting and FAQ

## 🛠️ Development

### Project Structure

```
SpectrumLootTool/
├── Core.lua                 # Main logic and initialization
├── UI.lua                   # User interface and event handling  
├── Database.lua             # Data management and storage
├── Log.lua                  # Roll tracking functionality
├── Debug.lua                # Debug system and logging
├── SpectrumLootTool.toc     # Addon metadata and dependencies
├── docs/                    # MkDocs documentation source
└── .devcontainer/           # Development environment setup
```

### Development Standards

This project follows strict coding standards:

- **Code Style**: 4-space indentation, camelCase functions, UPPER_CASE constants
- **Debugging**: Mandatory debug logging in every function
- **Testing**: In-game validation required before commits
- **Documentation**: Comprehensive inline and external documentation

### Contributing

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/awesome-feature`)
3. **Follow** the coding standards outlined in `.vscode/copilot-instructions.md`
4. **Test** thoroughly in-game
5. **Submit** a pull request

### Automated Release Process

This repository uses GitHub Actions for automated releases:

- **CI Validation** - Automatic code validation on every push/PR
- **Automated Releases** - Create git tags (e.g., `v0.1.13`) to trigger releases
- **WowUp Integration** - Releases are automatically compatible with WowUp

For detailed development setup, see `.devcontainer/local_tasks_guide.md`.

## 🔧 Compatibility

- **World of Warcraft**: Retail (Current Patch)
- **Interface Version**: Automatically updated with WoW patches
- **Dependencies**: None - fully self-contained
- **Guild**: Optimized for Spectrum Federation (Garona-US)
- **Installation Methods**: WowUp, Manual, CurseForge compatible

## 🤝 Support

- **Issues**: Report bugs via [GitHub Issues](https://github.com/OsulivanAB/SpectrumLootTool/issues)
- **Guild Support**: Contact officers in Spectrum Federation
- **Documentation**: Check our [documentation site](https://osulivanab.github.io/SpectrumLootTool/)

---

<div align="center">

**Made with ❤️ for the Spectrum Federation guild**

[Documentation](https://osulivanab.github.io/SpectrumLootTool/) • [Releases](https://github.com/OsulivanAB/SpectrumLootTool/releases) • [Issues](https://github.com/OsulivanAB/SpectrumLootTool/issues)

</div>
