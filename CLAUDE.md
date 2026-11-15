# Claude Code Game Studios -- Game Studio Agent Architecture

Indie game development managed through 49 coordinated Claude Code subagents.
Each agent owns a specific domain, enforcing separation of concerns and quality.

## Technology Stack

- **Engine**: Godot 4.7.2
- **Language**: GDScript
- **Version Control**: Git with trunk-based development
- **Build System**: SCons (engine), Godot Export Templates
- **Asset Pipeline**: Godot Import System + custom resource pipeline

> **Note**: Engine-specialist agents exist for Godot, Unity, and Unreal with
> dedicated sub-specialists. Use the set matching your engine.

## Project Structure

@.claude/docs/directory-structure.md

## Engine Version Reference

<!-- ENGINE-REFERENCE-IMPORT: the line under this comment is engine-specific,
     and there is none until an engine is set. /setup-engine, the grow's record
     step and /project-settings (engine.name) write
     @docs/engine-reference/<engine>/VERSION.md here for the chosen engine. Skills
     that need the pinned version read that file on demand either way. -->
@docs/engine-reference/godot/VERSION.md


## Technical Preferences

`project.yaml` at the repo root is the primary config store — engine, specialists,
naming, platform, performance, modes. Skills resolve it via `resolve_config`
(see `.claude/docs/config-resolution.md`).

`.claude/docs/technical-preferences.md` is the **legacy fallback**, read on demand
when a key is absent from `project.yaml`. It is not imported here: before
`/setup-engine` runs it is almost entirely `[TO BE CONFIGURED]` placeholders, and
after it runs `project.yaml` holds the real values.

## Coordination Rules

@.claude/docs/coordination-rules.md

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
  (exempt: `active.md` appends, agent memory, a subagent's new file at the path
  its orchestrating skill named; see `.claude/rules/agent-memory.md`)
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction
- A skipped or dismissed question is not an answer: act on nothing, re-ask in
  plain text and wait
- Started outside this file's folder? Warn first: hooks, deny rules and the
  ask-first mode load only when Claude Code starts here

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for full protocol and examples.

> **First session?** Say "make me a game" (`/prototype`), or run `/start` to begin
> the guided onboarding flow.

## Coding Standards

@.claude/docs/coding-standards.md

## Context Management

Read `.claude/docs/context-management.md` on demand — it is a reference, not
session context. Two of its conventions are load-bearing and cited by name
elsewhere in the repo, so they are restated here rather than lost:

- **`production/session-state/active.md` is the session checkpoint.** The file is
  the memory, not the conversation. Read it first after any compaction, crash, or
  `/clear`.
- **Helpers in `.claude/scripts/` emit observations, never verdicts.** A script
  that scores or judges will eventually contradict a mode or override it cannot
  see. (Cited by `artifact-check.sh` and `adr-dep-graph.sh`.)
  
## Art Direction and Visual Design

The project keeps its visual-design knowledge base in `/docs/art/` and its concept art and
moodboards in `/art/` (not imported by Godot: `art/.gdignore`).

Before implementing or modifying any visual element:

1. Read `/docs/art/ART_DIRECTION.md`.
2. Read the relevant guide: `VISUAL_STYLE_GUIDE.md`, `COLOR_PALETTE.md`, `SPRITE_SPEC.md`,
   `environments/ENVIRONMENT_GUIDELINES.md`, and the room's own file (e.g. `environments/LIVING_ROOM.md`).
3. Inspect the corresponding concept references in `/art/`.
4. Respect each decision's status.

### Design Authority

- APPROVED decisions are mandatory.
- PROVISIONAL decisions are the current working direction; follow them, and say so before revisiting one.
- EXPERIMENTAL concepts are exploratory and must not silently become production standards.
- OPEN decisions must be surfaced when relevant; never guess or silently resolve them.
- REJECTED concepts must not be reused.

The GDD and the Demo Specification remain authoritative for gameplay, camera, room geometry,
projection, navigation and demo scope. If an art document appears to conflict with them, report
the conflict before implementing (see `ART_DIRECTION.md` §2 and §4).

### Implementation Principles

- Keep visual presentation separate from gameplay logic.
- This project has no physics collision shapes: walking footprints, sight blockers, hiding spots
  and interaction ranges are data (`assets/data/`). Images never define or change them.
- Make visual assets replaceable without changing gameplay behavior (`PropVisuals`, `SPRITE_SPEC.md`).
- Preserve movement, navigation, interaction, room dimensions and coordinates unless explicitly
  instructed otherwise.
- Do not redesign established gameplay systems or rewrite the room view's architecture as part
  of visual work.

### Visual Consistency

All new visual assets and environments must follow the approved Art Direction.

When a requested implementation conflicts with an existing approved design decision, identify the conflict before proceeding.

Do not invent new visual standards without documenting them.

### Reference Images

Reference images and concept art are visual guidance, not production-ready assets. A generated
image does not become a standard because it is in `/art/`.

Do not use complete concept illustrations as in-game backgrounds.

Analyze their composition, shape language, materials, lighting, palette, and object design, then
implement these principles within the existing Godot architecture. Before a broad restyle, report
the plan and wait for approval.
