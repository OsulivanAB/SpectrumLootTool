# Changelog

All notable changes to SpectrumLootTool will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Modern Material Design documentation theme
- Enhanced MkDocs configuration with advanced plugins
- Interactive documentation with copy buttons and animations
- WoW-themed CSS styling for authentic look and feel
- Comprehensive API reference documentation
- Installation guide with multiple installation methods
- Quick start guide for new users
- Configuration documentation with all settings explained

### Changed
- Complete redesign of documentation site
- Improved navigation structure with tabbed interface
- Enhanced CI/CD workflows with better MkDocs support
- Updated development container with all required dependencies

### Technical
- Added Material theme with light/dark mode support
- Integrated social cards for better sharing
- Added search functionality with improved indexing
- Implemented git integration for edit history
- Added syntax highlighting optimized for Lua code

## [0.3.3] - 2024-12-XX

### Added
- Enhanced debug logging system with export functionality
- Officer status refresh command (`/slh refresh`)
- Version validation between TOC and Core.lua files
- Comprehensive CI/CD pipeline with automated testing

### Fixed
- Officer permissions not updating immediately after rank changes
- Interface positioning issues on different screen resolutions
- Memory leak in long-running raid sessions

### Changed
- Improved error handling and user feedback
- Better integration with WoW's guild system APIs
- More reliable synchronization between addon users

## [0.3.2] - 2024-11-XX

### Added
- Support for new WoW classes (Evoker)
- Enhanced class color support
- Improved officer control buttons with better visual feedback

### Fixed
- Compatibility issues with recent WoW patches
- UI scaling problems on high-resolution displays
- Synchronization delays in large raid groups

### Security
- Enhanced guild rank verification
- Better protection against unauthorized roll modifications

## [0.3.1] - 2024-10-XX

### Added
- Configurable frame positioning and scaling
- Outside raid usage option for testing and small groups
- Enhanced status command with more detailed information

### Fixed
- Frame positioning persistence between sessions
- Combat state detection for auto-hide functionality
- Player data cleanup on guild leave/join

### Changed
- Improved UI responsiveness during combat
- Better handling of offline players in display
- More intuitive officer control layout

## [0.3.0] - 2024-09-XX

### Added
- Complete UI overhaul with modern WoW-style interface
- Officer controls with arrow buttons for easy roll adjustments
- Real-time synchronization between addon users
- Comprehensive settings panel integration
- Debug logging system for troubleshooting

### Changed
- **BREAKING**: Command structure updated for better organization
- Database schema improvements for better performance
- Enhanced guild integration with proper rank checking

### Removed
- Legacy text-based interface (replaced with graphical UI)
- Deprecated command aliases (use `/slh help` for current commands)

### Migration
- Existing data will be automatically migrated to new format
- Old command aliases will show deprecation warnings

## [0.2.5] - 2024-08-XX

### Added
- Automatic guild detection for Spectrum Federation
- Basic officer permission system
- Player class detection and color coding

### Fixed
- Data persistence issues across game sessions
- Synchronization problems in cross-realm groups
- Memory usage optimization for large guilds

## [0.2.0] - 2024-07-XX

### Added
- Core loot tracking functionality
- Basic roll count management
- Simple command interface (`/slh` commands)
- Guild integration for Spectrum Federation

### Changed
- Moved from beta to stable release
- Improved data storage efficiency
- Enhanced error handling

## [0.1.0] - 2024-06-XX

### Added
- Initial release for Spectrum Federation guild
- Basic player tracking
- Simple roll count system
- Minimal command interface

---

## Release Notes

### Version Compatibility

| SLH Version | WoW Version | Status |
|-------------|-------------|--------|
| 0.3.3+ | 10.2.x (Dragonflight) | ✅ Supported |
| 0.3.0-0.3.2 | 10.1.x-10.2.x | ✅ Supported |
| 0.2.x | 10.0.x-10.1.x | ⚠️ Legacy Support |
| 0.1.x | 10.0.x | ❌ Deprecated |

### Upgrade Guide

#### From 0.2.x to 0.3.x
1. **Backup your data**: Export current roll counts before upgrading
2. **Install new version**: Follow standard installation procedures
3. **Update commands**: Review new command syntax with `/slh help`
4. **Configure UI**: Access new settings via Options → AddOns → Spectrum Loot Helper
5. **Verify permissions**: Use `/slh status` to confirm officer status

#### From 0.1.x to 0.3.x
- **Full migration required**: 0.1.x data format is not compatible
- **Manual data entry**: Roll counts will need to be re-entered
- **Command retraining**: All commands have changed

### Development Milestones

#### Next Release (0.4.0)
- [ ] Integration with popular loot council addons
- [ ] Advanced analytics and reporting
- [ ] Custom loot distribution algorithms
- [ ] Mobile companion app integration
- [ ] Multi-guild support

#### Future Releases
- [ ] Machine learning for loot prediction
- [ ] Integration with guild management tools
- [ ] Advanced visualization and charts
- [ ] Cross-server guild support

### Known Issues

#### Current Issues (0.3.3)
- Minor display glitches on ultra-wide monitors (fix in progress)
- Occasional sync delays in very large raids (40+ players)
- Settings UI may require `/reload` to fully apply changes

#### Workarounds
- **Ultra-wide displays**: Manually adjust UI scale to 80-90%
- **Sync delays**: Use `/slh refresh` to force synchronization
- **Settings not applying**: Use `/reload` after making changes

### Contributing

See our [Contributing Guide](development/contributing.md) for information about:
- Bug reports and feature requests
- Development setup and guidelines
- Code contribution process
- Testing procedures

### Support

- **GitHub Issues**: [Report bugs and request features](https://github.com/OsulivanAB/SpectrumLootTool/issues)
- **Guild Discord**: Contact officers in Spectrum Federation
- **Documentation**: [Full documentation site](https://osulivanab.github.io/SpectrumLootTool/)

---

!!! info "Stay Updated"
    Subscribe to releases on GitHub to get notified of new versions and important updates.
