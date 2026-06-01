# Story 1.1: Arch TUI MVP

Status: ready-for-dev

## Story

As the owner of this Arch configuration,
I want an `arch-tui` command that discovers tool bricks and presents them in an OpenTUI interface,
so that I can run recurring setup, maintenance, appearance, desktop, and system actions from a modular terminal UI.

## Acceptance Criteria

1. `arch-tui` is available as an installable user command from `scripts/arch-tui` and can be run without root.
2. The TUI implementation uses OpenTUI and lives under `dotfiles/arch-tui/` if a TypeScript/Node project layout is required.
3. The TUI discovers repo-owned scripts through explicit `arch-tui:*` metadata and does not expose scripts that lack the metadata contract.
4. The MVP renders top-level categories: `Setup`, `Maintenance`, `Appearance`, `Desktop`, and `System`.
5. Selecting a discovered non-critical brick runs its configured command and shows completion, failure, or cancellation before returning control to the TUI.
6. Selecting a brick with `critical=true` requires explicit confirmation before execution.
7. If a critical brick has a `dry-run` metadata command, the TUI offers a preview/dry-run path before execution.
8. If a critical brick has no `dry-run` metadata command, the TUI clearly states that no dry-run is available and still requires explicit confirmation.
9. The first `Maintenance > Global Update` brick exists and supports a dry-run/preview mode.
10. Existing `arch-menu`, setup scripts, theme switching, package ownership, and generated theme overwrite protections continue to work unchanged.

## Tasks / Subtasks

- [ ] Create the `arch-tui` launcher (AC: 1, 2)
  - [ ] Add `scripts/arch-tui` with `set -euo pipefail` and normal-user execution.
  - [ ] If using TypeScript/OpenTUI, have the launcher execute the app from `dotfiles/arch-tui/` without requiring root.
  - [ ] Rely on the existing `install_scripts()` loop in `install.sh`, which installs every file in `scripts/` to `~/.local/bin`.

- [ ] Add the OpenTUI app structure (AC: 2, 4, 5)
  - [ ] Create the minimal `dotfiles/arch-tui/` project only if OpenTUI requires it.
  - [ ] Use `@opentui/core`; do not use unrelated TUI frameworks.
  - [ ] Keep the UI simple: category list, brick list/details, actions for run/dry-run/back/quit.
  - [ ] Handle terminal exit cleanup so the shell is usable after quitting or after a command fails.

- [ ] Implement safe metadata discovery (AC: 3, 4)
  - [ ] Scan repo-owned `scripts/` entries only.
  - [ ] Parse only leading comment metadata lines using the `arch-tui:<key>=<value>` format.
  - [ ] Require at least `id`, `category`, `name`, `summary`, `command`, and `critical` keys.
  - [ ] Support optional `dry-run` metadata.
  - [ ] Do not execute scripts during discovery.
  - [ ] Ignore scripts with missing or invalid required metadata, and show/report discovery errors in a non-crashing way.

- [ ] Implement command execution and result handling (AC: 5, 6, 7, 8)
  - [ ] Run commands exactly from metadata, not by guessing from filenames.
  - [ ] Show command output or a terminal handoff that preserves visibility of results.
  - [ ] Return to the TUI after success, failure, cancellation, or dry-run.
  - [ ] Apply explicit confirmation before any `critical=true` execution.
  - [ ] Show dry-run first when `dry-run` exists.

- [ ] Add initial metadata-backed bricks (AC: 4, 9, 10)
  - [ ] Add `Maintenance > Global Update` as the first required brick.
  - [ ] Add dry-run/preview for Global Update.
  - [ ] Add optional MVP bricks only if low-risk and metadata-backed: theme switch, hypridle toggle, DNS setup, or existing config openers.
  - [ ] Preserve existing direct script usage; metadata must not break CLI invocation of scripts.

- [ ] Implement the Global Update script behavior (AC: 9, 10)
  - [ ] Prefer a staged checklist over one opaque command.
  - [ ] Include Pacman package update and AUR package update as the first concrete stages.
  - [ ] Keep Pacman and AUR package ownership separate.
  - [ ] Add optional repo-owned tooling refresh or desktop component reload only when safe and explicit.
  - [ ] The dry-run must show planned stages and commands without performing updates.

- [ ] Validate and document (AC: 1-10)
  - [ ] Run Bash syntax checks for changed scripts: `bash -n scripts/arch-tui` and any new/modified shell scripts.
  - [ ] Run the available TypeScript/OpenTUI validation command if the local dependencies are installed.
  - [ ] Do not invent CI or test commands that do not exist.
  - [ ] Update README only for user-visible command/menu behavior.

## Dev Notes

### Source Spec

- Primary contract: `_bmad-output/specs/spec-tui-tool-bricks/SPEC.md`.
- Companion: `_bmad-output/specs/spec-tui-tool-bricks/tool-bricks.md`.
- Project rules: `_bmad-output/project-context.md`.

### Required Metadata Contract

Use script-local metadata, inspired by Omarchy's command-center pattern, but keep this repo's prefix:

```bash
#!/usr/bin/env bash
# arch-tui:id=global-update
# arch-tui:category=maintenance
# arch-tui:name=Global Update
# arch-tui:summary=Update pacman, AUR packages, and repo-owned tooling
# arch-tui:command=arch-global-update
# arch-tui:critical=true
# arch-tui:dry-run=arch-global-update --dry-run
set -euo pipefail
```

Required keys for MVP: `id`, `category`, `name`, `summary`, `command`, `critical`.

Optional key for MVP: `dry-run`.

Valid MVP categories: `setup`, `maintenance`, `appearance`, `desktop`, `system`.

Do not auto-run or trust scripts only because they are executable. Discovery must only read metadata.

### Existing Code To Preserve

- `scripts/arch-menu` is the current Fuzzel menu entry point. Do not rewrite it wholesale for this story. If adding `arch-tui` access from the existing menu, make the smallest additive change.
- `scripts/theme-switch` already protects generated theme overwrites through `confirm_theme_overwrite`; do not bypass this from the TUI.
- `scripts/arch-setup-dns` writes `/etc/systemd/resolved.conf` and restarts `systemd-resolved`; treat DNS changes as critical if exposed.
- `scripts/arch-setup-howdy` installs Howdy and edits PAM for `sudo` and `hyprlock`; treat as critical if exposed.
- `scripts/arch-setup-limine` writes bootloader files and can change EFI boot order; treat as critical if exposed.
- `scripts/arch-setup-voxtype` downloads a model and restarts a user service; keep it optional.
- `scripts/arch-toggle-hypridle` toggles a user service and is a good low-risk Desktop brick candidate.

### Project Structure Requirements

- `scripts/arch-tui`: user-facing executable launcher installed into `~/.local/bin` like existing scripts.
- `dotfiles/arch-tui/`: OpenTUI implementation if a TypeScript/Node project is needed.
- New user-executable helper scripts belong in `scripts/`, not under arbitrary folders.
- `install.sh` already installs every regular file under `scripts/` with `install -Dm755`; do not duplicate that installer logic unless the OpenTUI app has additional install-time needs.
- Do not commit generated dependency folders such as `node_modules`.
- Do not add a broad framework or build system beyond what OpenTUI actually needs.

### OpenTUI Technical Context

- OpenTUI package: `@opentui/core`.
- Current npm version observed during story creation: `0.3.1`.
- OpenTUI is a Zig native core with TypeScript bindings and is commonly installed with Bun: `bun install @opentui/core`.
- OpenTUI docs state Zig is required to build packages. Confirm whether the Arch package set needs `zig` and `bun` before adding dependencies.
- If Bun is required, decide whether `mise`-managed Node is sufficient or whether Bun must be added explicitly to package lists. Do not silently add dependencies without updating the relevant package list and README.

### Global Update Guidance

Global Update belongs under `Maintenance`, not `Setup`.

First version should be staged and visible:

1. Preview planned stages and commands in dry-run mode.
2. Update Pacman packages.
3. Update AUR packages through `yay` when available.
4. Optionally refresh repo-owned tooling only when the step is explicit and safe.
5. Optionally restart/reload desktop components only when the user selects or confirms it.
6. Show a final summary.

Do not merge Pacman package lists and AUR package lists into one ownership model. Keep the existing split from `install.sh` and `packages/*.txt`.

### Critical Action Policy

Critical examples: package/system updates, bootloader changes, DNS rewrites, PAM changes, generated theme overwrites, reboot, shutdown, suspend, and any command that requires `sudo`.

Critical execution requirements:

- Show the command or staged operation before running.
- Offer dry-run when metadata provides it.
- Require explicit confirmation before real execution.
- Clearly indicate when no dry-run exists.

### Testing Requirements

- Bash scripts must pass `bash -n`.
- If TypeScript/OpenTUI dependencies are installed locally, run the package's available typecheck/build command.
- If dependencies are missing, report that validation could not run; do not fabricate a passing result.
- Avoid live destructive validation for package updates, bootloader, DNS, PAM, reboot, shutdown, or generated theme overwrite paths.

### Anti-Patterns To Avoid

- Do not scan and execute every file in `scripts/`.
- Do not turn this personal Arch config into a generic distro/product installer.
- Do not replace `arch-menu` wholesale in this MVP.
- Do not bypass existing safety prompts in `theme-switch`, Limine, Howdy, DNS, or system power actions.
- Do not remove Waybar or alter AGS behavior as part of this story.
- Do not assume NetworkManager is active.

### References

- `_bmad-output/specs/spec-tui-tool-bricks/SPEC.md#Capabilities`
- `_bmad-output/specs/spec-tui-tool-bricks/SPEC.md#Constraints`
- `_bmad-output/specs/spec-tui-tool-bricks/tool-bricks.md#MVP-Scope`
- `_bmad-output/specs/spec-tui-tool-bricks/tool-bricks.md#Metadata-Shape`
- `_bmad-output/project-context.md#Technology-Stack--Versions`
- `_bmad-output/project-context.md#Critical-Implementation-Rules`
- `README.md#Menu-Systeme`
- `README.md#Themes`
- `install.sh` package install and script install patterns
- `install.sh:551-557` existing `install_scripts()` behavior
- `scripts/arch-menu`
- `scripts/theme-switch`

### Recent Repository Pattern

- Recent commits are concise imperative messages such as `Add optional Limine bootloader setup` and `Fix Plymouth setup for UKI boot`.
- Preserve the same implementation style: focused scripts, minimal installer changes, and explicit safety prompts for boot/system-impacting actions.

## Dev Agent Record

### Agent Model Used

TBD by dev agent

### Debug Log References

### Completion Notes List

### File List
