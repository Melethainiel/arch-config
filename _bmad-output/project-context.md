---
project_name: 'arch-config'
user_name: 'Thibaud'
date: '2026-06-01'
sections_completed: ['technology_stack', 'language_rules', 'framework_rules', 'testing_rules', 'quality_rules', 'workflow_rules', 'anti_patterns']
existing_patterns_found: 9
status: 'complete'
rule_count: 50
optimized_for_llm: true
---

# Project Context for AI Agents

_This file contains critical rules and patterns that AI agents must follow when implementing code in this project. Focus on unobvious details that agents might otherwise miss._

---

## Technology Stack & Versions

- Target OS: Arch Linux, validated by `install.sh` through `/etc/arch-release`.
- Installer/runtime scripts: Bash with `set -euo pipefail`; scripts are installed to `~/.local/bin`.
- Desktop stack: Hyprland, hypridle, hyprlock, hyprpaper, hyprpolkitagent, xdg-desktop-portal-hyprland.
- Hyprland configuration: Lua modules under `dotfiles/hypr`; `hyprland.lua` is the entrypoint.
- Bar/shell UI: AGS/Aylur GTK Shell from AUR package `aylurs-gtk-shell-git`, not `aur/ags`.
- AGS code: TypeScript/TSX in `dotfiles/ags` with `strict: true`, `target: ES2020`, `module: ES2022`, `moduleResolution: Bundler`, `jsxImportSource: ags/gtk4`.
- Theme system: `matugen` generates colors for AGS, SwayNC, Hyprland, Ghostty, Fuzzel, GTK, VS Code, btop, and OpenCode.
- Network stack: `iwd + impala`; installer disables NetworkManager and wpa_supplicant when present.
- Package sources: Pacman packages are split by purpose in `packages/*.txt`; AUR packages live only in `packages/aur.txt` and are installed via `yay`.
- Node tooling: `mise` is a baseline package and installs global Node.js LTS.

## Critical Implementation Rules

### Language-Specific Rules

- Bash scripts must keep `set -euo pipefail`; handle optional commands with explicit `|| true` only where absence/failure is expected.
- Installer functions should remain idempotent: check existing files, packages, units, and generated config before overwriting.
- Do not run installer logic as root; `install.sh` intentionally requires a normal user and uses `sudo` only for privileged operations.
- When editing files under `$HOME/.config`, preserve generated theme files unless the code explicitly asks for overwrite confirmation.
- Keep package parsing compatible with comments and blank lines; `read_packages` strips `#` comments and empty lines.
- AGS TypeScript is strict TSX for `ags/gtk4`; use existing `createPoll`, signal, and widget patterns rather than browser React assumptions.
- AGS imports are extensionless relative imports and package imports from `ags/*`; generated `@girs` and `node_modules` are local type artifacts and must stay untracked.
- Hyprland config is Lua, not legacy `.conf`; add new settings as small Lua modules and load them from `dotfiles/hypr/hyprland.lua` in an order that preserves generated overrides.
- Lua comments may document ordering constraints, especially where generated theme files must win.

### Framework-Specific Rules

- AGS bar windows are created per monitor in `syncBars`; dispose old roots and destroy prior `bar-*` windows before recreating monitor-bound UI.
- AGS app identity matters: normal runs use `instanceName: "arch-shell"`; test/theme validation can use `ARCH_SHELL_TEST` to avoid colliding with the real session.
- AGS widgets should remain small and colocated under `dotfiles/ags/widgets`; shared process helpers belong in `dotfiles/ags/lib`.
- Prefer AGS reactive primitives already used in the repo, such as `createPoll`, instead of introducing unrelated React state patterns.
- Shell commands embedded in AGS widgets must tolerate missing tools/devices and return empty output rather than crashing the bar.
- Hyprland Lua entry order is intentional: HyprMod managed settings load late, then generated `theme.lua` loads last so active theme values win.
- Workspace number shortcuts use physical keycodes for FR/AZERTY keyboards; do not replace them with symbolic number keys.
- `theme-switch` owns generated theme files in user config directories and restarts/reloads session components best-effort without failing the whole theme change.
- Waybar is intentionally installed as fallback while AGS is the active bar; do not remove Waybar just because AGS exists.

### Testing Rules

- There is no dedicated automated test suite configured in this repo yet; do not invent test commands in documentation or CI changes.
- Validate Bash changes with syntax checks where possible, for example `bash -n install.sh scripts/<name>`.
- For installer changes, prefer dry reasoning plus targeted shell syntax validation; many paths require Arch Linux, systemd, sudo, hardware, or live user services.
- Validate AGS TypeScript changes with the local AGS/TypeScript setup when available; if types are missing, run `ags types --directory dotfiles/ags --update` to regenerate local ignored type artifacts.
- Do not commit generated AGS `dotfiles/ags/@girs` or `dotfiles/ags/node_modules`.
- Theme and desktop-session changes should account for live-session side effects; reload/restart commands are best-effort and should not be treated as deterministic tests.

### Code Quality & Style Rules

- Keep the repository small and direct; avoid adding frameworks, build systems, or abstractions unless they solve an actual repo problem.
- Preserve the existing functional Bash style: top-level constants, small functions, and a final `main "$@"`.
- Use `install -D`, `mkdir -p`, existence checks, and service checks consistently for idempotent setup.
- Keep dotfile ownership clear: defaults live in `dotfiles/`; generated/applied user files live under `$HOME/.config`.
- Avoid large rewrites of `install.sh`; make minimal changes in the relevant function or add one focused function when needed.
- Keep package lists as plain newline-separated package names with comments only where they clarify purpose or hardware-specific behavior.
- AGS component files use kebab-case filenames and PascalCase exported widget functions.
- Hyprland Lua module filenames are lowercase descriptive names; keep `hyprland.lua` as the composition file.
- Comments should explain non-obvious ordering, hardware, service, or generated-file constraints, not restate simple commands.

### Development Workflow Rules

- Treat this as a personal reproducible Arch config, not a generic installer product; prefer explicit choices over broad configurability.
- Changes that affect live system files must be idempotent and safe to rerun on an already-configured machine.
- Do not add automatic destructive cleanup outside paths this repo clearly owns.
- Keep Pacman, AUR, and optional package ownership separated: Pacman packages in `packages/core.txt`, `desktop.txt`, `gaming.txt`, `dev.txt`; AUR packages in `packages/aur.txt`.
- Hardware-specific setup should stay optional or guarded, as with Howdy, GPU Vulkan packages, Limine activation, and Voxtype model download.
- Scripts intended for user execution belong in `scripts/` and are installed executable into `~/.local/bin`.
- README updates should document user-visible behavior, setup entry points, and important package/service choices.

### Critical Don't-Miss Rules

- Never replace `aylurs-gtk-shell-git` with `ags`; `aur/ags` is Adventure Game Studio, not Aylur's GTK Shell.
- Do not convert Hyprland Lua config back to legacy `.conf` files; `install.sh` explicitly removes legacy split `.conf` files.
- Keep generated Hyprland theme loading last; otherwise active wallpaper/theme colors can be overridden by static defaults.
- Do not remove Waybar until AGS is fully validated as the only bar across target machines.
- Do not assume NetworkManager is active; the intended network stack is `iwd + impala` with systemd-resolved/networkd.
- Do not make Limine the default bootloader without explicit confirmation; systemd-boot remains the fallback path.
- Do not make Howdy mandatory; it depends on IR camera hardware and config remains machine-specific.
- Do not overwrite existing generated theme files silently; preserve or ask before replacing user-applied themes.
- Do not commit local/generated AGS type artifacts from `dotfiles/ags/@girs` or `dotfiles/ags/node_modules`.

---

## Usage Guidelines

**For AI Agents:**

- Read this file before implementing any code.
- Follow all rules exactly as documented.
- When in doubt, prefer the more restrictive, idempotent, and minimal option.
- Update this file if new project-specific patterns emerge.

**For Humans:**

- Keep this file lean and focused on agent needs.
- Update it when technology stack or desktop architecture changes.
- Remove rules that become obsolete or obvious.

Last Updated: 2026-06-01
