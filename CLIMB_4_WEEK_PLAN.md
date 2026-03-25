# Soldat Climb MVP: 4-Week Implementation Plan

## Purpose

Build a desktop-first, code-first Climb MVP by extracting the exact Soldat movement feel from this repo before attempting a portable rewrite.

This plan assumes:

- The first goal is a playable desktop prototype, not a polished commercial build.
- Fidelity of movement matters more than architecture purity.
- We are intentionally avoiding editor-first workflows for now.
- Web and mobile are later targets, not week-1 targets.

## Product Goal

At the end of 4 weeks, we should have:

- A desktop app that launches straight into a Climb run
- One player
- No weapons, no combat loop, no AI, no menus beyond what is needed
- Exact Soldat-derived movement and collision
- Restart, timer, checkpoints or spawn/restart support
- Ghost/replay recording for deterministic validation
- A small set of canonical Climb test maps

## Strategic Decision

Use the current Pascal codebase as the reference implementation.

Do not rewrite the movement core yet.

Why:

- The movement is already implemented in:
  - `shared/mechanics/Control.pas`
  - `shared/mechanics/Sprites.pas`
  - `shared/Parts.pas`
  - `shared/PolyMap.pas`
  - `shared/Anims.pas`
- The biggest risk is losing feel, not choosing the wrong language.
- A clean rewrite should happen only after we have replay-based parity tests.

## Scope Boundaries

Keep:

- Fixed-tick movement
- Polygon collision
- Facing-direction logic derived from aim
- Roll / rollback / side-jump / crouch / prone state machine
- Map loading
- Animation timing that affects movement

Remove or defer:

- Weapons
- Bullets
- Gore / blood / cosmetic sparks not needed for feel
- Multiplayer
- Chat
- Bots
- Team modes
- Voting
- Most menus
- Steam / lobby work

## Week 1: Carve Out a Climb-Only Playable Loop

### Goal

Get a stripped desktop build that still uses the original movement and can load into a map, move, restart, and finish.

### Tasks

1. Define MVP mode
- Add a dedicated "Climb mode" path instead of trying to keep the full shooter loop intact.
- Prefer a compile-time or small runtime switch over broad invasive refactors.

2. Strip player equipment and combat
- Force `NOWEAPON` for the player.
- Disable fire-related logic where it interferes with movement.
- Disable grenade and weapon selection UI paths.

3. Remove non-essential loop systems
- Disable bots, voting, team logic, score logic, and unrelated HUD sections.
- Keep only what is required to spawn, update, render, and restart.

4. Simplify startup
- Launch straight into a local Climb session on a specified test map.
- Avoid server/client orchestration if a purely local path is possible with minimal changes.

5. Add restart
- Bind a restart key.
- Restart should reset player state, timer, and ghost capture state.

### Deliverable

- Local desktop build
- One map
- One player
- Exact movement intact
- Restart works

### Exit Criteria

- Side jumps, rollbacks, landings, and facing flips behave the same as in the current game
- No weapon systems are required to complete a run

## Week 2: Timer, Checkpoints, Map Flow, Minimal UX

### Goal

Turn the stripped sandbox into a real Climb run loop.

### Tasks

1. Run state
- Add run states: idle, running, finished, restarted
- Start timer on first movement or first checkpoint leave
- Stop timer on finish trigger

2. Finish / checkpoints
- Choose one of these:
  - map-defined start and finish markers
  - a lightweight custom config per map
- Do not over-design map tooling in week 2

3. Minimal HUD
- Timer
- Current run status
- Restart hint
- Optional checkpoint indicator

4. Map rotation for testing
- Support a tiny curated list of Climb maps
- Add a simple next/previous map control or config flag

5. Camera sanity
- Make sure camera behavior is good enough for Climb
- Remove shooter-specific camera behaviors if they hurt readability

### Deliverable

- You can load a map, start a run, finish a run, restart instantly, and switch between a few maps

### Exit Criteria

- A player can complete repeated runs without touching shooter-specific UI
- Timer and finish state are stable across restarts

## Week 3: Replay / Ghost System and Movement Oracle

### Goal

Create the reference harness that makes future rewrites safe.

### Tasks

1. Input recording
- Record per-tick input state:
  - left/right/up/down
  - jet/flip
  - prone if needed
  - mouse aim or facing input state
- Save runs as small text or binary replay files

2. Playback
- Deterministically replay recorded runs
- Render a ghost of the best run or previous run

3. Validation hooks
- Log or export tick snapshots:
  - position
  - velocity
  - direction
  - major animation state if useful

4. Canonical move set
- Create a handful of short test replays:
  - standing jump
  - side jump
  - rollback / backflip
  - rapid facing flip recovery
  - slope landing

5. Best-time persistence
- Save best local times per map

### Deliverable

- Record and replay system
- Visible ghost
- Canonical reference replays

### Exit Criteria

- A replay reproduces the same movement reliably enough to be used as a regression oracle
- We can detect when a refactor changes movement

## Week 4: Cleanup, Hardening, and Rewrite Preparation

### Goal

Stabilize the MVP and prepare the codebase for a later portable core rewrite.

### Tasks

1. Isolate the true Climb core
- Identify the smallest movement slice that must survive into a future rewrite
- Document dependencies between:
  - control state
  - animation timing
  - collision
  - map data

2. Remove dead pathways
- Clean out obvious shooter-only hooks from the Climb path
- Do not attempt a massive repo-wide cleanup

3. Add regression checks
- Make replay comparison part of the development workflow
- Even a simple command-line replay runner is enough

4. Package the MVP
- Make startup simple
- Document how to launch it and load a map

5. Write rewrite notes
- Capture what a future C++ core must preserve exactly
- Capture what can change safely

### Deliverable

- Stable desktop Climb MVP
- Replay-based movement regression safety net
- Clear boundary for future C++ rewrite

### Exit Criteria

- Another session or engineer can pick up the project without rediscovering the architecture
- We know exactly what should be ported later

## Recommended Technical Shape During These 4 Weeks

### Keep the project code-first

Prefer:

- Plain Pascal code
- Text config files
- Replay files
- Small focused modules

Avoid for now:

- Editor-managed scene pipelines
- New engine adoption
- Visual scripting
- Heavy asset tooling work

### Suggested internal modules

Even if the repo is not immediately reorganized, think in these buckets:

- `climb_core`
  - movement
  - collision
  - map state
  - timer/run state
- `climb_frontend`
  - window/input/rendering/HUD
- `climb_replay`
  - record/playback/ghost

## Major Risks

1. Accidentally changing movement feel
- Mitigation: replay oracle by week 3

2. Over-refactoring too early
- Mitigation: ship the ugly but faithful MVP first

3. Fighting the original menu/server structure
- Mitigation: add a narrow Climb path instead of cleaning the entire game

4. Hidden dependency on animation data
- Mitigation: preserve original animation timing and assets during MVP

5. Scope creep into multiplayer or web
- Mitigation: explicitly defer both until after replay-backed desktop MVP

## Explicit Non-Goals for This Phase

- Browser version
- Mobile version
- Full online multiplayer
- Matchmaking
- Map editor
- Cosmetic polish beyond readability
- Commercial-grade content pipeline

## Success Definition

This phase is successful if:

- An experienced Soldat Climb player says the movement feels right
- Runs can be repeated quickly
- Best times and ghosts work
- We can safely start a future rewrite from a known-good reference

This phase is not required to produce:

- scalable architecture
- beautiful code
- engine portability
- polished production UX

## What To Do Immediately In The Next Session

1. Create a dedicated branch for Climb MVP work.
2. Identify the shortest local execution path that bypasses unnecessary server/shooter flow.
3. Force the player into `NOWEAPON` and strip weapon UI dependencies.
4. Choose one test map and make restart instantaneous.
5. Do not touch web, mobile, or rewrite work yet.

## Suggested Next-Session Prompt

Use this in the next session if needed:

> Pick up from `CLIMB_4_WEEK_PLAN.md`. We are building the week-1 Climb-only desktop MVP inside the existing Pascal repo. Keep the original movement/collision feel, force `NOWEAPON`, remove or bypass non-essential shooter systems, load directly into one test map, and implement instant restart. Do not start a rewrite.

