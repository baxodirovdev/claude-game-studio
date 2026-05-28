---
name: team-3d-asset
description: "Orchestrate the full 3D asset pipeline: concept-artist → modeler → texture-artist → rigging-animator (if deformable) → blender-specialist → technical-artist. Coordinates handoffs end-to-end from brief to Godot-ready asset."
argument-hint: "[asset brief or name]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Task, AskUserQuestion
---

When this skill is invoked, orchestrate the 3D asset team through a
structured pipeline. Each stage hands off to the next; the user approves
between stages.

**Decision Points:** At each step transition, use `AskUserQuestion` to
present the subagent's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise
labels. The user must approve before the next stage runs.

1. **Read the argument** for the target asset brief (e.g., `knight
   character`, `forest tree kit`, `magic sword`, `stone wall modular kit`).

2. **Classify the asset** — this determines the pipeline path:
   - **Hard-surface prop / weapon / vehicle** → concept → 3d-modeler →
     texture → (skip rig) → export
   - **Character / creature** → concept → character-artist →
     rigging-animator → texture → export
   - **Environment kit** → concept → environment-artist → texture →
     (skip rig) → export
   - **Hybrid** (rigged prop like a chest, wind-animated foliage) →
     confirm path with the user

3. **Gather context**:
   - `design/gdd/art-bible.md` (style and budgets)
   - `.claude/docs/technical-preferences.md` (engine conventions)
   - `docs/engine-reference/godot/VERSION.md` (Godot 4.6 rules)
   - Similar existing assets in `src/assets/models/` for consistency

## How to Delegate

Use the Task tool to spawn each team member as a subagent. Always provide
the full asset brief + every prior stage's output in the agent's prompt
(the agent has no conversation history).

- `subagent_type: concept-artist` — silhouette, turnaround, material callouts
- `subagent_type: 3d-modeler` — hard-surface / prop spec
- `subagent_type: character-artist` — character model spec
- `subagent_type: environment-artist` — kit spec
- `subagent_type: texture-artist` — PBR material spec
- `subagent_type: rigging-animator` — skeleton + animation list
- `subagent_type: blender-specialist` — export validation + pipeline
- `subagent_type: technical-artist` — Godot import settings + material
  resource setup

## Pipeline Stages

### Stage 1 — Concept (concept-artist)
Spawn `concept-artist` with the asset brief to produce the concept sheet at
`design/concept-art/[asset].md`. User approves silhouette and material
callouts before proceeding.

### Stage 2 — Model Spec (routed)
Route to `3d-modeler`, `character-artist`, or `environment-artist` per the
classification in step 2. Produce the model spec via the `model-spec`
skill at `design/gdd/models/[asset].md`. User approves polycount, UVs,
material count.

### Stage 3 — Texture Spec (texture-artist)
Spawn `texture-artist` to produce the texture spec via the `texture-spec`
skill at `design/gdd/materials/[asset].md`. User approves resolution,
channel packing, memory budget.

### Stage 4 — Rig Spec (rigging-animator) — CONDITIONAL
Skip if the asset is static. For characters/creatures/rigged props, spawn
`rigging-animator` to produce the rig and animation list. User approves
bone count, animation set, root motion convention.

### Stage 5 — Blender Pipeline (blender-specialist)
Spawn `blender-specialist` to:
- Confirm the `.blend` file organization plan
- Define the export path (.blend direct import vs .glb)
- Set up the import preset in Godot for this asset class (if new)
- Prepare the validation script for `blender-export-check`

### Stage 6 — Authoring (human in the loop)
The actual 3D authoring happens in Blender by the human artist. The
agents have produced every spec needed. Output a handoff summary listing:
- Concept sheet location
- Model spec location
- Texture spec location
- Rig spec location (if applicable)
- Target .blend path under `src/assets/models/`
- Target texture paths under `src/assets/textures/`

### Stage 7 — Export Validation (blender-export-check skill)
Once the artist reports authoring complete, run the `blender-export-check`
skill against the `.blend` file. Iterate on failures until PASS.

### Stage 8 — Engine Integration (technical-artist)
Spawn `technical-artist` to:
- Configure the Godot import preset for this asset
- Create the `.tres` material resources with the texture-artist's maps
- Verify the asset appears correctly in-engine at target LOD distances
- Update the art bible asset index

4. **Compile the asset record** at `design/gdd/asset-records/[asset].md`
   linking every stage output and the final in-engine path.

5. **Output a summary**:
   - Asset name and class
   - Stage outputs (paths)
   - Open blockers
   - Total tri + memory budget consumed
   - Integration status
