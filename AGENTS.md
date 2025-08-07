## Project Goal

You are assisting with a World of Warcraft addon for the Spectrum Federation Guild. The addon must:
- Track how many "Best-in-Slot" rolls each member has available.
- Be available to all Spectrum Federation members.
- Allow only officers to increase or decrease Best-in-Slot rolls for any member.
- Data must sync in real time across the raid group efficiently, minimizing game impact
- Update data for members who miss a raid when they return, using data from other raid group members.
- Categorize data by Major.Minor game versions. When a new minor version is released, reset all roll counts to 0, but retain previous version data in the log.

## WoWUP Compatibility

- Ensure the addon can be imported and updated in WoWUP by providing the GitHub repository link.
- The repository root must contain the `.toc` file and all addon Lua files in a single folder (e.g., `SpectrumLootHelper/`).
- Do not create extra nested folders or files outside the addon directory that are not required for the addon to function in-game.
- Keep the `.toc` file up-to-date with the correct interface version and all Lua file references.
- Test importing the addon into WoWUP using the repo link to confirm it works without manual steps.
- Document the WoWUP installation process in the README for guild members.

## Addon Code Organization Best Practices

- Organize code into logical Lua files by feature or responsibility (e.g., core logic, UI, data sync, officer controls).
- Use a main `.toc` file to declare all Lua files and metadata for the addon.
- Minimize global variables; use local scopes and tables to avoid polluting the global namespace.
- Group related functions and data in tables/modules (e.g., `SpectrumLootHelper.Sync`, `SpectrumLootHelper.UI`).
- Separate UI code from core logic where possible.
- Use clear, descriptive naming for all functions, variables, and files.
- Add comments and documentation for complex logic, especially sync and versioning code.
- Store persistent data in the SavedVariables table, using versioned keys if needed.
- Follow WoW addon community conventions for folder and file structure.
- 
## Documentation and Changelog Maintenance
- Always keep the following files and folders up-to-date as appropriate:
  - README.md (main addon readme)
  - mkdocs.yml (documentation navigation/config)
  - CHANGELOG.md (changelog for all user-facing changes)
  - /docs/* (all documentation pages)

## UI Requirements

- Minimal UI that resembles a weak arua and can be placed anywhere on the screen.
  - Different Player name on each row
    - Limited to players currently in the raid group
    - Player names colored by class
  - If the person is an officer in the Spectrum Federation (Garona-US) Guild:
    - Up and down arrow buttons which move the players Best In Slot Roll count up or down
- Settings
  - Customizability options, such as show just me or show everybody
  - Toggle Button to show all data for the current Raid Tier
    - Current Raid Tier = Data from the same major and minor patch as the current game
  - Re-size the scale of the main UI to be smaller or larger
  - A way to view the log of changes historically broken down by game version (major.minor)
 
## Functionality

- Guild Rank cuttoff for who is an officer in the Spectrum Federation (Garona-US) guild should be able to be configured using a variable in the code and then re-used wherever it is needed.
- Internal Database which keeps a log of modifications to each players Best-in-Slot roll count
  - Data Needed for each log entry:
    - Timestamp (Server Time)
    - Player Name
    - Which Officer made the change
    - The new value for that player
  - Database should sync between all members in the Raid group
    - Things that can trigger a sync:
      - A change is made to someone's point values
      - A new person joins the raid group
  - Database values can only be added by players who are an officer in the Spectrum Federation (Garona-US) guild.
  - Database values can only be modified by players who are an officer in the Spectrum Federation (Garona-US) guild.
- Addon should turn off as much functionality as possible to reduce game impact (while still being on enough to turn itself back on) whenever:
  - The player is not in a raid zone and does not have the settings page open
  - The user is in combat
- The code should have tests and linting in place that validate that the code is working as it should.


## Best Practices

- Follow the most up-to-date best practices for World of Warcraft Addon Development


## When in Doubt

- If you are unsure about code organization, documentation, or WoWUP compatibility, ask for clarification or refer to the latest WoW addon best practices.
