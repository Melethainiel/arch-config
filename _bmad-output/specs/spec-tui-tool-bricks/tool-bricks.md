# Tool Brick Categories

This companion proposes initial TUI categories from the current repository surface. The list is expected to grow; new entries should fit the discovery contract rather than requiring core menu rewrites.

## Runtime

- The user-facing command is `arch-tui`.
- Use OpenTUI for the richer terminal interface.
- Keep the TUI local and script-driven; do not introduce a daemon for the first version.
- Auto-discovery must read explicit `arch-tui:*` script metadata before exposing an executable action.
- Use Omarchy's command-center pattern as inspiration: scripts stay executable alone, while metadata provides group, name, summary, criticality, and optional dry-run behavior.
- If OpenTUI needs a TypeScript/Node project layout, place the implementation under `dotfiles/arch-tui/` and keep an installable launcher in `scripts/arch-tui`.

## MVP Scope

- Discover scripts with `arch-tui:*` metadata.
- Render top-level categories: Setup, Maintenance, Appearance, Desktop, and System.
- Run a selected command and show completion, failure, or cancellation.
- Require confirmation for `critical=true` bricks.
- Show and run dry-run/preview when metadata provides it.
- Include the first `Maintenance > Global Update` brick.

## Proposed Categories

- Setup: audio (`wiremix`), Wi-Fi (`impala`), Bluetooth (`bluetui`), power profile, sleep behavior, monitors, keybindings, input, defaults, DNS, security, bootloader, and config editing.
- Maintenance: global update, package updates, AUR updates, diagnostics, script refresh, config validation, and restart/reload of desktop components.
- Appearance: wallpaper and preset application through `theme-switch`, with overwrite confirmation preserved; future font and visual customization entries can land here.
- Desktop: Hypridle toggle, Hyprland config, Hypridle config, Hyprlock config, AGS, Fuzzel, SwayNC, Ghostty, Fastfetch config editing, and session-specific utilities.
- System: lock, suspend, logout, reboot, shutdown, and about/status actions currently exposed by `arch-menu`.

## Critical Action Policy

- Critical actions should support dry-run or preview as each brick is defined.
- Critical examples include bootloader changes, DNS rewrites, PAM changes, package/system updates, generated theme overwrites, and poweroff/reboot actions.
- If a critical brick has no dry-run yet, the TUI must show that limitation and require explicit confirmation before execution.

## Global Update

- Place Global Update under Maintenance, not Setup.
- Treat it as a staged checklist rather than a single opaque command.
- First version should include dry-run/preview, Pacman package update, AUR package update, optional repo-owned tooling refresh, optional desktop component restart/reload, and a final summary.
- Add more update steps over time through new metadata-backed bricks rather than expanding core TUI logic.

## Discovery Direction

- Prefer script-local metadata over hardcoded menu wiring.
- A brick needs at least an id, category, name, summary, command, criticality flag, and optional dry-run command.
- Discovery should allow future new menu entries without editing the core OpenTUI navigation.

## Metadata Shape

Example script header:

```bash
#!/usr/bin/env bash
# arch-tui:id=global-update
# arch-tui:category=maintenance
# arch-tui:name=Global Update
# arch-tui:summary=Update pacman, AUR packages, and repo-owned tooling
# arch-tui:critical=true
# arch-tui:dry-run=arch-global-update --dry-run
set -euo pipefail
```
