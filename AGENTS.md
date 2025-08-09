# SpectrumLootHelper Addon Specification

## Project Goal

- Track how many "Best-in-Slot" rolls each member has available.
- Be available to all Spectrum Federation members.
- Allow only officers to increase or decrease Best-in-Slot rolls for any member.
- Data must sync in real time across the raid group efficiently, minimizing game impact.
- Update data for members who miss a raid when they return, using data from other raid group members.
- Categorize data by major.minor game versions. When a new minor version is released, reset all roll counts to 0, but retain previous version data in the log.

## WoWUP Compatibility

- Ensure the addon can be imported and updated in WoWUP by providing the GitHub repository link.
- The repository root must contain the `.toc` file and all addon Lua files in a single folder (e.g., `SpectrumLootHelper/`).
- Do not create extra nested folders or files outside the addon directory that are not required for the addon to function in-game.
- Keep the `.toc` file up to date with the correct interface version and all Lua file references.
- Test importing the addon into WoWUP using the repo link to confirm it works without manual steps.
- Document the WoWUP installation process in the README for guild members.

## Addon Code Organization Best Practices

- Organize code into logical Lua files by feature or responsibility (e.g., core logic, UI, data sync, officer controls).
- Use a main `.toc` file to declare all Lua files and metadata for the addon.
- Minimize global variables; use local scopes and tables to avoid polluting the global namespace.
- Group related functions and data into tables/modules (e.g., `SpectrumLootHelper.Sync`, `SpectrumLootHelper.UI`).
- Separate UI code from core logic where possible.
- Use clear, descriptive naming for all functions, variables, and files.
- Add comments and documentation for complex logic, especially sync and versioning code.
- Store persistent data in the SavedVariables table, using versioned keys if needed.
- Follow World of Warcraft addon community conventions for folder and file structure.

## Documentation and Changelog Maintenance

- Always keep the following files and folders up to date as appropriate:
  - `README.md` (main addon readme)
  - `mkdocs.yml` (documentation navigation/config)
  - `CHANGELOG.md` (changelog for all user-facing changes)
  - `docs/` (all documentation pages)

## UI Requirements

- Minimal UI that resembles a WeakAura and can be placed anywhere on the screen.
  - Different player name on each row:
    - Limited to players currently in the raid group
    - Player names colored by class
  - If the **current user** is an officer in the Spectrum Federation (Garona-US) guild:
    - Up and down arrow buttons to adjust a player’s Best-in-Slot roll count up or down
- **Settings:**
  - Option to show just the current user or show everybody
  - Toggle button to show all data for the current raid tier  
    - *Current raid tier* = data from the same major.minor patch as the current game version  
  - Resize the scale of the main UI (smaller or larger)
  - View a log of changes (historical records broken down by game version, major.minor)

## Functionality

- Guild rank cutoff for who is an officer should be configurable via a variable in the code and reused wherever needed.
- Internal database that keeps a log of modifications to each player’s Best-in-Slot roll count:  
  - Data needed for each log entry:  
    - Timestamp (server time)  
    - Player name  
    - Officer who made the change  
    - New value for that player  
  - The database should sync between all members in the raid group.  
    - Sync triggers:  
      - A change is made to someone’s point values  
      - A new person joins the raid group  
  - Database values can only be added or modified by officers in the Spectrum Federation (Garona-US) guild.
- Addon should disable as much functionality as possible (while still able to reactivate) whenever:  
  - The player is not in a raid zone and does not have the settings page open  
  - The user is in combat
- Code should have tests and linting in place to validate correct functionality.

## Best Practices

- Follow the most up-to-date best practices for World of Warcraft addon development.
- Enforce that roll counts cannot be negative (no cap on maximum).

## When in Doubt

- If unsure about code organization, documentation, or WoWUP compatibility, refer to the latest WoW addon best practices.
