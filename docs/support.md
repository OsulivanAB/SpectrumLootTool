# Support

Get help with SpectrumLootTool installation, configuration, and troubleshooting.

## 🆘 Getting Help

### Before You Ask

1. **Check the documentation** - Most questions are answered in our guides
2. **Search existing issues** - Someone might have already reported your problem
3. **Try basic troubleshooting** - Simple fixes solve most issues
4. **Gather information** - Have version numbers and error messages ready

## 📚 Documentation Resources

### Primary Documentation
- **[Installation Guide](installation.md)** - Getting the addon installed and running
- **[Quick Start](quick-start.md)** - Essential commands and features
- **[User Guide](user-guide/basic-usage.md)** - Comprehensive usage instructions
- **[Configuration](configuration.md)** - All settings and customization options
- **[Troubleshooting](user-guide/troubleshooting.md)** - Common issues and solutions

### Technical Documentation
- **[API Reference](api-reference.md)** - For developers and advanced users
- **[Database System](database.md)** - How data is stored and managed
- **[Debug System](debug.md)** - Logging and diagnostic tools

## 🐛 Bug Reports

### Where to Report

#### GitHub Issues (Preferred)
For technical bugs, feature requests, and development-related issues:

**[Create an Issue on GitHub](https://github.com/OsulivanAB/SpectrumLootTool/issues/new)**

#### Guild Discord
For quick questions and guild-specific issues:
- Contact **Spectrum Federation** officers on Garona-US
- Use guild Discord channels for immediate help

### What to Include

When reporting bugs, please provide:

#### Basic Information
- **SpectrumLootTool version** (`/slh status` for version info)
- **World of Warcraft version** (found in game client)
- **Operating system** (Windows, Mac, Linux)

#### Problem Description
- **What you expected to happen**
- **What actually happened**
- **Steps to reproduce** the issue
- **When the problem started** (after update, specific action, etc.)

#### Technical Details
- **Error messages** (exact text if possible)
- **Debug logs** (use `/slh debuglog export`)
- **Screenshots** (if UI-related)
- **Other addons** that might conflict

### Example Bug Report

```markdown
**Bug Description:**
Roll counts not syncing between officers during raid

**Expected Behavior:**
When an officer adjusts a player's roll count, it should immediately 
appear on all other players' interfaces

**Actual Behavior:**
Changes only appear locally, other players see old counts

**Steps to Reproduce:**
1. Start raid with multiple officers running SLH
2. Officer A adjusts Player X's count using arrow buttons
3. Officer B's interface still shows old count for Player X
4. `/slh refresh` doesn't fix the sync issue

**Environment:**
- SLH Version: 0.3.3
- WoW Version: 10.2.5
- Officers affected: 3/4 in raid
- Regular members: Seeing mixed data

**Debug Info:**
[Paste output from `/slh debuglog export`]
```

## 🔧 Self-Help Resources

### Diagnostic Commands

Use these commands to gather information:

<div class="command-example">
<code>/slh status</code> - Check addon status and configuration
</div>

<div class="command-example">
<code>/slh debuglog export</code> - Export technical diagnostic information
</div>

<div class="command-example">
<code>/slh config validate</code> - Check for configuration problems
</div>

### Quick Fixes

#### Addon Not Loading
1. Check AddOns menu at character select
2. Ensure folder is named `SpectrumLootTool`
3. Verify all files are present
4. Try `/reload` in-game

#### Interface Issues
1. Enable "Outside Raid" if not in a raid group
2. Check if frame is positioned off-screen
3. Try `/slh reset ui` to reset interface
4. Disable conflicting addons temporarily

#### Permission Problems
1. Verify guild membership in Spectrum Federation
2. Check your guild rank (must be 0-2 for officer features)
3. Use `/slh refresh` to update permissions
4. Contact guild officers if rank is incorrect

#### Data Synchronization
1. Use `/slh refresh` to force sync
2. Check network connectivity
3. Verify other players are running compatible versions
4. Try `/slh reset current` if data seems corrupted

## 💬 Community Support

### Guild Resources

#### Spectrum Federation Discord
- **#addon-support** - Technical help and questions
- **#officer-chat** - Officer-specific features and permissions
- **#general** - General guild discussion

#### Guild Officers
Current officers who can help with permissions and guild-specific issues:
- Contact any rank 0-2 member for assistance
- Officers can verify your rank and troubleshoot permissions

### External Communities

#### WoW Addon Communities
- **r/WowAddons** - Reddit community for addon discussion
- **Addon development forums** - For technical development questions
- **WowInterface** - General addon support community

#### Developer Resources
- **GitHub Discussions** - Feature requests and development chat
- **Addon development Discord servers** - Technical programming help

## 📋 Frequently Asked Questions

### Installation & Setup

**Q: Can I use SpectrumLootTool in other guilds?**
A: The addon is designed specifically for Spectrum Federation and requires guild membership for full functionality.

**Q: Do I need to be an officer to use the addon?**
A: No, all guild members can view roll counts. Officer rank (0-2) is only required for adjustment controls.

**Q: Why don't I see the interface in dungeons?**
A: By default, the addon only works in raid groups. Enable "Outside Raid" in settings to use it elsewhere.

### Functionality

**Q: How do roll counts work?**
A: Lower numbers = higher loot priority. Counts increase when you receive BiS loot and can be adjusted by officers.

**Q: Can I see historical data for offline players?**
A: Yes, enable "Show All Players" in settings to see data for all guild members regardless of online status.

**Q: What happens if I leave and rejoin the guild?**
A: Your roll count data is preserved as long as you rejoin with the same character name.

### Technical Issues

**Q: The addon is causing memory issues, what should I do?**
A: Enable "Current Group Only" mode, disable debug logging, and consider using `/slh reset old` to clean up old data.

**Q: How do I backup my roll count data?**
A: Data is automatically saved to SavedVariables. You can export it with `/slh debuglog export` for backup purposes.

## 🚀 Feature Requests

### How to Request Features

1. **Check existing requests** on GitHub Issues
2. **Discuss with guild members** to gauge interest
3. **Create detailed feature request** with use cases
4. **Consider contributing** if you have development skills

### Current Roadmap

See our [Changelog](changelog.md) for planned features and development milestones.

### Popular Requests

Some commonly requested features being considered:
- Integration with loot council addons
- Advanced analytics and reporting
- Mobile companion app
- Cross-guild support

## 📞 Direct Contact

### Primary Developer
- **Email**: Anthony.r.Bahl@gmail.com
- **GitHub**: @OsulivanAB
- **In-Game**: Osulivan on Garona-US

### Response Times
- **Critical bugs**: 24-48 hours
- **General questions**: 2-7 days
- **Feature requests**: Varies based on complexity

### Best Contact Method
1. **GitHub Issues** - For bugs and feature requests
2. **Guild Discord** - For quick questions and guild-specific issues
3. **Email** - For private or sensitive issues

---

!!! info "Community First"
    Our community is friendly and helpful! Don't hesitate to ask questions - chances are other players have experienced the same issues and can offer quick solutions.
