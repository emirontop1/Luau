# Aurora design notes

Aurora now borrows the same broad feature targets as popular Roblox UI libraries without copying their source: modern windows/tabs, theme presets, rich elements, runtime notifications, flags, and config persistence.

Reference points checked while improving this implementation:

- WindUI documents runtime-swappable themes, rich elements, config flags, key systems, notifications, dialogs, and localization as core library areas.
- Rayfield emphasizes production-ready primitives such as windows, tabs, elements, notifications, themes, key systems, and config saving.
- Fluent highlights modern design, customization, and broad UI element coverage.
- Orion documents `SaveConfig`, `ConfigFolder`, `Flag`, `Save`, keybinds, dropdown refresh/set behavior, and config files.

Aurora implements the practical subset that can stay self-contained in this repository: loader-based install, themes, public elements, protected callbacks, flags, optional config save/load through executor filesystem functions when available, and a full all-elements smoke test.
