# Installation Guide

Get SpectrumLootTool up and running in World of Warcraft quickly with our comprehensive installation guide.

## 🎯 Prerequisites

Before installing SpectrumLootTool, ensure you have:

- **World of Warcraft Retail** (Current Patch)
- **Spectrum Federation Guild Membership** (Garona-US server)
- **Officer Rank** (for full functionality)

!!! info "Guild Requirements"
    While anyone can install and use the basic features, full officer controls require rank 0-2 in the Spectrum Federation guild.

## 🚀 Installation Methods

=== "WowUp (Recommended)"

    <div class="install-steps">
    
    <div class="install-step">
    **Download WowUp**
    
    Visit [wowup.io](https://wowup.io/) and download the WowUp client for your operating system.
    </div>
    
    <div class="install-step">
    **Open WowUp**
    
    Launch WowUp and ensure it has detected your World of Warcraft installation.
    </div>
    
    <div class="install-step">
    **Install from URL**
    
    Navigate to **Addons** → **Install from URL** and enter:
    ```
    https://github.com/OsulivanAB/SpectrumLootTool
    ```
    </div>
    
    <div class="install-step">
    **Install & Update**
    
    Click **Install** and WowUp will automatically download and install the addon. Future updates will be handled automatically!
    </div>
    
    </div>

=== "Manual Installation"

    <div class="install-steps">
    
    <div class="install-step">
    **Download Release**
    
    Visit our [Releases page](https://github.com/OsulivanAB/SpectrumLootTool/releases) and download the latest ZIP file.
    </div>
    
    <div class="install-step">
    **Locate AddOns Folder**
    
    Find your WoW AddOns directory:
    
    - **Windows**: `World of Warcraft\_retail_\Interface\AddOns\`
    - **Mac**: `Applications/World of Warcraft/_retail_/Interface/AddOns/`
    </div>
    
    <div class="install-step">
    **Extract Files**
    
    Extract the downloaded ZIP file directly into your AddOns folder. You should see a new `SpectrumLootTool` folder.
    </div>
    
    <div class="install-step">
    **Restart WoW**
    
    Restart World of Warcraft or use `/reload` in-game to load the addon.
    </div>
    
    </div>

=== "Development Version"

    For developers or testing latest features:
    
    ```bash
    git clone https://github.com/OsulivanAB/SpectrumLootTool.git
    cd SpectrumLootTool
    # Copy files to your AddOns directory
    ```

## ✅ Verification

After installation, verify everything is working:

### 1. Check Addon Load
Open the AddOns menu at character select and ensure **Spectrum Loot Helper** is listed and enabled.

### 2. Test Basic Commands
Log into your character and try these commands:

<div class="command-example">
<code>/slh status</code> - Check addon status and configuration
</div>

<div class="command-example">
<code>/slh help</code> - Display available commands
</div>

<div class="command-example">
<code>/slh</code> - Toggle the main interface
</div>

### 3. Expected Output
You should see output similar to:

```
=== SLH Status ===
Guild: Spectrum Federation
Officer: true/false
Version: 0.3.3
WoW Version: 10.2
```

## 🔧 Configuration

### Initial Setup

1. **Join/Create a Raid Group** - The addon is designed for raid environments
2. **Access Settings** - Go to **Options** → **AddOns** → **Spectrum Loot Helper**
3. **Configure Preferences**:
   - Enable "Outside Raid" if you want to use it solo
   - Unlock frame to reposition the interface
   - Configure debug logging if needed

### Officer Permissions

If you're an officer (rank 0-2) in Spectrum Federation, you'll see additional controls:

- **Arrow buttons** next to player names for adjusting roll counts
- **Enhanced status information** in `/slh status`
- **Access to officer-only commands**

## 🛠️ Troubleshooting

### Common Issues

!!! failure "Addon Not Loading"
    **Symptoms**: Addon doesn't appear in-game
    
    **Solutions**:
    - Verify files are in correct AddOns folder
    - Check character select AddOns menu
    - Ensure folder is named `SpectrumLootTool`
    - Try `/reload` in-game

!!! warning "No Interface Visible"
    **Symptoms**: Commands work but no UI appears
    
    **Solutions**:
    - Ensure you're in a raid group (or enable "Outside Raid")
    - Exit combat before opening interface
    - Try `/slh` command to toggle visibility

!!! info "No Officer Controls"
    **Symptoms**: Missing arrow buttons and officer features
    
    **Solutions**:
    - Verify guild membership in Spectrum Federation
    - Check rank (must be 0-2)
    - Use `/slh refresh` to update officer status

### Debug Information

For technical issues, enable debug logging:

```
/slh debuglog on
```

Then reproduce the issue and export logs:

```
/slh debuglog export
```

Share the exported information when reporting bugs.

## 🔄 Updating

### WowUp Users
Updates are handled automatically! WowUp will notify you when new versions are available.

### Manual Users
1. Check [Releases](https://github.com/OsulivanAB/SpectrumLootTool/releases) for new versions
2. Download and extract new version
3. Replace existing files in AddOns folder
4. Use `/reload` in-game

## 🎮 Next Steps

Once installed, check out these guides:

- [Quick Start Guide](quick-start.md) - Get up and running quickly
- [User Guide](user-guide/basic-usage.md) - Comprehensive feature overview
- [Configuration](configuration.md) - Detailed configuration options

---

!!! success "Installation Complete!"
    Welcome to SpectrumLootTool! Join your raid group and start tracking those BiS rolls! 🎲
