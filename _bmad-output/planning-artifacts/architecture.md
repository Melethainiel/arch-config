---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
inputDocuments:
  - /home/thibaud/source/repos/personnal/arch-config/_bmad-output/planning-artifacts/prds/prd-arch-config-2026-06-01/prd.md
  - /home/thibaud/source/repos/personnal/arch-config/_bmad-output/project-context.md
workflowType: 'architecture'
lastStep: 8
status: 'complete'
completedAt: '2026-06-01'
project_name: 'arch-config'
user_name: 'Thibaud'
date: '2026-06-01'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements:**

The project defines 28 functional requirements for `arch-tui`, a local terminal command center for this personal Arch Linux configuration repository. Architecturally, the requirements point to a small but safety-sensitive local application rather than a broad platform.

The core functional areas are:

- TUI shell and navigation: provide a normal-user `arch-tui` launcher, render categories, show Tool Brick details, preserve terminal usability, and recover cleanly after exit or failure.
- Metadata-backed Tool Brick discovery: parse explicit `arch-tui:*` metadata from approved repo-owned scripts, avoid arbitrary executable scanning, reject or report invalid metadata, and support incremental brick additions without changing core navigation.
- Command execution and result handling: execute only metadata-declared commands, preserve direct script usage, show success/failure/cancellation, and keep command output visible for privileged, package, update, or failure-prone operations.
- Critical action safety: mark critical actions from metadata, require explicit confirmation, expose dry-run/preview when provided, and clearly state when no dry-run exists.
- First install and configuration upgrade: expose setup and upgrade actions while preserving existing idempotent script behavior, hardware guards, generated theme safety, and machine-specific optionality.
- Maintenance and Global Update: provide a critical metadata-backed Global Update brick with dry-run/preview, visible stages, Pacman/AUR separation, optional repo-owned tooling refresh, optional desktop reload/restart, and final summaries.
- Git Synchronization: deferred beyond MVP, but architecturally important because future sync flows must be status/diff-first, split pull/stage/commit/push, protect secret-like files and generated artifacts, and block unsafe one-click sync states.
- Appearance, Desktop, and System actions: expose daily commands while preserving theme safety and requiring confirmation for power/session actions.

These requirements imply an architecture with a small number of clear components: launcher, TUI shell, metadata discovery/parser, metadata validation, category/brick model, command runner, dry-run/preview runner, confirmation/safety gate, output/result handling, and Global Update Tool Brick support.

**Non-Functional Requirements:**

The main NFRs are safety, repository fit, idempotency, discoverability, transparency, extensibility, dependency discipline, terminal recovery, and generated artifact protection.

Safety is the dominant architectural driver. The TUI must not weaken existing script-level confirmations or turn critical operations into accidental one-key actions. Discovery must not execute scripts. Critical actions must be metadata-driven, visible, previewable where possible, and explicitly confirmed.

Idempotency and repository fit are also central. The project is a personal reproducible Arch config, not a generic installer. Setup and maintenance flows should orchestrate existing repo-owned scripts and preserve their safeguards rather than replacing them wholesale.

Transparency affects command execution architecture. Long-running, privileged, package, Git, and destructive operations need visible output or reviewable summaries. The TUI must not hide important output behind a spinner or leave the terminal in a broken state.

Dependency discipline matters because OpenTUI may require a TypeScript/Node project layout. Any implementation should keep the TUI project minimal, use existing `mise`/Node conventions where appropriate, and avoid adding broad frameworks.

Generated artifact protection is required for AGS type artifacts, `node_modules`, generated theme files, and user-applied config. Future Git sync and current command execution must not silently commit, overwrite, or remove those artifacts.

**Scale & Complexity:**

- Primary domain: local terminal application for Arch Linux script orchestration
- Complexity level: medium
- Estimated architectural components: 8-10

The project is not high-scale in terms of users, data volume, multi-tenancy, or distributed systems. Its complexity comes from operational risk, live-system side effects, metadata correctness, terminal behavior, and preserving existing repository conventions.

There are no regulatory compliance, multi-tenant, remote fleet, or enterprise audit requirements. There are no real-time collaboration requirements. User interaction complexity is moderate because the TUI must support navigation, detail views, dry-run/preview flows, confirmation gates, command execution, visible output, and result states.

### Technical Constraints & Dependencies

Known constraints and dependencies:

- Target OS is Arch Linux only.
- `arch-tui` must launch as a normal user and must not require the whole process to run under `sudo`.
- OpenTUI is the intended TUI framework.
- If OpenTUI requires a TypeScript/Node project layout, implementation code should live under `dotfiles/arch-tui/`.
- User-executable launchers and helper scripts belong in `scripts/` and install to `~/.local/bin`.
- Bash scripts must keep `set -euo pipefail`.
- Tool Brick discovery should scan approved repo-owned locations only, with MVP discovery assumed to scan `scripts/`.
- Discovery must parse metadata without executing scripts.
- Required MVP metadata keys are `id`, `category`, `name`, `summary`, `command`, and `critical`; optional MVP key is `dry-run`.
- MVP categories are `Setup`, `Maintenance`, `Appearance`, `Desktop`, and `System`, represented by stable lowercase metadata values.
- Package ownership boundaries must remain separated between Pacman package lists and `packages/aur.txt`.
- The repository uses `iwd + impala`, not NetworkManager assumptions.
- Hyprland config is Lua-based and generated theme loading must remain last.
- AGS is `aylurs-gtk-shell-git`, and generated AGS type artifacts must remain untracked.
- Waybar remains installed as fallback.
- Limine, Howdy, DNS, PAM, hardware-specific setup, generated theme overwrite, and power/session commands must remain guarded and optional where relevant.
- Git Synchronization is out of MVP scope but must remain architecturally feasible without unsafe auto-push or destructive defaults.

### Cross-Cutting Concerns Identified

The major cross-cutting concerns are:

- Safety gating: criticality, explicit confirmation, dry-run/preview availability, and visible warnings must apply across setup, maintenance, desktop, system, appearance, and future Git actions.
- Metadata validation: the metadata contract affects discovery, categorization, command execution, criticality, dry-run routing, and extensibility.
- Command execution transparency: output visibility, exit state capture, cancellation handling, and terminal recovery affect every executable Tool Brick.
- Idempotency preservation: setup, upgrade, maintenance, and theme actions must preserve existing script safeguards and rerun safety.
- Dependency minimalism: OpenTUI and any Node/TypeScript setup must be introduced narrowly and documented without turning the repo into a generic app framework.
- Repository ownership boundaries: discovery, generated artifact protection, package source separation, and future Git sync must respect what the repo owns versus local/generated/user-specific files.
- Deferred Git safety: phase 2 sync requires status/diff-first flows, secret-like path safeguards, no auto-push by default, and conflict/destructive-state blocking.
- Arch-specific assumptions: the system can assume Arch Linux but must not assume NetworkManager, mandatory hardware support, or a uniform bootloader/session state.

## Starter Template Evaluation

### Primary Technology Domain

Local CLI/TUI application based on project requirements analysis.

The product is not a web app, mobile app, API backend, full-stack app, or desktop GUI. It is a local terminal application that orchestrates repo-owned Arch Linux scripts through a safety-sensitive TUI.

### Starter Options Considered

**OpenTUI minimal TypeScript project**

OpenTUI is the intended TUI framework in the PRD. Current package metadata identifies `@opentui/core` version `0.3.1` as a TypeScript library backed by a native Zig core for terminal UIs.

This option does not appear to provide a broadly established scaffold command comparable to `create-ink-app`, so the correct foundation is a minimal manually-created project under `dotfiles/arch-tui/`.

Architectural fit:

- Best alignment with PRD constraint that OpenTUI is the intended framework.
- Fits the repo rule to avoid broad frameworks and keep the project small.
- Allows explicit separation between TUI UI code, metadata discovery, safety gating, and command execution.
- Requires us to define project structure ourselves, which is acceptable because the desired architecture is small and repo-specific.

**Ink / create-ink-app**

Ink is current at version `7.0.5`, and `create-ink-app` is current at version `3.0.2`. Ink has a mature starter path and strong React-style CLI ergonomics.

Architectural fit:

- Strong CLI/TUI ecosystem and scaffolding.
- Would introduce a React renderer and move away from the PRD's OpenTUI direction.
- More generic than needed for this repo.
- Not selected because it contradicts the stated OpenTUI preference.

**react-blessed**

`react-blessed` is current at version `0.7.2`.

Architectural fit:

- Provides a React renderer over blessed.
- Older and less aligned with the PRD than OpenTUI.
- Not selected because it adds a different TUI stack without a project-specific reason.

### Selected Starter: Manual Minimal OpenTUI TypeScript Project

**Rationale for Selection:**

A manually-created OpenTUI TypeScript project is the best fit because the architecture needs to be small, explicit, and aligned with the PRD rather than generated from a generic app starter. The repository already has Node available through `mise`, and the PRD explicitly directs implementation code to `dotfiles/arch-tui/` if OpenTUI requires a TypeScript/Node project layout.

This selection preserves the repository's minimalism while still giving the TUI a proper isolated project boundary.

**Initialization Command:**

There is no selected external scaffold command. The first implementation story should create the minimal project structure directly:

```bash
mkdir -p dotfiles/arch-tui/src
cd dotfiles/arch-tui
npm init -y
npm install @opentui/core
npm install --save-dev typescript
```

Exact package-manager choice and lockfile handling should be confirmed during implementation based on the repository's Node conventions.

**Architectural Decisions Provided by Starter:**

**Language & Runtime:**

TypeScript running on Node.js, with Node supplied through the repository's existing `mise` baseline.

**Styling Solution:**

No separate styling framework. Terminal layout and colors should use OpenTUI primitives directly. Any visual constants should remain local to the TUI code unless reuse becomes necessary.

**Build Tooling:**

Minimal TypeScript build configuration local to `dotfiles/arch-tui/`. The TUI launcher in `scripts/arch-tui` should execute the built entrypoint or a documented development entrypoint.

**Testing Framework:**

No test framework is selected by the starter. Validation should begin with TypeScript checks and targeted shell syntax checks for launchers/scripts. A test framework can be added later only if concrete TUI logic needs automated coverage.

**Code Organization:**

Recommended initial structure:

- `dotfiles/arch-tui/src/main.ts`: TUI entrypoint
- `dotfiles/arch-tui/src/discovery.ts`: metadata scanning and parsing
- `dotfiles/arch-tui/src/model.ts`: Tool Brick and category types
- `dotfiles/arch-tui/src/validation.ts`: metadata validation and duplicate/category checks
- `dotfiles/arch-tui/src/executor.ts`: command and dry-run execution
- `dotfiles/arch-tui/src/safety.ts`: critical-action confirmation policy
- `dotfiles/arch-tui/src/ui.ts`: OpenTUI rendering/navigation

This structure should stay flexible. Implementation should not create abstractions before the MVP needs them.

**Development Experience:**

The project should keep local TypeScript configuration and package metadata under `dotfiles/arch-tui/`. Generated dependency artifacts such as `node_modules` must remain untracked. The root installer should install `scripts/arch-tui` through the existing script installation path.

**Note:** Project initialization using this structure should be the first implementation story.

## Core Architectural Decisions

### Decision Priority Analysis

**Critical Decisions (Block Implementation):**

- Use a local TypeScript/Node TUI architecture with OpenTUI, implemented under `dotfiles/arch-tui/`.
- Use no database and no persisted application state for MVP.
- Discover Tool Bricks only through explicit metadata in approved repo-owned scripts.
- Treat metadata validation as a first-class architectural boundary.
- Execute only metadata-declared commands; never infer commands from filenames.
- Gate critical actions through metadata-driven confirmation and dry-run/preview routing.
- Keep command output visible and preserve terminal recovery.
- Install the user-facing launcher through `scripts/arch-tui` and the existing script installation path.

**Important Decisions (Shape Architecture):**

- Keep the metadata discovery surface to `scripts/` for MVP.
- Keep the TUI project self-contained under `dotfiles/arch-tui/`.
- Keep TypeScript strict enough to catch model/metadata errors before runtime.
- Keep UI, discovery, validation, execution, and safety policy separated as modules.
- Treat Global Update as a Tool Brick workflow rather than hardcoding update behavior into the TUI shell.
- Keep package ownership boundaries visible between Pacman and AUR.

**Deferred Decisions (Post-MVP):**

- Git Synchronization implementation is deferred to phase 2.
- Full guided first-install checklist/resume state is deferred.
- Secret scanning beyond path/filename heuristics is deferred.
- A dedicated automated test framework is deferred until concrete TUI logic justifies it.
- Broader discovery paths or plugin systems are deferred and not part of MVP.

### Data Architecture

The MVP will use no database and no durable app-level state.

Tool Bricks are discovered at runtime from script metadata. The TUI can keep transient in-memory state for the current navigation selection, selected Tool Brick, dry-run result, command result, and confirmation flow.

Rationale:

- The PRD does not require saved preferences, user accounts, history, or multi-machine state.
- Runtime discovery keeps the TUI aligned with the current repository checkout.
- Avoiding persistence reduces accidental stale metadata, migration needs, and state corruption.
- A future guided install checklist could add persisted progress later, but that is explicitly out of MVP scope.

### Authentication & Security

The TUI has no login/authentication layer because it is a local user command for a personal machine.

Security is handled through execution safety:

- The TUI must not run as root.
- Privileged operations occur only inside selected Tool Brick commands, using existing script behavior or explicit privilege escalation.
- Criticality is declared through metadata using `critical=true`.
- Critical actions require explicit confirmation before real execution.
- Dry-run/preview is offered when the Tool Brick provides `dry-run`.
- If no dry-run exists, the TUI must state that before confirmation.
- Script-level confirmations, such as generated theme overwrite prompts, must remain intact.
- Discovery must parse metadata without executing scripts.
- Invalid or duplicate metadata must not crash the TUI or expose unsafe actions silently.

### API & Communication Patterns

There is no network API in MVP.

The main communication boundary is local process execution:

- Discovery reads repo-owned script files.
- Execution runs metadata-declared shell commands as child processes.
- Dry-run runs metadata-declared dry-run commands as child processes.
- Results are normalized into success, failure, skipped, or cancellation states.
- Output must remain visible for long-running, privileged, package, update, Git, or failure-prone operations.
- Commands should be treated as shell-level operations with clear boundaries, not as hidden internal callbacks.

Error handling standards:

- Metadata errors are discovery/validation errors.
- Command non-zero exits are execution failures.
- User cancellation is distinct from command failure when supported.
- Missing dependencies should produce clear setup/dependency messages rather than crashing.

### Frontend Architecture

The TUI is the frontend.

Architecture should separate UI rendering from operational logic:

- `main.ts`: entrypoint and app startup.
- `ui.ts`: OpenTUI rendering and navigation.
- `model.ts`: category and Tool Brick types.
- `discovery.ts`: script scanning and metadata parsing.
- `validation.ts`: required fields, categories, duplicate IDs, boolean parsing.
- `safety.ts`: critical-action warnings and confirmation policy.
- `executor.ts`: command/dry-run process execution and result mapping.

The UI should not own command execution rules. It should call discovery, validation, safety, and execution modules through explicit interfaces. This keeps future AI agents from mixing rendering code with operational side effects.

### Infrastructure & Deployment

There is no cloud hosting or deployment pipeline.

Installation/deployment is local:

- `scripts/arch-tui` is the user-facing launcher.
- The root installer should install it into `~/.local/bin` through the existing script installation path.
- TypeScript/OpenTUI project files live under `dotfiles/arch-tui/`.
- `node_modules` and generated local artifacts must remain untracked.
- The implementation should document how the launcher reaches the built or development TUI entrypoint.
- Validation starts with TypeScript checks and Bash syntax checks for shell launchers.

### Decision Impact Analysis

**Implementation Sequence:**

1. Create minimal `dotfiles/arch-tui/` TypeScript/OpenTUI project.
2. Add `scripts/arch-tui` launcher and ensure existing installation path handles it.
3. Define Tool Brick model and metadata contract.
4. Implement script discovery and metadata parsing from `scripts/`.
5. Implement metadata validation and invalid/duplicate reporting.
6. Implement TUI category and detail views.
7. Implement dry-run and command execution with visible output/result states.
8. Implement critical-action confirmation flow.
9. Add `Maintenance > Global Update` Tool Brick metadata and staged workflow.
10. Document usage and dependency setup.

**Cross-Component Dependencies:**

- UI depends on validated Tool Brick models, not raw parsed metadata.
- Execution depends on metadata validation so invalid commands are not runnable.
- Safety gating depends on metadata criticality and dry-run availability.
- Global Update depends on both metadata discovery and command execution behavior.
- Future Git Synchronization depends on the same safety, preview, and output visibility patterns.

## Implementation Patterns & Consistency Rules

### Pattern Categories Defined

**Critical Conflict Points Identified:**

8 areas where AI agents could make different choices:

- Tool Brick metadata field names and parsing rules
- Category and Tool Brick ID naming
- TypeScript module/file organization
- Validation error representation
- Command execution result representation
- Critical-action confirmation flow
- UI state naming and navigation states
- Generated/local artifact handling

### Naming Patterns

**Database Naming Conventions:**

No database is used in MVP. Agents must not introduce tables, migrations, ORM models, or persisted app state unless a later architecture update explicitly adds persistence.

**API Naming Conventions:**

No network API is used in MVP. Agents must not introduce REST, GraphQL, RPC, HTTP servers, or API route structures for the TUI.

Local command communication uses Tool Brick metadata and child-process execution only.

**Code Naming Conventions:**

TypeScript code uses:

- kebab-case file names only if the file represents a standalone executable or config-adjacent artifact.
- lower camelCase for functions and variables.
- PascalCase for TypeScript types/interfaces only when they represent domain models.
- lowercase stable category IDs in metadata.
- kebab-case Tool Brick IDs.

Examples:

```ts
type ToolBrick = {
  id: string;
  category: ToolBrickCategory;
  name: string;
  summary: string;
  command: string;
  critical: boolean;
  dryRun?: string;
};

function discoverToolBricks(): DiscoveryResult {
  // ...
}
```

Metadata examples:

```bash
# arch-tui:id=global-update
# arch-tui:category=maintenance
# arch-tui:name=Global Update
# arch-tui:summary=Update Pacman and AUR packages with visible stages.
# arch-tui:command=scripts/global-update
# arch-tui:dry-run=scripts/global-update --dry-run
# arch-tui:critical=true
```

Allowed MVP category IDs:

- `setup`
- `maintenance`
- `appearance`
- `desktop`
- `system`

Agents must not invent new categories without updating the architecture or validation rules.

### Structure Patterns

**Project Organization:**

The TUI project lives under `dotfiles/arch-tui/`.

Initial source organization:

- `src/main.ts`: startup and top-level wiring only.
- `src/model.ts`: shared domain types and constants.
- `src/discovery.ts`: file scanning and metadata parsing.
- `src/validation.ts`: metadata validation and duplicate/category checks.
- `src/executor.ts`: dry-run and command execution.
- `src/safety.ts`: critical-action policy and confirmation rules.
- `src/ui.ts`: OpenTUI rendering and navigation.

Agents must not put command execution, script scanning, or metadata validation directly inside UI rendering code.

**File Structure Patterns:**

- Launcher script: `scripts/arch-tui`.
- TUI source: `dotfiles/arch-tui/src/`.
- TUI package metadata: `dotfiles/arch-tui/package.json`.
- TUI TypeScript config: `dotfiles/arch-tui/tsconfig.json`.
- Generated dependencies: `dotfiles/arch-tui/node_modules/`, untracked.
- Build output location should be local to `dotfiles/arch-tui/` and documented if introduced.

Tool Brick scripts remain in `scripts/` for MVP discovery. A script is not exposed just because it is executable; it must include valid metadata.

### Format Patterns

**API Response Formats:**

No API response format exists for MVP.

Internal result objects should use discriminated unions rather than loosely shaped objects.

Example:

```ts
type ExecutionResult =
  | { kind: "success"; command: string; exitCode: 0 }
  | { kind: "failure"; command: string; exitCode: number; message?: string }
  | { kind: "cancelled"; command: string };
```

**Data Exchange Formats:**

Metadata format is line-oriented script comments:

```text
arch-tui:<key>=<value>
```

Parsing rules:

- Only leading comment metadata is parsed.
- Discovery must not execute scripts.
- Required keys: `id`, `category`, `name`, `summary`, `command`, `critical`.
- Optional key: `dry-run`.
- `critical` accepts only `true` or `false`.
- Unknown keys should be reported as warnings or ignored consistently, but must not make the script runnable if required keys are missing.
- Duplicate IDs must be validation errors.
- Invalid categories must be validation errors.
- Missing required fields must be validation errors.

Validation result shape should distinguish valid Tool Bricks from metadata problems:

```ts
type ValidationIssue = {
  file: string;
  kind: "missing-field" | "invalid-category" | "duplicate-id" | "invalid-boolean";
  message: string;
};
```

### Communication Patterns

**Event System Patterns:**

No event bus is used in MVP. Agents must not introduce event emitters or pub/sub unless a later implementation need proves it necessary.

UI actions should call explicit functions:

- discovery function loads Tool Bricks.
- validation function validates parsed metadata.
- safety function determines confirmation requirements.
- executor function runs dry-run or real command.

**State Management Patterns:**

No external state management library is used.

UI state should remain local and explicit:

- current category
- selected Tool Brick
- current view
- validation issues
- last dry-run result
- last execution result
- confirmation pending state

State names should describe workflow state, not implementation mechanics.

Recommended view state values:

```ts
type ViewState =
  | "category-list"
  | "brick-list"
  | "brick-detail"
  | "dry-run-result"
  | "confirm-run"
  | "execution-result"
  | "validation-issues";
```

### Process Patterns

**Error Handling Patterns:**

Errors are grouped by boundary:

- Discovery errors: file read/access problems.
- Metadata validation errors: missing fields, invalid category, duplicate ID, invalid boolean.
- Dependency errors: missing Node/OpenTUI/runtime command dependencies.
- Execution errors: non-zero exit code or child process failure.
- User cancellation: explicit cancellation, not command failure.

Agents must not collapse these into a single generic error string.

User-facing errors should be clear and operational:

```text
Invalid Tool Brick metadata in scripts/foo: missing required field "command".
```

Execution failures should include the command and exit code where available.

**Loading State Patterns:**

The MVP should avoid elaborate loading abstractions. Operations are local and command-oriented.

If a long-running command executes, output visibility matters more than spinner polish. The user should be able to see package/update/sudo output during or after execution.

### Enforcement Guidelines

**All AI Agents MUST:**

- Parse Tool Brick metadata without executing scripts.
- Use the shared `ToolBrick` model rather than ad hoc objects.
- Validate metadata before exposing a Tool Brick in the UI.
- Keep UI rendering separate from discovery, validation, safety, and execution.
- Keep critical-action confirmation metadata-driven.
- Preserve existing script-level confirmations.
- Keep generated dependency artifacts untracked.
- Avoid introducing persistence, APIs, auth, event buses, or plugin systems in MVP.

**Pattern Enforcement:**

- TypeScript type checks should catch model drift.
- Validation logic should reject invalid categories, duplicate IDs, missing required fields, and invalid booleans.
- Shell launchers should be checked with `bash -n`.
- Any new Tool Brick should include metadata examples matching this document.
- Pattern changes should be made in the architecture document before implementation diverges.

### Pattern Examples

**Good Examples:**

Metadata-driven discovery:

```bash
# arch-tui:id=hypridle-toggle
# arch-tui:category=desktop
# arch-tui:name=Toggle Hypridle
# arch-tui:summary=Toggle the Hypridle idle daemon for the current session.
# arch-tui:command=scripts/hypridle-toggle
# arch-tui:critical=false
```

Critical action with dry-run:

```bash
# arch-tui:id=global-update
# arch-tui:category=maintenance
# arch-tui:name=Global Update
# arch-tui:summary=Update Pacman and AUR packages with visible stages.
# arch-tui:command=scripts/global-update
# arch-tui:dry-run=scripts/global-update --dry-run
# arch-tui:critical=true
```

Clear separation:

```ts
const discovery = discoverToolBricks({ directory: "scripts" });
const validation = validateToolBricks(discovery.bricks);

if (validation.valid.length === 0) {
  showValidationIssues(validation.issues);
}
```

**Anti-Patterns:**

Do not expose every executable script automatically:

```ts
// Wrong: executable does not mean safe or intended for TUI.
scanEveryExecutableOnPath();
```

Do not execute scripts during discovery:

```ts
// Wrong: discovery must be non-mutating.
execSync(`${script} --describe`);
```

Do not hardcode criticality in UI labels only:

```ts
// Wrong: safety must come from validated metadata.
const isCritical = brick.name.includes("Update");
```

Do not bypass existing confirmations:

```ts
// Wrong: TUI must not weaken script-level safety.
runCommandWithAutoYes(brick.command);
```

Do not introduce persistence for MVP navigation:

```ts
// Wrong for MVP unless architecture changes.
saveCurrentViewToDatabase();
```

## Project Structure & Boundaries

### Complete Project Directory Structure

```text
arch-config/
├── install.sh
├── README.md
├── packages/
│   ├── core.txt
│   ├── desktop.txt
│   ├── dev.txt
│   ├── gaming.txt
│   └── aur.txt
├── scripts/
│   ├── arch-tui
│   ├── global-update
│   └── ...
├── dotfiles/
│   ├── arch-tui/
│   │   ├── package.json
│   │   ├── package-lock.json
│   │   ├── tsconfig.json
│   │   ├── src/
│   │   │   ├── main.ts
│   │   │   ├── model.ts
│   │   │   ├── discovery.ts
│   │   │   ├── validation.ts
│   │   │   ├── executor.ts
│   │   │   ├── safety.ts
│   │   │   └── ui.ts
│   │   └── dist/
│   │       └── ...
│   ├── ags/
│   ├── hypr/
│   └── ...
└── _bmad-output/
    └── planning-artifacts/
        └── architecture.md
```

Notes:

- `dotfiles/arch-tui/node_modules/` is intentionally omitted because it must remain untracked.
- `dotfiles/arch-tui/dist/` is optional if the implementation chooses a build output; if introduced, it must be documented.
- `scripts/global-update` represents the MVP Global Update Tool Brick script. The exact script name can be adjusted during implementation, but its metadata and category mapping must follow this architecture.

### Architectural Boundaries

**API Boundaries:**

No network API exists in MVP.

The key boundary is local command execution:

- Input boundary: script metadata read from `scripts/`.
- Validation boundary: parsed metadata becomes validated `ToolBrick` models.
- Execution boundary: validated metadata commands become child-process executions.
- UI boundary: UI renders categories, details, validation issues, confirmations, and results, but does not decide command semantics.

**Component Boundaries:**

`src/main.ts`

- Starts the application.
- Wires discovery, validation, UI, safety, and execution.
- Should not contain metadata parsing details or command execution logic.

`src/model.ts`

- Owns domain types and constants.
- Defines `ToolBrick`, `ToolBrickCategory`, validation issue types, execution result types, and view state types.
- Other modules import shared types from here instead of redefining shapes.

`src/discovery.ts`

- Scans approved script locations.
- Reads files.
- Parses leading `arch-tui:*` metadata.
- Does not execute scripts.
- Does not decide whether a parsed script is valid enough to expose.

`src/validation.ts`

- Validates required metadata fields.
- Validates category IDs.
- Validates `critical` booleans.
- Detects duplicate IDs.
- Produces valid Tool Bricks plus validation issues.

`src/safety.ts`

- Encodes critical-action policy.
- Determines whether confirmation is required.
- Determines whether dry-run/preview should be offered.
- Does not execute commands.

`src/executor.ts`

- Runs dry-run or real commands.
- Captures exit status and maps it to execution result types.
- Keeps output visible according to the TUI strategy.
- Does not decide which commands are safe; it executes already-approved requests.

`src/ui.ts`

- Owns OpenTUI rendering and navigation.
- Displays categories, Tool Brick lists, detail views, dry-run results, confirmation prompts, validation issues, and execution results.
- Calls safety/executor functions rather than embedding policy or process execution.

**Service Boundaries:**

The project does not use backend services.

Internal services are plain TypeScript modules with explicit function calls. Agents should not introduce service classes, dependency-injection containers, or event buses for MVP.

**Data Boundaries:**

No database or persistent app state exists.

Data flows through these forms:

- Raw script file contents.
- Parsed metadata records.
- Validated `ToolBrick` models.
- UI state.
- Execution results.

Generated/local artifacts such as `node_modules`, AGS type artifacts, and generated theme files are outside the TUI data model and must not be managed or committed by the TUI.

### Requirements to Structure Mapping

**Feature/Epic Mapping:**

TUI Shell and Navigation, FR-1 to FR-4:

- `scripts/arch-tui`: user-facing launcher.
- `dotfiles/arch-tui/src/main.ts`: application startup.
- `dotfiles/arch-tui/src/ui.ts`: categories, navigation, detail views, terminal recovery behavior.

Metadata-Backed Tool Brick Discovery, FR-5 to FR-7:

- `dotfiles/arch-tui/src/discovery.ts`: scanning and parsing.
- `dotfiles/arch-tui/src/validation.ts`: required fields, allowed categories, duplicates.
- `dotfiles/arch-tui/src/model.ts`: metadata and Tool Brick types.
- `scripts/*`: Tool Brick metadata comments.

Command Execution and Result Handling, FR-8 to FR-10:

- `dotfiles/arch-tui/src/executor.ts`: child process execution and result mapping.
- `dotfiles/arch-tui/src/ui.ts`: output/result display.
- `dotfiles/arch-tui/src/model.ts`: execution result types.

Critical Action Safety, Preview, and Dry Run, FR-11 to FR-14:

- `dotfiles/arch-tui/src/safety.ts`: critical confirmation and dry-run policy.
- `dotfiles/arch-tui/src/ui.ts`: warning, dry-run option, confirmation prompt.
- `dotfiles/arch-tui/src/executor.ts`: dry-run command execution.
- `scripts/*`: `critical` and `dry-run` metadata fields.

First Install and Configuration Upgrade, FR-15 to FR-17:

- `scripts/*`: setup/upgrade Tool Brick scripts and metadata.
- `dotfiles/arch-tui/src/validation.ts`: setup category validation.
- `dotfiles/arch-tui/src/ui.ts`: setup category display and summaries.

Maintenance and Global Update, FR-18 to FR-21:

- `scripts/global-update`: staged update workflow and dry-run support.
- `dotfiles/arch-tui/src/discovery.ts`: metadata discovery.
- `dotfiles/arch-tui/src/executor.ts`: run/dry-run execution.
- `dotfiles/arch-tui/src/ui.ts`: maintenance category and result summary display.

Git Synchronization, FR-22 to FR-25:

- Deferred for phase 2.
- Future implementation should add Git Tool Bricks under `scripts/`.
- Future logic must reuse `safety.ts`, `executor.ts`, validation patterns, and output visibility patterns.
- No phase 2 Git sync files should be added for MVP unless implementation scope changes.

Appearance, Desktop, and System Actions, FR-26 to FR-28:

- `scripts/*`: metadata-backed Tool Bricks for theme, Hypridle, reload, lock, suspend, reboot, shutdown, etc.
- `dotfiles/arch-tui/src/safety.ts`: critical policy for power/session actions.
- `dotfiles/arch-tui/src/ui.ts`: category display, confirmation, result display.

**Cross-Cutting Concerns:**

Safety:

- `src/safety.ts`
- `src/validation.ts`
- `src/ui.ts`
- Script-level prompts in existing scripts

Idempotency:

- Existing scripts under `scripts/` and setup behavior in `install.sh`
- TUI must not remove existing checks or prompts

Generated Artifact Protection:

- `.gitignore` patterns if needed
- `dotfiles/arch-tui/node_modules/`
- `dotfiles/ags/@girs`
- `dotfiles/ags/node_modules`
- generated theme files

Dependency Discipline:

- `dotfiles/arch-tui/package.json`
- `dotfiles/arch-tui/package-lock.json`
- `README.md`
- package lists only if additional system dependencies are required

### Integration Points

**Internal Communication:**

Internal modules communicate through typed function calls and shared domain types.

Expected flow:

```text
main.ts
  -> discovery.ts reads scripts
  -> validation.ts validates parsed metadata
  -> ui.ts renders valid bricks and issues
  -> safety.ts evaluates critical actions
  -> executor.ts runs dry-run or command
  -> ui.ts displays result
```

**External Integrations:**

External integrations are local tools invoked by Tool Brick commands:

- Pacman via update scripts.
- `yay` for AUR updates when available.
- Existing repo scripts such as `theme-switch`, Hypridle toggles, desktop reload helpers, or setup scripts.
- Git only in phase 2.
- No remote service integration in MVP.

**Data Flow:**

```text
scripts/* metadata
  -> parsed metadata
  -> validation result
  -> ToolBrick[]
  -> TUI category/detail views
  -> safety decision
  -> dry-run or command execution
  -> execution result
  -> user-visible summary/output
```

The TUI should not mutate metadata during runtime. Tool Brick definitions are changed by editing repo scripts.

### File Organization Patterns

**Configuration Files:**

- `dotfiles/arch-tui/package.json`: package scripts and dependencies.
- `dotfiles/arch-tui/package-lock.json`: locked Node dependency graph if npm is used.
- `dotfiles/arch-tui/tsconfig.json`: TypeScript configuration.
- Root-level config should not be added for the TUI unless needed by the existing repo.

**Source Organization:**

Source code stays flat under `dotfiles/arch-tui/src/` for MVP. Do not create nested feature directories until the codebase actually needs them.

**Test Organization:**

No dedicated automated test framework is selected for MVP.

If tests are introduced later:

- Prefer colocated `*.test.ts` files for pure logic modules such as `discovery.ts` and `validation.ts`.
- Avoid testing live system effects directly.
- Keep shell validation with `bash -n scripts/arch-tui scripts/global-update`.

**Asset Organization:**

No static assets are required for MVP.

Terminal colors, labels, and layout constants should stay in `ui.ts` or a small local helper only if reuse becomes necessary.

### Development Workflow Integration

**Development Server Structure:**

There is no web development server.

Local development happens inside `dotfiles/arch-tui/` using package scripts such as TypeScript check/build commands. Exact scripts should be defined during implementation.

**Build Process Structure:**

The TUI may either run through a TypeScript-compatible runtime strategy or build to local JavaScript output. If build output is introduced, it should remain under `dotfiles/arch-tui/dist/`.

The launcher `scripts/arch-tui` must document or encode how it invokes the TUI entrypoint.

**Deployment Structure:**

Deployment is local installation:

- Root installer installs `scripts/arch-tui` to `~/.local/bin`.
- Node dependencies for `dotfiles/arch-tui/` must be documented.
- The TUI must launch as a normal user.
- Privileged actions remain inside selected Tool Brick commands.

## Architecture Validation Results

### Coherence Validation ✅

**Decision Compatibility:**

The architectural decisions are compatible and reinforce each other.

The selected stack is a local TypeScript/Node TUI using OpenTUI under `dotfiles/arch-tui/`, launched through `scripts/arch-tui`. This aligns with the PRD's OpenTUI direction, the repository's existing Node availability through `mise`, and the project-context rule to keep the repository small and explicit.

The decision to use no database and no persisted app state is compatible with runtime metadata discovery and a personal local TUI. It avoids unnecessary migrations, stale state, and persistence concerns while leaving room for future persisted guided setup state if that becomes a later requirement.

The metadata-first Tool Brick model supports the safety, extensibility, and discoverability requirements. Discovery, validation, safety, execution, and UI are separated into modules, which prevents UI code from owning operational policy or side effects.

No contradictory decisions were found.

**Pattern Consistency:**

The implementation patterns support the architectural decisions.

Naming conventions use lowercase metadata category IDs, kebab-case Tool Brick IDs, and TypeScript model types for shared structures. This matches the metadata contract and validation approach.

The communication pattern is coherent: there is no network API, no event bus, and no state management library. Internal modules communicate through explicit function calls and shared domain types.

The error-handling pattern maps directly to the architecture boundaries: discovery errors, validation errors, dependency errors, execution errors, and user cancellation are separate categories.

**Structure Alignment:**

The project structure supports the architecture.

`dotfiles/arch-tui/src/` contains the local TUI implementation. `scripts/arch-tui` is the user-facing launcher. `scripts/*` remains the MVP discovery surface for Tool Bricks.

Each major FR category maps to a concrete module or script location. Integration points are local and explicit: metadata read from scripts, validation into Tool Brick models, safety checks, child-process execution, and UI result display.

### Requirements Coverage Validation ✅

**Epic/Feature Coverage:**

No separate epics were loaded, so validation is based on PRD feature groups and FRs.

All PRD feature groups are architecturally supported:

- TUI Shell and Navigation: supported by `scripts/arch-tui`, `main.ts`, and `ui.ts`.
- Metadata-Backed Tool Brick Discovery: supported by `discovery.ts`, `validation.ts`, and `model.ts`.
- Command Execution and Result Handling: supported by `executor.ts`, `ui.ts`, and execution result types.
- Critical Action Safety, Preview, and Dry Run: supported by `safety.ts`, metadata fields, `executor.ts`, and UI confirmation flows.
- First Install and Configuration Upgrade: supported through metadata-backed setup Tool Bricks under `scripts/`.
- Maintenance and Global Update: supported by the planned `scripts/global-update` Tool Brick and the same discovery/execution model.
- Git Synchronization and File Safety: explicitly deferred to phase 2, with architectural constraints preserved.
- Appearance, Desktop, and System Actions: supported through metadata-backed Tool Bricks and safety policy.

**Functional Requirements Coverage:**

All 28 FRs are architecturally supported or explicitly deferred where the PRD defers implementation.

FR-1 to FR-4 are covered by launcher, startup, UI navigation, and terminal recovery requirements.

FR-5 to FR-7 are covered by metadata parsing, validation, duplicate/category checks, and script-only discovery.

FR-8 to FR-10 are covered by metadata-declared command execution and visible result/output handling.

FR-11 to FR-14 are covered by metadata-driven criticality, confirmation policy, dry-run routing, and missing dry-run messaging.

FR-15 to FR-17 are covered by Setup category Tool Bricks and preservation of existing script idempotency.

FR-18 to FR-21 are covered by the Global Update Tool Brick architecture and staged execution model.

FR-22 to FR-25 are deferred for phase 2 but architecturally constrained by safety, preview-first behavior, and no unsafe auto-push/destructive defaults.

FR-26 to FR-28 are covered by metadata-backed daily actions and critical policy for power/session commands.

**Non-Functional Requirements Coverage:**

Safety is addressed through metadata validation, critical-action confirmation, dry-run/preview routing, and preservation of script-level prompts.

Repository fit is addressed by keeping the tool personal, Arch-only, repo-owned, and minimal.

Idempotency is addressed by keeping setup and maintenance behavior in existing or focused scripts rather than rewriting install logic inside UI code.

Discoverability is addressed by category navigation, Tool Brick metadata, summaries, and detail views.

Transparency is addressed by visible command output and normalized result states.

Extensibility is addressed by metadata-backed Tool Brick addition without core navigation rewrites.

Dependency discipline is addressed by isolating Node/OpenTUI code under `dotfiles/arch-tui/`.

Terminal recovery is identified as a core UI/execution responsibility.

Generated artifact protection is addressed through untracked dependency artifacts and explicit boundaries around generated AGS/theme files.

### Implementation Readiness Validation ✅

**Decision Completeness:**

Critical decisions are documented, including the selected TUI framework, project location, launcher location, metadata discovery surface, no-persistence decision, command execution boundary, safety gating, and phase 2 Git deferral.

Current package versions were verified for key technologies:

- `@opentui/core@0.3.1`
- `typescript@6.0.3`
- local Node `v24.15.0`

**Structure Completeness:**

The project structure is specific enough for implementation:

- launcher path is defined
- TUI source path is defined
- core modules are defined
- module responsibilities are defined
- requirement-to-file mapping is defined
- integration and data flow boundaries are defined

**Pattern Completeness:**

The implementation patterns cover the major conflict points likely to affect multiple AI agents:

- metadata format
- category and ID naming
- TypeScript model shapes
- validation issue shapes
- execution result shapes
- UI state names
- error categories
- anti-patterns to avoid

### Gap Analysis Results

**Critical Gaps:**

None detected.

There are no missing decisions that block implementation.

**Important Gaps:**

- Exact TypeScript execution strategy remains open: build to `dist/` versus a runtime TypeScript strategy. This does not block architecture because the launcher boundary is defined, but the first implementation story must choose and document it.
- Exact OpenTUI rendering primitives and terminal cleanup mechanics should be validated during implementation against `@opentui/core@0.3.1`.
- `scripts/global-update` is architecturally named as the MVP Tool Brick, but the exact existing/new script implementation must be verified when implementation begins.

**Nice-to-Have Gaps:**

- A small `README.md` section for `arch-tui` dependency setup and usage would help handoff.
- Later pure-logic tests for `discovery.ts` and `validation.ts` would improve confidence once the implementation exists.
- A future phase 2 Git sync architecture section can be added when that work starts.

### Validation Issues Addressed

No critical validation issues were found.

The minor execution-strategy gap is handled by constraining the launcher boundary: `scripts/arch-tui` must document or encode how it invokes the TUI entrypoint, and any build output must remain local to `dotfiles/arch-tui/`.

### Architecture Completeness Checklist

**Requirements Analysis**

- [x] Project context thoroughly analyzed
- [x] Scale and complexity assessed
- [x] Technical constraints identified
- [x] Cross-cutting concerns mapped

**Architectural Decisions**

- [x] Critical decisions documented with versions
- [x] Technology stack fully specified
- [x] Integration patterns defined
- [x] Performance considerations addressed

**Implementation Patterns**

- [x] Naming conventions established
- [x] Structure patterns defined
- [x] Communication patterns specified
- [x] Process patterns documented

**Project Structure**

- [x] Complete directory structure defined
- [x] Component boundaries established
- [x] Integration points mapped
- [x] Requirements to structure mapping complete

### Architecture Readiness Assessment

**Overall Status:** READY FOR IMPLEMENTATION

**Confidence Level:** high

**Key Strengths:**

- The architecture is tightly aligned with the PRD and project-context constraints.
- Safety is treated as a first-class architectural boundary rather than UI decoration.
- Metadata discovery, validation, safety, execution, and UI responsibilities are clearly separated.
- The structure is minimal and concrete, which fits this repository.
- Deferred Git sync scope is constrained enough to avoid unsafe MVP creep.

**Areas for Future Enhancement:**

- Add a phase 2 architecture section for Git Synchronization once MVP is complete.
- Add persistence architecture only if guided setup/checklist state becomes required.
- Add automated tests for metadata parsing and validation after initial implementation.
- Revisit the discovery surface if Tool Bricks need to expand beyond `scripts/`.

### Implementation Handoff

**AI Agent Guidelines:**

- Follow all architectural decisions exactly as documented.
- Use implementation patterns consistently across all components.
- Respect project structure and boundaries.
- Refer to this document for all architectural questions.
- Do not introduce persistence, APIs, event buses, plugin systems, or broad framework patterns in MVP.
- Do not weaken existing script-level safety prompts.

**First Implementation Priority:**

Create the minimal `dotfiles/arch-tui/` TypeScript/OpenTUI project and `scripts/arch-tui` launcher, then implement metadata model, discovery, and validation before any command execution behavior.
