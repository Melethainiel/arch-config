---
title: Arch TUI Utility PRD
status: draft
created: 2026-06-01
updated: 2026-06-01
---

# PRD: Arch TUI Utility

## 0. Document Purpose

This PRD defines the product requirements for `arch-tui`, a terminal UI command center for this personal Arch Linux configuration repository. It is written for downstream architecture, epic/story creation, and implementation work. The PRD builds on `_bmad-output/specs/spec-tui-tool-bricks/SPEC.md`, `_bmad-output/specs/spec-tui-tool-bricks/tool-bricks.md`, `_bmad-output/implementation-artifacts/1-1-arch-tui-mvp.md`, and `_bmad-output/project-context.md`; it does not replace those implementation-specific contracts. Requirements are grouped by feature with stable FR IDs. Inferred points are tagged with `[ASSUMPTION]` and indexed in §12.

## 1. Vision

`arch-tui` is a single terminal utility for installing, updating, maintaining, and synchronizing the user's Arch Linux machines through one discoverable interface. Instead of remembering individual scripts, setup steps, maintenance commands, or Git sync routines, the user opens one command and navigates safe, categorized tool bricks.

The product should make the repository easier to operate across multiple PCs without turning it into a generic Linux installer. It remains opinionated, personal, Arch-only, and repo-owned. The TUI should expose the user's existing setup logic, not hide it behind opaque automation. Dangerous operations remain explicit, previewable where possible, and confirmable before execution.

The long-term direction is a modular control center for machine lifecycle work: first install, recurring upgrades, configuration drift checks, maintenance tasks, appearance/session controls, and synchronization of selected files through Git. The MVP proves the core shell: metadata-backed discovery, category browsing, preview/dry-run behavior, critical-action gating, command execution, and the first `Maintenance > Global Update` workflow. Git Synchronization is explicitly deferred to phase 2.

## 2. Target User

### 2.1 Jobs To Be Done

- As the owner of several Arch machines, I want one command to discover what this repository can do so I do not need to remember script names.
- As the maintainer of my personal config, I want to run first-install and upgrade flows safely so machines stay consistent without blind overwrites.
- As a daily user, I want maintenance actions such as package updates, desktop reloads, diagnostics, and service checks to be visible and staged.
- As someone syncing dotfiles and machine-specific changes, I want Git state, diffs, pulls, commits, and pushes to be explicit so I do not lose local changes or leak sensitive files.
- As a developer of this repo, I want new actions to appear through metadata rather than editing the TUI navigation each time.

### 2.2 Non-Users (v1)

- Users outside this repository or outside the user's machines.
- Non-Arch Linux users.
- People looking for a generic distro installer, generic dotfile manager, or GUI desktop control center.
- Multi-user teams needing role-based access, audit approvals, or enterprise policy enforcement.

### 2.3 Key User Journeys

- **UJ-1. Thibaud performs a first install on a fresh PC.** Thibaud boots into a new Arch environment or a recently installed base system and launches `arch-tui` from the repository checkout. He enters `Setup`, reviews the available setup bricks, previews high-impact steps when possible, and runs the selected install/configuration actions. The TUI returns clear success/failure status for each step and preserves existing safeguards around root, generated files, and hardware-specific setup. The value lands when the machine reaches a known configured state without requiring Thibaud to memorize the repository's script surface. **Edge case:** if a machine-specific step such as Howdy, Limine, DNS, or hardware setup is selected, the TUI marks it critical and requires explicit confirmation before execution.

- **UJ-2. Thibaud upgrades an already configured PC.** Thibaud launches `arch-tui` on a machine that already uses this repo. He opens `Maintenance > Global Update`, reviews the planned stages, runs the dry-run/preview, then executes the real update. Pacman and AUR updates remain visibly separate, optional repo-owned tooling refreshes are explicit, and the final summary shows what changed or failed. The value lands when the PC is updated while preserving package-source boundaries and giving Thibaud enough information to troubleshoot.

- **UJ-3. Thibaud synchronizes configuration changes through Git.** Thibaud has edited local config files and wants to bring one machine in sync with the repository or publish selected changes. He opens a Git synchronization category or brick, sees repository status and diffs, pulls or fetches safely, chooses files to stage or confirms the proposed staged set, commits with a visible message, and pushes only after confirmation. The value lands when synchronization is deliberate, reversible where possible, and does not silently overwrite local changes or publish secrets. **Edge case:** if dirty files, untracked secret-like files, or merge conflicts exist, the TUI blocks one-click sync and routes him to an explicit resolution path.

- **UJ-4. Thibaud runs a small desktop or appearance action.** Thibaud wants to toggle Hypridle, apply a theme, reload desktop components, lock the session, or open a config file. He navigates to `Desktop`, `Appearance`, or `System`, reads the brick summary, and runs the action. Low-risk actions run quickly and return to the menu; critical actions such as reboot, shutdown, generated theme overwrite, or privileged changes require confirmation. The value lands when daily operational commands become discoverable without weakening existing safety prompts.

- **UJ-5. Thibaud adds a new tool brick.** Thibaud writes or updates a repo-owned script and adds `arch-tui:*` metadata. After launching `arch-tui`, the new brick appears in the correct category without changing core navigation code. The value lands when new workflows can be added incrementally while keeping discovery safe and explicit.

## 3. Glossary

- **Tool Brick** — A repo-owned executable action exposed in `arch-tui` through explicit metadata. A Tool Brick can be run directly as a script and can also be discovered by the TUI.
- **Metadata Contract** — The `arch-tui:*` comment fields that declare a Tool Brick's ID, category, name, summary, command, criticality, and optional preview/dry-run behavior.
- **Category** — A top-level grouping in the TUI. MVP Categories are `Setup`, `Maintenance`, `Appearance`, `Desktop`, and `System`.
- **Critical Action** — A Tool Brick that can make privileged, destructive, irreversible, system-impacting, network-impacting, package-impacting, or configuration-overwriting changes.
- **Preview** — A non-mutating explanation, diff, status view, planned command list, or script-provided output that shows what a Tool Brick intends to do.
- **Dry Run** — A non-mutating execution mode provided by a Tool Brick command that simulates or lists planned changes.
- **Global Update** — The Maintenance workflow that stages recurring update work, initially including Pacman updates, AUR updates, optional repo-owned tooling refresh, optional desktop reload/restart, and final summary.
- **Git Synchronization** — TUI-supported repository status, diff, fetch/pull, stage, commit, and push workflows for selected config files and repo changes.
- **First Install** — The setup path used to bootstrap or configure a new PC with this repository's Arch configuration.
- **Configuration Upgrade** — The path used to apply repository changes to an already configured PC while preserving local safety constraints.
- **Machine-Specific Action** — A Tool Brick whose behavior depends on hardware, bootloader state, local services, or host-specific configuration.

## 4. Features

### 4.1 TUI Shell and Navigation

**Description:** `arch-tui` provides a single terminal entry point with category navigation, brick listing, brick details, action choices, and result visibility. The first version uses OpenTUI for a richer terminal interface than the current Fuzzel-driven `arch-menu`. It must remain usable as a local command and must not require root to launch. Realizes UJ-1, UJ-2, UJ-4, and UJ-5.

**Functional Requirements:**

#### FR-1: Launch `arch-tui`

The user can run `arch-tui` as an installable user command from `scripts/arch-tui` without launching the TUI as root.

**Consequences (testable):**
- `scripts/arch-tui` exists and is installable through the repository's existing script installation path.
- Running `arch-tui` as a normal user opens the TUI or exits with a clear dependency/setup error.
- Running `arch-tui` must not require the entire process to run under `sudo`.

#### FR-2: Render Core Categories

The TUI can render the MVP Categories `Setup`, `Maintenance`, `Appearance`, `Desktop`, and `System`.

**Consequences (testable):**
- Each Category appears when at least one valid Tool Brick exists for it.
- Empty Categories are either hidden or shown with an empty-state message. [ASSUMPTION: hiding empty Categories is acceptable for MVP if discoverability of available actions is clearer.]
- Category labels in the UI use title case while metadata values use stable lowercase identifiers.

#### FR-3: Browse Tool Brick Details

The user can inspect a Tool Brick's name, summary, category, criticality, command, and preview/dry-run availability before execution.

**Consequences (testable):**
- Selecting a Tool Brick shows its summary before run choices.
- Critical Actions are visibly marked before the user reaches execution.
- If no Preview or Dry Run exists, the TUI says so explicitly.

#### FR-4: Preserve Terminal Usability

The TUI restores the terminal to a usable state after quit, success, failure, cancellation, or command execution.

**Consequences (testable):**
- Quitting returns control to the shell.
- Failed Tool Brick execution returns control to the TUI or shell with visible error state.
- Long-running or interactive commands expose output in a way the user can read before continuing.

### 4.2 Metadata-Backed Tool Brick Discovery

**Description:** `arch-tui` discovers Tool Bricks from explicit repo-owned metadata, not from arbitrary executable scanning. This lets the user add new menu entries without rewriting core navigation while preventing accidental exposure of unsafe scripts. Realizes UJ-5.

**Functional Requirements:**

#### FR-5: Read Explicit Metadata Contract

The system can discover Tool Bricks by parsing leading `arch-tui:<key>=<value>` comment metadata from repo-owned scripts.

**Consequences (testable):**
- Discovery reads script metadata without executing scripts.
- Required MVP metadata keys are `id`, `category`, `name`, `summary`, `command`, and `critical`.
- Optional MVP metadata key is `dry-run`.
- Scripts missing required metadata are ignored or reported as invalid without crashing the TUI.

#### FR-6: Restrict Discovery Surface

The system exposes only repo-owned Tool Bricks from approved locations. [ASSUMPTION: MVP discovery scans `scripts/` only.]

**Consequences (testable):**
- Discovery does not scan arbitrary `$PATH` executables.
- Discovery does not expose a script only because it is executable.
- Discovery does not follow user-writable external plugin paths in MVP.

#### FR-7: Support Incremental Brick Addition

The user can add a new Tool Brick by adding valid metadata to a compatible repo-owned script without editing core TUI navigation.

**Consequences (testable):**
- A new script with valid metadata appears in the expected Category.
- Invalid category values are rejected or reported.
- Duplicate IDs are rejected or reported in a non-crashing way.

### 4.3 Command Execution and Result Handling

**Description:** The TUI runs selected Tool Bricks, shows whether they completed, failed, or were cancelled, and returns control to the user. It must avoid hiding important system output behind an opaque spinner. Package operations, privileged commands, and long-running workflows should make output visible. Realizes UJ-1, UJ-2, and UJ-4.

**Functional Requirements:**

#### FR-8: Execute Metadata Command

The TUI runs the command declared by Tool Brick metadata and does not infer commands from filenames.

**Consequences (testable):**
- Selecting Run executes the metadata `command` value.
- The TUI does not execute scripts during discovery.
- Direct script invocation outside the TUI continues to work unchanged.

#### FR-9: Show Outcome State

The TUI shows success, failure, or cancellation after Tool Brick execution.

**Consequences (testable):**
- A zero exit code is shown as success.
- A non-zero exit code is shown as failure with visible exit information.
- User cancellation is distinguishable from command failure when supported by the execution model.

#### FR-10: Preserve Output Visibility

The TUI gives the user access to command output for long-running, privileged, package, update, or failure-prone operations.

**Consequences (testable):**
- Package update output is visible during or after execution.
- Errors are not swallowed.
- The user can return to the TUI after reviewing output.

### 4.4 Critical Action Safety, Preview, and Dry Run

**Description:** Critical Actions must be visibly identified, previewable where possible, and explicitly confirmed before mutation. The TUI should strengthen existing safety behavior without bypassing script-level confirmations. Realizes UJ-1, UJ-2, UJ-3, and UJ-4.

**Functional Requirements:**

#### FR-11: Mark Critical Actions

The TUI identifies Tool Bricks with `critical=true` as Critical Actions before execution.

**Consequences (testable):**
- Critical Actions show a visible warning in the detail view.
- The warning appears before the user can run the action.
- Criticality is metadata-driven, not hardcoded only in the UI.

#### FR-12: Require Explicit Confirmation

The TUI requires explicit confirmation before running any Critical Action.

**Consequences (testable):**
- A Critical Action cannot run from a single accidental select/enter action.
- The confirmation includes the action name and command or staged operation.
- Existing script-level prompts such as theme overwrite confirmation remain intact.

#### FR-13: Offer Preview or Dry Run When Available

The TUI offers Preview or Dry Run before running a Critical Action when the Tool Brick provides a `dry-run` command or equivalent preview metadata.

**Consequences (testable):**
- A Tool Brick with `dry-run` exposes a preview/dry-run option before real execution.
- Dry Run executes the metadata `dry-run` command, not a guessed command.
- Dry Run returns to the Tool Brick detail or result screen without running the real command.

#### FR-14: State Missing Dry Run Clearly

If a Critical Action has no Dry Run, the TUI clearly states that limitation and still requires confirmation.

**Consequences (testable):**
- Critical Actions without `dry-run` display a "no dry run available" message or equivalent.
- The absence of Dry Run does not silently downgrade confirmation requirements.

### 4.5 First Install and Configuration Upgrade Workflows

**Description:** `arch-tui` should make first install and configuration upgrade flows discoverable through Tool Bricks while preserving the repository's idempotent, Arch-specific setup model. The TUI is an orchestrating interface over existing and future scripts, not a rewrite of `install.sh` in UI form. Realizes UJ-1 and UJ-2.

**Functional Requirements:**

#### FR-15: Expose First Install Actions Through Setup

The user can discover first-install-relevant Tool Bricks under `Setup`.

**Consequences (testable):**
- Setup can include install/configuration bricks for repository-owned setup actions.
- Hardware-specific actions such as Howdy, Limine, DNS, or Voxtype remain optional and guarded when exposed.
- The TUI does not make hardware-specific setup mandatory.

#### FR-16: Preserve Idempotent Setup Behavior

Setup and upgrade Tool Bricks must remain safe to rerun where the underlying repository behavior is intended to be idempotent.

**Consequences (testable):**
- Tool Bricks do not remove existing setup checks from scripts.
- Actions touching live system or user configuration keep existing safeguards.
- Generated theme files and user-applied config are not overwritten silently.

#### FR-17: Distinguish First Install From Configuration Upgrade

The TUI helps the user distinguish bootstrap/new-machine setup from recurring configuration upgrade work. [ASSUMPTION: MVP can do this through Category placement and brick summaries rather than a full guided wizard.]

**Consequences (testable):**
- Recurring update work appears under `Maintenance`, not `Setup`.
- Setup brick summaries clarify whether an action is first-install, machine-specific, or recurring.
- Configuration upgrade actions do not pretend to be safe first-install defaults unless they are designed for that path.

### 4.6 Maintenance and Global Update

**Description:** Maintenance is the recurring operations area for already configured PCs. The first required workflow is `Maintenance > Global Update`, presented as a staged workflow rather than a single opaque command. Realizes UJ-2.

**Functional Requirements:**

#### FR-18: Provide Global Update Brick

The MVP includes a `Maintenance > Global Update` Tool Brick.

**Consequences (testable):**
- A valid metadata-backed Global Update brick appears under Maintenance.
- The brick is marked critical.
- The brick supports Dry Run or Preview.

#### FR-19: Stage Global Update Work

Global Update presents recurring update work as visible stages.

**Consequences (testable):**
- Dry Run lists planned stages and commands without performing updates.
- Real execution includes Pacman package update and AUR package update when the required tools are available.
- Optional repo-owned tooling refresh and desktop reload/restart are explicit, not hidden side effects.

#### FR-20: Preserve Package Ownership Boundaries

Global Update keeps Pacman and AUR package ownership separate.

**Consequences (testable):**
- Pacman and AUR steps are presented separately.
- AUR updates use `yay` when available.
- Package list ownership remains aligned with `packages/*.txt` and `packages/aur.txt`.

#### FR-21: Summarize Maintenance Results

Global Update and maintenance actions show a final summary of completed, failed, skipped, or cancelled stages.

**Consequences (testable):**
- The user can see which stages ran.
- Skipped optional steps are visible.
- Failures identify the failing stage.

### 4.7 Git Synchronization and File Safety

**Description:** `arch-tui` should manage synchronization of repository and selected configuration files through Git-oriented workflows in phase 2, after the MVP shell and Global Update workflow. This extends the original spec with the user's clarified goal of synchronizing various files across PCs. Because Git sync can overwrite local work or leak secrets, phase 2 requirements emphasize preview-first behavior and explicit confirmation. Realizes UJ-3.

**Functional Requirements:**

#### FR-22: Show Git Status and Diff Before Sync

The user can view repository status and diffs before running synchronization actions.

**Consequences (testable):**
- Git status is visible before pull, commit, or push actions.
- File diffs are available before applying or publishing changes where applicable.
- Dirty worktree state is not ignored.

#### FR-23: Separate Pull, Stage, Commit, and Push

Git Synchronization exposes pull/fetch, stage, commit, and push as separate visible steps or explicitly staged operations.

**Consequences (testable):**
- Push does not happen silently as part of a generic sync by default.
- Staged files are visible before commit.
- Commit message is visible or user-provided before commit.

#### FR-24: Protect Against Secret or Accidental File Publication

Git Synchronization warns before committing or pushing obvious secret-like files, generated dependency artifacts, or files outside expected ownership. [ASSUMPTION: MVP can use filename/path heuristics and Git status rather than a full secret scanner.]

**Consequences (testable):**
- `.env`, credential-like filenames, generated AGS type artifacts, `node_modules`, and other ignored/generated patterns are not silently staged by a TUI sync action.
- Auto-push is disabled by default.
- The user must confirm before first push or before publishing unusual files.

#### FR-25: Block Unsafe One-Click Sync States

The TUI blocks one-click synchronization when conflicts, unresolved merges, suspicious untracked files, or destructive Git operations are detected.

**Consequences (testable):**
- Merge conflict state prevents automatic sync completion.
- Destructive Git operations such as reset/clean are not run without explicit high-risk confirmation.
- The user is routed to manual resolution or an explicit guided action.

**Out of Scope:**
- Building a complete replacement for Git, chezmoi, yadm, or a secret management system.
- Automatically syncing arbitrary home-directory files outside repository-owned paths in MVP.

### 4.8 Appearance, Desktop, and System Actions

**Description:** The TUI can expose day-to-day operational actions currently scattered across scripts or menus: theme switching, Hypridle toggles, desktop config helpers, lock/suspend/logout/reboot/shutdown, and status/about actions. These should be metadata-backed and safety-classified. Realizes UJ-4.

**Functional Requirements:**

#### FR-26: Expose Low-Risk Daily Actions

The TUI can expose low-risk daily actions such as Hypridle toggle, config openers, status/about commands, or desktop reload helpers.

**Consequences (testable):**
- Low-risk Tool Bricks can run without critical confirmation when marked non-critical.
- Each action still shows a summary before execution.
- Existing direct script usage remains unchanged.

#### FR-27: Preserve Theme Safety

Appearance Tool Bricks preserve existing generated theme overwrite confirmations and theme application safeguards.

**Consequences (testable):**
- `theme-switch` safeguards are not bypassed.
- Generated theme files are not silently overwritten by the TUI.
- Best-effort component reload behavior remains best-effort and does not turn theme changes into hard failures unnecessarily.

#### FR-28: Guard Power and Session Actions

System power/session actions such as reboot, shutdown, suspend, and logout are Critical Actions when exposed.

**Consequences (testable):**
- Power/session actions require explicit confirmation.
- The action name and expected effect are shown before execution.
- Accidental selection cannot immediately power off or reboot the system.

## 5. Cross-Cutting Non-Functional Requirements

- **Safety:** The TUI must prefer preview, dry-run, and explicit confirmation over hidden mutation for Critical Actions.
- **Repository Fit:** The product must remain a personal Arch configuration tool, not a generic installer product.
- **Idempotency:** Actions that touch live system or user configuration must preserve existing idempotent behavior and be safe to rerun where scripts already promise that behavior.
- **Discoverability:** A user should be able to understand available actions from category names, brick names, and summaries without reading script source.
- **Transparency:** Long-running, privileged, package, Git, or destructive operations must expose their commands, planned stages, output, or diffs enough for troubleshooting.
- **Extensibility:** Adding Tool Bricks should primarily require metadata additions, not core navigation rewrites.
- **Dependency Discipline:** OpenTUI and any runtime dependencies must be justified, documented, and added through the repository's package/dependency conventions.
- **Terminal Recovery:** The TUI must not leave the terminal in a broken state after exit or failure.
- **Generated Artifact Protection:** Generated or local artifacts such as AGS `@girs`, `node_modules`, generated theme files, and user-applied config must not be silently committed, overwritten, or removed.

## 6. Constraints and Guardrails

### 6.1 Technical Constraints

- Target OS is Arch Linux only.
- The user-facing command is `arch-tui`.
- OpenTUI is the intended TUI framework.
- If OpenTUI requires a TypeScript/Node project layout, implementation code should live under `dotfiles/arch-tui/`.
- User-executable launchers and helper scripts belong in `scripts/` and install to `~/.local/bin`.
- Bash scripts keep `set -euo pipefail`.
- The TUI must not require root to start; privileged actions use existing script behavior or explicit privilege escalation only when the action runs.

### 6.2 Safety Guardrails

- Discovery must not execute arbitrary scripts.
- Critical Actions include package/system updates, bootloader changes, DNS rewrites, PAM changes, generated theme overwrites, power/session actions, destructive Git actions, and commands requiring `sudo`.
- Critical Actions require explicit confirmation.
- Critical Actions should expose Preview or Dry Run as each Tool Brick supports it.
- If no Dry Run exists, the TUI must say so before confirmation.
- Auto-push, destructive Git cleanup, and overwrite operations are disabled by default.

### 6.3 Product Boundaries

- The TUI should orchestrate existing repo-owned scripts and incremental new scripts.
- The TUI should not replace `install.sh`, `arch-menu`, or `theme-switch` wholesale in MVP.
- The TUI should not remove Waybar, alter AGS behavior, or make unrelated desktop architecture changes.
- The TUI should not assume NetworkManager is active.
- The TUI should not make Limine, Howdy, or hardware-specific components mandatory.

## 7. MVP Scope

### 7.1 In Scope

- `scripts/arch-tui` launcher installed as the `arch-tui` command.
- OpenTUI-based local TUI shell.
- Metadata discovery from repo-owned scripts using `arch-tui:*` fields.
- Core Categories: `Setup`, `Maintenance`, `Appearance`, `Desktop`, and `System`.
- Brick detail view with name, summary, command, criticality, and Dry Run availability.
- Execution of metadata-declared commands.
- Visible success, failure, or cancellation result states.
- Critical confirmation.
- Optional Dry Run when metadata provides it.
- First `Maintenance > Global Update` brick with Dry Run/Preview.
- Global Update stages for Pacman update, AUR update, optional repo-owned tooling refresh, optional desktop reload/restart, and final summary.
- Basic README documentation for user-visible command/menu behavior.

### 7.2 Out of Scope for MVP

- Full graphical desktop control center.
- Rewriting all existing scripts into Tool Bricks.
- Replacing `arch-menu` wholesale.
- Full guided first-install wizard with dependency graph and resume state. [NOTE FOR PM: This may become important once multiple fresh machines are managed through the TUI.]
- Git Synchronization implementation; it is product scope for phase 2 after the core TUI shell and Global Update MVP.
- Full secret scanning beyond obvious path/filename safeguards.
- Support for non-Arch systems.
- Plugin system for external or third-party commands.
- Enterprise audit trail, multi-user roles, or remote fleet management.

## 8. Success Metrics

**Primary**
- **SM-1:** The user can run `arch-tui`, browse at least the MVP Categories, inspect Tool Brick details, run at least one safe Tool Brick, and return to the menu with a clear result. Validates FR-1 through FR-10 and FR-26.
- **SM-2:** A valid metadata-backed Tool Brick can be added without modifying core TUI navigation. Validates FR-5 through FR-7.
- **SM-3:** `Maintenance > Global Update` can show a Dry Run/Preview and execute the real update as visible stages with a final summary. Validates FR-18 through FR-21.

**Secondary**
- **SM-4:** Critical Actions cannot run without explicit confirmation and show Dry Run availability or absence before execution. Validates FR-11 through FR-14 and FR-28.
- **SM-5:** Existing direct usage of `arch-menu`, setup scripts, and `theme-switch` continues to work unchanged. Validates FR-8, FR-16, and FR-27.
- **SM-6:** Phase 2 Git Synchronization requirements are implementable as metadata-backed Tool Bricks without introducing unsafe auto-push or destructive defaults. Validates FR-22 through FR-25.

**Counter-metrics (do not optimize)**
- **SM-C1:** Number of exposed Tool Bricks should not be maximized at the cost of safety. A smaller set of well-described, safe Tool Bricks is better than exposing every script.
- **SM-C2:** One-click automation should not be maximized for Critical Actions. Preview, staged execution, and confirmation matter more than speed.
- **SM-C3:** Generic configurability should not be maximized. The product should remain aligned with this personal Arch config.

## 9. Risks and Mitigations

- **Risk:** The TUI hides important command output or fails to recover the terminal. **Mitigation:** require visible output handling and terminal cleanup as core requirements.
- **Risk:** Metadata discovery accidentally exposes unsafe scripts. **Mitigation:** scan only approved repo-owned locations and require explicit metadata with valid categories.
- **Risk:** Critical actions become too easy to trigger. **Mitigation:** metadata-driven criticality, explicit confirmation, and Dry Run/Preview requirements.
- **Risk:** Git sync leaks secrets or overwrites local work. **Mitigation:** status/diff-first workflows, no auto-push by default, suspicious file warnings, and blocked one-click sync in conflict states.
- **Risk:** OpenTUI dependency setup complicates an otherwise simple repo. **Mitigation:** keep the TUI project minimal, document runtime dependencies, and avoid adding broader frameworks.
- **Risk:** The project drifts into a generic installer. **Mitigation:** keep non-Arch and third-party plugin support out of scope.

## 10. Open Questions

1. Should empty Categories be hidden or displayed with empty-state copy?
2. What exact dependency path should OpenTUI use in this repo: Node via `mise`, Bun, Zig, or another minimal setup validated against current OpenTUI requirements?
3. Which Tool Bricks beyond Global Update should ship first: Hypridle toggle, theme switch, DNS setup, config openers, or diagnostics?
4. Should Critical Action confirmation be a simple confirm prompt or typed confirmation for high-risk operations such as reboot, shutdown, bootloader changes, and destructive Git commands?
5. Which files outside the repository, if any, should phase 2 Git Synchronization manage?
6. Should first-install flows remain individual Tool Bricks, or should a later version introduce a guided setup checklist with progress state?

## 11. Source Reconciliation

- Existing SPEC capabilities CAP-1 through CAP-7 are preserved in FR-1 through FR-14, FR-18, and FR-19.
- Existing constraints around Arch-only scope, idempotency, script installation, package ownership, generated theme safety, OpenTUI, explicit metadata discovery, and Global Update placement are preserved in §§4-7.
- The implementation story's acceptance criteria are preserved in MVP Scope and relevant FRs.
- The user's latest clarification expanded the product beyond the MVP into first install, configuration upgrade, maintenance, and Git Synchronization; these are captured as product scope, with Git Synchronization explicitly deferred to phase 2.
- Comparable research reinforced metadata-first discovery, preview-first risky actions, visible terminal execution for package/privileged work, and safe Git sync patterns.

## 12. Assumptions Index

- §4.1 FR-2: Empty Categories may be hidden in MVP if that improves clarity.
- §4.2 FR-6: MVP discovery scans `scripts/` only.
- §4.5 FR-17: First install versus configuration upgrade can initially be distinguished through Category placement and brick summaries instead of a guided wizard.
- §4.7 FR-24: MVP secret protection can use filename/path heuristics and Git status rather than a full secret scanner.
