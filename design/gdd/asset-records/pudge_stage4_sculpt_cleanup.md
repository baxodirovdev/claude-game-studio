# Pudge — Stage 4 Sculpt-Cleanup Checklist

> **Pipeline stage**: 4 (Sculpt cleanup) — entered 2026-06-18 after Stage 3 (Model Spec) APPROVED.
> **Working object**: `pudge_v2_remesh` in `src/assets/models/heroes/anime_pudge.blend`.
> **Backup**: `pudge_v2_remesh_preStage4` (in hidden `STAGE4_BACKUP` collection) — pre-cleanup snapshot, fully restorable.
> **Source of truth**: `design/gdd/contracts/pudge-interface-contract.md` (contract wins on any conflict),
> concept `design/concept-art/pudge.md` Silhouette B "Coiled Hook Carry".

This is a **human-in-Blender** task list. The agent has completed the *safe, scripted*
prep (below); the *artistic sculpting* is yours. Do not script-sculpt the surface —
these are sculpt-mode / proportional-edit decisions that need an artist's eye against
the concept.

---

## Axis convention (read first)

| Direction | Meaning | Concept feature on this side |
|---|---|---|
| **+X** | Character's **LEFT** | **Chunky hook arm**, hook + chain prop, chain coil on hip, **larger left eye** |
| **−X** | Character's **RIGHT** | Slimmer arm, smaller eye |
| **−Y** | **Front** (face direction) | Belly hangs forward (−Y), face reads in Front Ortho (Numpad 1) |
| **+Z** | Up | Top of head ≈ 1.399 m, feet ≈ 0 |

Mesh faces **−Y** in Blender → exports to **−Z forward** in Godot (correct). No
rotation hack. (Contract §9 / O-2 — verified PASS at Stage 4 entry.)

---

## ✅ Done by agent (scripted, safe — already in the saved .blend)

- [x] **Snapshot** `pudge_v2_remesh` → `pudge_v2_remesh_preStage4` (hidden `STAGE4_BACKUP`). Reversible baseline.
- [x] **Confirmed asymmetry is on the correct side.** Vert counts at the hand/lower-arm band
      (z 0.55–0.85): **+X = 1482 verts vs −X = 628** → chunky arm mass is on the character's
      **left (+X)**, matching Silhouette B and model spec §3. Upper-shoulder band is ~symmetric (correct).
- [x] **Removed stale `PUDGE_NEW_REFERENCE_RIG`** (12 `REF_*` objects scaled to the old 1.5 m
      target; actual mesh tops at 1.399 m). Scene de-cluttered.
- [x] **Reconciled `design/gdd/asset-records/pudge.md`** to the contract (22/26 bones, T-pose,
      keyframed jiggle, manual LOD).
- [x] Saved `anime_pudge.blend` (`.blend1` backup written).

---

## ⚠️ Corrected understanding (2026-06-18) — it's a 2-arm T-pose, NOT "4 arms"

An earlier pass mis-read this mesh as having spurious extra-arm artifacts to bulk-delete.
**That was wrong and has been fully reverted** (mesh restored to the clean 19,147-vert
backup). Verified by top-down + front ortho:

- The mesh has **exactly two arms**, held out to the sides ≈ **T-pose** — the correct,
  riggable bind pose. **Keep both arms. Do not bulk-cut them.**
- The "4 arms" look came from the **hook blade (left/+X hand) and chain coils** being
  **fused onto the hands/forearms** by the AI generator — props reading as extra limbs,
  not actual limbs.

**Decision (user, 2026-06-18): leave the mesh as-is.** The body is an acceptable 2-arm
T-pose base for rigging. The fused hook/chain are deferred to a **later prop-separation
task** (see "Deferred" below), not cut during this sculpt pass.

## 🎨 Your sculpt tasks (in Blender)

### 1. (DEFERRED) Hook/chain → separate prop — NOT this pass
- The hook + chain are currently **fused onto the hands**. They must eventually become the
  separate `mesh_pudge_hook` prop (attached at `socket_hook_hand`), because the hook is
  **thrown** and a clean hand weight-paints/animates far better.
- **Per user decision this is deferred** — do *not* peel it now. Keep the **left (+X)** fused
  hook/chain intact as a **shape reference** for authoring the real prop later.
- Tracked as a separate task; revisit at prop-authoring (alongside Stage 5 retopo), not here.

### 2. Face refinement to concept  **[HIGH — reads at gameplay camera]**
- Grotesque-jovial butcher grin: **crooked / mismatched teeth** (teeth are a strip, per model spec).
- **Asymmetric eyes — larger LEFT eye (+X)**, ~15% bigger than right (concept + spec §3).
- Heavy brow, bulbous nose, jowly cheeks. Face must read in **Front Ortho** at small scale.
- Keep the **no-neck hunch** — head sits low between the shoulders.

### 3. Belly read  **[HIGH — primary silhouette]**
- Enormous bloated belly **hanging forward (−Y) beyond the feet** in side profile.
- Smooth the belly into a single dominant convex mass — this is the tank read.
- Note the **`jiggle_boundary` zone** (contract §6, 2-color red/white + pink gradient): keep
  belly surface clean and even so weight-paint / jiggle keyframes deform predictably later.

### 4. Arm refinement  **[MED]**
- Confirm the **left (+X) arm is visibly heavier** than the right (it already carries more mass —
  refine, don't rebuild). Beefy forearm, chunky gripping hand.
- **Leave the fused hook/chain alone this pass** (deferred — see task 1). Refine only the
  arm/hand *form*; the prop-separation happens later.

### 5. Belt / apron  **[LOW]**
- Brown leather **belt** at the waist; small **bloodied apron stub** under the belt (merged into
  body mesh per brief §6). Ratty boots at the feet.

### 6. Final silhouette pass vs Silhouette B  **[GATE]**
- Side-by-side the mesh against `design/concept-art/pudge.md` Silhouette B in Front + Right ortho.
- **3-heads-tall** proportion check (head ≈ 0.466 m of the 1.399 m height).
- Silhouette must be **instantly readable as Pudge** from the default gameplay camera —
  belly + hunch + hook arm are the three silhouette anchors.

---

## Hand-off back to pipeline

When the sculpt reads on-concept from all ortho views:
1. Save `anime_pudge.blend`.
2. Delete `STAGE4_BACKUP` only after you're satisfied (keep until then).
3. Proceed to **Stage 5 (Retopo)** — hand-retopologize to the model-spec topology
   (~6,100 tris LOD0, clean deformation loops), shrinkwrapped to this cleaned sculpt
   + the existing `textured_mesh_bake_hp` high-poly bake source.

> Stage 4 acceptance = artifact gone, face/belly/arm on-concept, 3-head proportion holds,
> silhouette readable. No polycount/topology gate yet — that's Stage 5.
