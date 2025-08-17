# Quick Start Guide

Get up and running with SpectrumLootTool in minutes! This guide covers the essential commands and features you'll use most often.

## 🚀 First Steps

### 1. Basic Commands

The most important commands to know:

<div class="command-example">
<code>/slh</code> - Toggle the main loot tracking interface
</div>

<div class="command-example">
<code>/slh status</code> - Check your addon status and permissions
</div>

<div class="command-example">
<code>/slh help</code> - Display all available commands
</div>

### 2. Check Your Setup

After installation, verify your configuration:

```
/slh status
```

You should see something like:

<div class="command-output">
<span class="timestamp">[2024-01-15 20:30:45]</span><br>
<span class="success">=== SLH Status ===</span><br>
<span class="success">Guild: Spectrum Federation</span><br>
<span class="success">Officer: true</span><br>
<span class="success">Version: 0.3.3</span><br>
<span class="success">WoW Version: 10.2</span>
</div>

!!! tip "Officer Status"
    If "Officer: false" but you should have permissions, try `/slh refresh` to update your status.

## 🎯 Core Features

### For All Users

#### View Roll Counts
Open the main interface to see current BiS roll counts:

```
/slh
```

The interface shows:
- **Player names** (colored by class)
- **Current roll counts** for each player
- **Real-time updates** as counts change

#### Reposition Interface
Unlock the frame to move it around your screen:

1. Go to **Options** → **AddOns** → **Spectrum Loot Helper**
2. Check **"Unlock Frame"**
3. Drag the interface to your preferred location
4. Uncheck **"Unlock Frame"** to lock position

### For Officers

#### Adjust Roll Counts
Officers see arrow buttons next to each player name:

- **↑ Up Arrow** - Increase player's roll count by 1
- **↓ Down Arrow** - Decrease player's roll count by 1

!!! warning "Officer Permissions"
    You must be rank 0-2 in Spectrum Federation guild to see officer controls.

#### Manual Adjustments
Use commands for precise adjustments:

```
/slh set PlayerName 5
```

```
/slh add PlayerName 2
```

## ⚙️ Essential Settings

Access settings via **Options** → **AddOns** → **Spectrum Loot Helper**:

### Outside Raid Usage
- **Default**: Disabled (raid groups only)
- **Enable**: Use addon when solo or in small groups
- **Use Case**: Personal tracking outside of raids

### Frame Position
- **Locked** (default): Interface position is fixed
- **Unlocked**: Drag interface anywhere on screen
- **Auto-save**: Position remembered between sessions

### Show All Players
- **Current Group** (default): Show only current raid members
- **All Known Players**: Display all players from database
- **Use Case**: View historical data for offline players

## 🔍 Monitoring & Debug

### View Recent Changes
See what's been happening with roll counts:

```
/slh debuglog show 10
```

### Enable Detailed Logging
For troubleshooting or bug reports:

```
/slh debuglog on
```

### Export Debug Information
When reporting issues:

```
/slh debuglog export
```

## 📋 Common Workflows

### Raid Night Setup

<div class="feature-grid">
<div class="feature-card">

**1. Pre-Raid Check**
```
/slh status
/slh refresh
```
Verify addon is working and permissions are current.

</div>
<div class="feature-card">

**2. Open Interface**
```
/slh
```
Display the loot tracking interface for your raid team.

</div>
<div class="feature-card">

**3. Position UI**
Unlock frame if needed and position interface where it won't block important UI elements.

</div>
</div>

### Officer Loot Distribution

<div class="install-steps">

<div class="install-step">
**Item Drops**

When a BiS item drops, check the interface to see who has the most/least rolls.
</div>

<div class="install-step">
**Award Loot**

Give the item to the appropriate player based on your guild's loot rules.
</div>

<div class="install-step">
**Update Counts**

Use the arrow buttons to decrease the winner's roll count by 1.
</div>

<div class="install-step">
**Verify Changes**

Confirm the change is reflected in the interface and synced to other players.
</div>

</div>

### Troubleshooting Quick Fixes

| Issue | Quick Fix |
|-------|-----------|
| Interface not showing | `/slh` then ensure you're in raid and out of combat |
| No officer buttons | `/slh refresh` to update guild permissions |
| Data seems wrong | `/slh debuglog export` and check for errors |
| Can't move interface | Enable "Unlock Frame" in addon settings |
| Missing players | Enable "Show All Players" or invite them to group |

## 🎓 Advanced Tips

### Keyboard Shortcuts
While there are no built-in hotkeys, you can create macros:

```
/run SlashCmdList.SLH("")
```

### Integration with Other Addons
SpectrumLootTool works alongside:
- **WeakAuras** - Can be positioned to complement your WA setup
- **Details/Skada** - No conflicts with damage meters
- **Guild management addons** - Uses standard WoW guild APIs

### Performance Optimization
For optimal performance:
- Keep debug logging off during normal use
- Use "Current Group" mode instead of "All Players" for large databases
- Consider enabling outside raid usage only when needed

## 📚 What's Next?

Now that you have the basics down:

- **[User Guide](user-guide/basic-usage.md)** - Comprehensive feature documentation
- **[Configuration](configuration.md)** - Detailed configuration options
- **[Support](support.md)** - Common issues and solutions

---

!!! success "You're Ready!"
    You now know the essential SpectrumLootTool features. Time to track some BiS rolls! 🎲
