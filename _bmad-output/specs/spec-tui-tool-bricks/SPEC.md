---
id: SPEC-tui-tool-bricks
companions:
  - ../../project-context.md
  - tool-bricks.md
sources: []
---

> **Canonical contract.** This SPEC and the files in `companions:` are the complete, preservation-validated contract for what to build, test, and validate. Source documents listed in frontmatter are for traceability only; consult them only if you need narrative rationale or prose color this contract intentionally omits.

# Modular TUI Tool Bricks

## Why

The current Arch configuration can become more flexible if operational actions are exposed through a terminal UI composed of independent tool bricks. The goal is to make configuration, maintenance, and workflow actions easier to discover and combine without turning the repository into a broad generic installer product.

## Capabilities

- id: CAP-1
  intent: The user can launch a TUI entry point to browse available configuration and maintenance tools from a single terminal interface.
  success: Running the TUI presents a navigable list of tool bricks without requiring the user to remember individual script names.

- id: CAP-2
  intent: The user can execute a selected tool brick from the TUI and see whether it completed, failed, or was cancelled.
  success: Selecting a brick runs its associated action and returns control to the TUI with a visible outcome state.

- id: CAP-3
  intent: The system can discover tool bricks automatically so new menu entries can be added without rewriting the TUI flow.
  success: Adding a new brick declaration or compatible script makes it appear in the relevant TUI category without editing the core navigation model.

- id: CAP-4
  intent: The user can understand what each tool brick does before launching it.
  success: Each listed brick displays a concise name and purpose before execution.

- id: CAP-5
  intent: The TUI can expose only safe, repository-owned operations by default.
  success: Destructive, machine-specific, or privileged actions are absent by default or require an explicit confirmation step before execution.

- id: CAP-6
  intent: The user can browse tool bricks through categories that reflect existing repository workflows while leaving room for new entries.
  success: The TUI includes top-level Setup, Maintenance, Appearance, Desktop, and System categories and can accept new categories or bricks without a structural rewrite.

- id: CAP-7
  intent: The user can preview critical actions before committing to them when a dry-run is available.
  success: Critical bricks expose a dry-run or preview path as they are defined, and bricks without dry-run support clearly indicate that limitation before execution.

## Constraints

- The implementation must fit this repository's personal Arch configuration model and avoid becoming a generic cross-distribution product.
- TUI actions that touch live system or user configuration must remain idempotent and safe to rerun.
- Scripts intended for user execution must live in `scripts/` and be installable into `~/.local/bin`.
- The TUI must preserve existing package ownership boundaries: Pacman lists, AUR lists, and optional hardware-specific setup remain separate.
- The TUI must not silently overwrite generated theme files or user-applied configuration.
- The TUI should use OpenTUI to support a richer interface than the current Fuzzel-driven menu.
- Tool brick discovery must not execute arbitrary scripts just because they exist; discovery needs an explicit contract, naming convention, metadata file, or equivalent safe marker.
- Tool brick discovery should use explicit metadata on repo-owned scripts, following the command-center pattern used by Omarchy rather than hardcoded menu wiring.
- Dry-run support is required for critical actions as those bricks are defined, but the first version may introduce it incrementally per brick.
- Global update belongs under Maintenance, not Setup, because it is a recurring maintenance action rather than initial configuration.
- The TUI command name is `arch-tui`.
- If OpenTUI requires TypeScript/Node structure, the TUI code should live under `dotfiles/arch-tui/`; simple executable entry points still install through `scripts/` into `~/.local/bin`.

## Non-goals

- Build a full graphical desktop control center.
- Replace existing scripts or installer behavior in one rewrite.
- Make hardware-specific setup mandatory.
- Support non-Arch Linux systems.
- Provide dry-run coverage for every existing script in the first iteration.

## Success signal

- A user can open one terminal command, discover several tool bricks, run at least one safe brick, and return to the menu with a clear result without knowing the underlying script path.
- A developer can add another brick without changing the core navigation model.
- A critical brick can expose a dry-run path before execution when that brick has been marked as requiring preview support.
- The user can open Maintenance > Global Update to preview and run recurring update workflows without entering Setup.
- The MVP demonstrates metadata discovery, category rendering, command execution, critical confirmation, optional dry-run, and the first Maintenance > Global Update brick.

## Assumptions

- Assumed the first version should be local and script-driven, not a daemon or long-running background service.
- Assumed "briques d'outils" means independently declared actions that can be composed inside one TUI shell.
- Assumed the initial scope is repository maintenance/configuration workflows, not arbitrary third-party plugins.
- Assumed OpenTUI is acceptable as the richer TUI dependency for this feature.
- Assumed auto-discovery will be constrained by explicit `arch-tui:*` script metadata rather than scanning and running every executable in `scripts/`.
- Assumed the command entry point will be `arch-tui`.
- Assumed OpenTUI implementation code will live in `dotfiles/arch-tui/` if it needs a richer TypeScript/Node project layout.

## Open Questions

- What exact `arch-tui:*` metadata keys are required for the first implementation?
- Which steps should the first Global Update include beyond package updates and dry-run preview?
- Which existing actions should be marked critical first for dry-run or preview support?
