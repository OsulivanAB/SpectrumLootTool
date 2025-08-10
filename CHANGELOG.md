# Changelog

## 0.1.4 - Conditional frame visibility
- Main UI frame hides only during combat or when outside raids without the override setting.

## 0.1.3 - Options category visible
- Registered addon options with the modern Settings API so it appears under Options > AddOns.

## 0.1.2 - Root addon folder
- Moved addon `.toc` and Lua files to the repository root so the game detects the addon when cloned.

## 0.1.1 - Added outside raid toggle
- Added settings option to enable the addon outside raid groups.
- Core logic now disables the UI unless in a raid and out of combat.

## 0.1.0 - First Version
- Initial skeleton of Spectrum Loot Helper addon.
- Basic UI frame toggled with `/slh`.
- Database and officer check stubs.
- Introduced data sync module to share roll counts across the raid.
- Use addon namespace to avoid polluting the global table.
