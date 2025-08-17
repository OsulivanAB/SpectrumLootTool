# Debug System

SpectrumLootTool includes a sophisticated debug system designed to help users troubleshoot issues, monitor performance, and provide comprehensive bug reports. The debug system is mandatory for all addon functions and provides detailed logging capabilities.

## Overview

The Debug module provides:
- **Multi-level Logging**: Support for INFO, WARN, ERROR, and DEBUG log levels
- **Session Management**: Automatic session tracking with timing and statistics
- **Performance Monitoring**: Real-time performance metrics and optimization tools
- **Memory Management**: Intelligent buffer management with automatic cleanup
- **Export Functionality**: Complete bug report generation for issue reporting
- **Integration Testing**: Comprehensive test suite for system validation

## Getting Started

### Enabling Debug Logging

Debug logging is disabled by default to minimize performance impact. Enable it when you need detailed information:

```
/slh debuglog on
```

Or toggle it on/off:
```
/slh debuglog toggle
```

To disable debug logging:
```
/slh debuglog off
```

### Viewing Debug Logs

Display recent debug logs in chat:
```
/slh debuglog show
```

Show a specific number of entries:
```
/slh debuglog show 25
```

### Managing Debug Data

Clear all current debug logs:
```
/slh debuglog clear
```

View debug system statistics:
```
/slh debuglog stats
```

## Command Reference

### Basic Commands

| Command | Description |
|---------|-------------|
| `/slh debuglog on` | Enable debug logging |
| `/slh debuglog off` | Disable debug logging |
| `/slh debuglog toggle` | Toggle debug logging state |
| `/slh debuglog show [count]` | Display recent logs (default: 10 entries) |
| `/slh debuglog clear` | Clear all current session logs |
| `/slh debuglog stats` | Show debug system statistics |
| `/slh debuglog export` | Generate bug report export |

### Advanced Commands

#### Integration Testing
Test core addon functionality:
```
/slh debuglog test core      # Test core functionality
/slh debuglog test ui        # Test user interface
/slh debuglog test workflow  # Test user workflows
/slh debuglog test perf      # Test performance
/slh debuglog test all       # Run all tests
```

#### Performance Optimization
Monitor and optimize performance:
```
/slh debuglog optimize run              # Apply optimizations
/slh debuglog optimize memory           # Manage memory usage
/slh debuglog optimize monitor [time]   # Monitor for specified seconds
```

#### System Validation
Validate system integrity:
```
/slh debuglog verify        # Run completeness verification
/slh debuglog errors        # Test error handling
/slh debuglog wow          # Check WoW compatibility
/slh debuglog performance  # Assess performance impact
```

## Debug Levels

### INFO Level
- **Purpose**: General information about addon operations
- **Examples**: Function entry/exit, successful operations, state changes
- **Usage**: Default level for tracking normal addon behavior

### WARN Level  
- **Purpose**: Warnings that don't halt execution but indicate potential issues
- **Examples**: Deprecated API usage, recoverable errors, unusual conditions
- **Usage**: Identifies areas that may need attention

### ERROR Level
- **Purpose**: Errors that affect functionality but don't crash the addon
- **Examples**: Failed operations, invalid data, API errors
- **Usage**: Critical for debugging functional issues

### DEBUG Level
- **Purpose**: Detailed debugging information (most verbose)
- **Examples**: Variable states, detailed execution paths, performance metrics
- **Usage**: Deep troubleshooting and development debugging

## Performance Considerations

### Memory Management
The debug system automatically manages memory usage:
- **Buffer Limit**: Maximum 1,000 log entries in memory
- **Automatic Cleanup**: Oldest entries are removed when limit is reached
- **Memory Monitoring**: Real-time memory usage tracking and reporting

### Performance Impact
- **When Disabled**: Virtually no performance impact (fast early returns)
- **When Enabled**: Minimal impact during normal operation
- **High-Frequency Logging**: Monitor performance during intensive operations

### Optimization Features
- **Intelligent Filtering**: Log only relevant information based on current needs
- **Session-Based**: Logs are cleared between game sessions
- **Efficient Storage**: Optimized data structures for minimal memory footprint

## Bug Reporting

### Generating Bug Reports

When reporting issues, use the export function to generate comprehensive reports:

```
/slh debuglog export
```

This creates a detailed report including:
- **System Information**: WoW version, addon version, player details
- **Session Data**: Session duration, group status, debug statistics
- **Recent Logs**: Last 50 debug entries with full context
- **Performance Metrics**: Memory usage, logging statistics

### What to Include

When submitting bug reports, always include:
1. **Full debug export** (generated with `/slh debuglog export`)
2. **Steps to reproduce** the issue
3. **Expected vs actual behavior**
4. **When the issue occurs** (specific situations, triggers)
5. **Any error messages** seen in-game

### Privacy and Security

The debug export function:
- **Anonymizes sensitive data** where possible
- **Includes only addon-related information**
- **Does not capture chat content or personal data**
- **Focuses on technical debugging information**

## Integration with Development

### For Developers

Every function in SpectrumLootTool includes mandatory debug logging:

```lua
function SLH:ExampleFunction(param)
    self.Debug:LogDebug("Core", "Function entry", { param = param })
    -- function logic
    if errorCondition then
        self.Debug:LogError("Core", "Error occurred", { details = details })
    end
    self.Debug:LogInfo("Core", "Completed", { result = result })
end
```

### Component Names
Debug logs use component names matching file names:
- **Core**: Main logic and initialization
- **UI**: User interface and events  
- **Database**: Data management and storage
- **Log**: Roll tracking functionality
- **Debug**: Debug system itself

### Best Practices
- **Always include context data** in the third parameter
- **Use appropriate log levels** for different types of information
- **Test with debug verification**: `/slh debuglog verify`
- **Monitor performance impact**: `/slh debuglog performance`

## Troubleshooting

### Common Issues

**Debug logs not appearing:**
- Ensure debug logging is enabled: `/slh debuglog on`
- Check if logs were cleared: `/slh debuglog stats`
- Verify addon is functioning: `/slh status`

**Performance concerns:**
- Check current impact: `/slh debuglog performance`
- Monitor memory usage: `/slh debuglog stats`
- Run optimization: `/slh debuglog optimize run`

**Export not working:**
- Ensure debug logging has been enabled and used
- Check for recent log entries: `/slh debuglog show`
- Verify saved variables are functioning

### Getting Help

1. **Enable debug logging** and reproduce the issue
2. **Generate an export**: `/slh debuglog export`
3. **Check integration tests**: `/slh debuglog test all`
4. **Submit the export** along with issue details

## Technical Details

### Storage Mechanism
- **Memory Buffer**: In-memory storage for current session (max 1,000 entries)
- **Saved Variables**: Persistent storage through WoW's SavedVariables system
- **Session Management**: Automatic cleanup and rotation between game sessions

### Performance Metrics
- **Memory Usage**: Real-time tracking of debug system memory consumption
- **Logging Performance**: Metrics on logging operation efficiency
- **Buffer Utilization**: Monitoring of memory buffer usage patterns

### Compatibility
- **WoW Versions**: Full compatibility with current retail WoW
- **Addon Integration**: Seamless integration with all SpectrumLootTool modules
- **Performance Testing**: Comprehensive testing for raid environment usage

---

*The debug system is a core component of SpectrumLootTool's reliability and maintainability. When in doubt, enable debug logging and generate an export for comprehensive troubleshooting information.*
