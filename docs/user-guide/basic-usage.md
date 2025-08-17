# Basic Usage

Learn how to use SpectrumLootTool effectively for raid loot tracking and distribution.

## 🎯 Getting Started

SpectrumLootTool is designed to help Spectrum Federation track and distribute loot fairly during raids. The addon displays roll counts for each player and provides tools for officers to manage the loot distribution process.

## 🖥️ Main Interface

### Opening the Interface

Use any of these methods to open the main interface:

<div class="command-example">
<code>/slh</code> - Toggle interface visibility
</div>

<div class="command-example">
<code>/slh show</code> - Force show interface
</div>

<div class="command-example">
<code>/slh hide</code> - Force hide interface
</div>

### Interface Layout

The main interface displays:

1. **Player Names** - Listed alphabetically, colored by class
2. **Roll Counts** - Current BiS roll count for each player
3. **Officer Controls** - Arrow buttons (officers only)
4. **Status Indicators** - Online/offline status

## 📊 Understanding Roll Counts

### What Are Roll Counts?

Roll counts represent how many "BiS" (Best in Slot) items a player has received. The system helps ensure fair loot distribution by tracking who has received the most gear.

### How Counts Work

- **New players start at 0** rolls
- **Receiving BiS loot increases** count by 1
- **Officers can adjust** counts manually
- **Lower counts = higher loot priority**

### Roll Count Display

```
PlayerName [5] ↑↓    # Officer view with controls
PlayerName [5]       # Regular member view
PlayerName [5] 📴    # Offline player
```

## 👥 For Regular Members

### Viewing Your Status

Check your current roll count and standing:

<div class="command-example">
<code>/slh status</code> - Show your addon status and roll count
</div>

<div class="command-example">
<code>/slh me</code> - Show only your information
</div>

### Understanding Your Position

- **Lower numbers** = higher loot priority
- **Same numbers** = equal priority (use traditional rolling)
- **Offline players** still count in distribution decisions

### During Raids

1. **Keep interface open** to see current standings
2. **Check priorities** when loot drops
3. **Roll normally** if priorities are tied
4. **Be patient** while officers make adjustments

## 🛡️ For Officers

!!! warning "Officer Permissions Required"
    You must be rank 0-2 in Spectrum Federation to access officer controls.

### Officer Interface

Officers see additional controls:

- **↑ Up Arrow** - Increase player's roll count by 1
- **↓ Down Arrow** - Decrease player's roll count by 1
- **Enhanced status** information in commands

### Managing Roll Counts

#### Using Arrow Buttons

1. **Click ↑** next to a player's name to increase their count
2. **Click ↓** next to a player's name to decrease their count
3. **Changes sync immediately** to all addon users

#### Using Commands

<div class="command-example">
<code>/slh set PlayerName 3</code> - Set player to exactly 3 rolls
</div>

<div class="command-example">
<code>/slh add PlayerName 2</code> - Add 2 to player's current count
</div>

<div class="command-example">
<code>/slh subtract PlayerName 1</code> - Remove 1 from player's count
</div>

### Loot Distribution Process

<div class="install-steps">

<div class="install-step">
**Loot Drops**

When a BiS item drops, check the interface to see current roll counts and priorities.
</div>

<div class="install-step">
**Determine Eligibility**

Consider factors like:
- Current roll counts (lower = higher priority)
- Item upgrade significance
- Player attendance and contribution
- Guild loot rules
</div>

<div class="install-step">
**Award Loot**

Give the item to the chosen player using standard loot distribution methods.
</div>

<div class="install-step">
**Update Counts**

Use the ↓ arrow button or command to decrease the winner's roll count by 1.
</div>

<div class="install-step">
**Verify Sync**

Confirm the change appears on all players' interfaces and is properly synchronized.
</div>

</div>

## 🔧 Common Tasks

### Repositioning the Interface

1. Go to **Options** → **AddOns** → **Spectrum Loot Helper**
2. Check **"Unlock Frame"**
3. **Drag the interface** to your preferred location
4. **Uncheck "Unlock Frame"** to lock the position

### Handling Offline Players

- **Offline players remain visible** with a 📴 indicator
- **Their counts still matter** for loot distribution
- **Officers can adjust** offline player counts
- **Enable "Show All Players"** to see full guild roster

### Dealing with New Players

- **New guild members start at 0** rolls automatically
- **Officers can set starting counts** if needed for fairness
- **Use `/slh set PlayerName X`** to establish baseline

### Resolving Disputes

If there are questions about roll counts:

1. **Check the debug log** for recent changes
2. **Use `/slh debuglog show 10`** to see last 10 events
3. **Export logs** with `/slh debuglog export` if needed
4. **Reset individual players** if data corruption is suspected

## 📱 Interface Customization

### Display Options

#### Show/Hide Features

Access via **Options** → **AddOns** → **Spectrum Loot Helper**:

- **Show Outside Raid** - Use addon when not in a raid group
- **Show Offline Players** - Include offline guild members
- **Show All Players** - Display entire database vs. current group only
- **Auto-Hide in Combat** - Hide interface during encounters

#### Visual Customization

- **UI Scale** - Adjust interface size (50% - 200%)
- **Transparency** - Make interface semi-transparent
- **Class Colors** - Toggle class-colored player names

### Sorting and Filtering

#### Sort Methods

- **Alphabetical** (default) - A-Z by player name
- **Roll Count** - Lowest to highest counts
- **Reverse Roll Count** - Highest to lowest counts

#### Filtering Options

- **Current Group Only** - Show only current raid members
- **Guild Members** - Show all guild members regardless of online status
- **Hide Zero Counts** - Hide players with no rolls

## 🎮 Advanced Usage

### Macro Integration

Create macros for quick access:

```lua
-- Toggle interface
/run SLH:Toggle()

-- Quick status check
/run SLH:PrintStatus()

-- Officer quick adjust (replace PlayerName and amount)
/run if SLH:IsOfficer() then SLH:AdjustPlayer("PlayerName", -1) end
```

### Keyboard Shortcuts

While SLH doesn't have built-in hotkeys, you can:

1. **Assign macros** to action bar slots
2. **Use keybind addons** to assign shortcuts
3. **Create custom hotkeys** through WoW's interface

### Integration with Other Addons

SpectrumLootTool works well with:

- **Loot council addons** - Can inform decision making
- **Damage meters** - No conflicts, complementary data
- **Guild management tools** - Uses standard WoW APIs
- **WeakAuras** - Can trigger on loot events

## 🚨 Troubleshooting

### Common Issues

#### Interface Not Showing

**Symptoms**: Commands work but no UI visible

**Solutions**:
- Ensure you're in a raid group OR enable "Outside Raid"
- Exit combat before opening interface
- Check if frame is positioned off-screen
- Try `/slh reset ui` to reset interface position

#### Data Inconsistencies

**Symptoms**: Roll counts don't match between players

**Solutions**:
- Use `/slh refresh` to force data sync
- Check guild permissions with `/slh status`
- Export debug logs for analysis
- Consider data reset for affected players

#### Performance Issues

**Symptoms**: Interface is slow or unresponsive

**Solutions**:
- Reduce UI scale if very large
- Enable "Current Group Only" mode
- Disable debug logging if enabled
- Consider addon conflicts with `/reload`

### Getting Help

1. **Check documentation** - Most issues are covered here
2. **Use debug commands** - `/slh debuglog export` for technical issues
3. **Contact officers** - Guild leadership can help with permissions
4. **Report bugs** - Use GitHub issues for technical problems

---

!!! success "Ready to Raid!"
    You now understand the basics of SpectrumLootTool. Practice with the interface outside of raids to get comfortable with the controls before your next raid night!
