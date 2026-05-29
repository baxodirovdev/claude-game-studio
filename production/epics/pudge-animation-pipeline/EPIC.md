# Epic: Pudge Animation Pipeline

> **Slug**: `pudge-animation-pipeline`
> **Status**: Ready (stories created)
> **Type**: Art / Asset-production pipeline (not a code module)
> **Hero ID**: `pudge`
> **Created**: 2026-05-29

## Overview

Take the existing AI-generated, textured Pudge mesh from a static prop to a
fully game-ready, animated hero: clean retopology, baked PBR textures, a 27-bone
rig with helper bones, 10 frame-accurate animation clips, GLB export, and Godot
4.6 integration (AnimationTree + bone sockets + engine-side IK).

A throwaway rig test (2026-05-29) confirmed the clean LOD0 retopo auto-weights
and deforms without tearing — this epic de-risked, now it needs proper execution.

## Why this is a "pragmatic asset" epic (no ADRs / TR-IDs)

This is art production, not a code feature. There is no system GDD with TR-IDs
and no governing ADR for character/animation work. The **implementation contract
lives in the detailed asset specs below** — each story points at the exact spec
section it satisfies instead of a TR-ID/ADR. Acceptance criteria are lifted from
those specs; evidence is art-appropriate (deform QA poses, bake checks,
`/blender-export-check`, in-game verification).

## Governing Specs (the contract — read in place of ADRs)

| Spec | Path |
|---|---|
| Brief (locked) | `design/characters/pudge_brief.md` |
| Concept sheet (Silhouette B locked) | `design/concept-art/pudge.md` |
| Model spec | `design/gdd/models/pudge.md` |
| Retopo + bake plan | `design/gdd/models/pudge_retopo_bake_plan.md` |
| Texture spec | `design/gdd/materials/pudge.md` |
| **Rig + animation spec** (27 bones, 10 clips) | `design/gdd/rigs/pudge.md` |
| Rig authoring playbook | `design/gdd/rigs/pudge_authoring_playbook.md` |
| Operational Blender pipeline | `design/gdd/asset-records/pudge_blender_pipeline.md` |
| Godot loader contract | `src/gameplay/hero/hero_model_builder.gd:28-36` |

## Engine

Godot 4.6 (integration stories) · Blender 4.x/5.1 (art stories).
**Risk:** Godot 4.6 AnimationTree / SkeletonModifier3D IK are post-LLM-cutoff —
verify APIs against `docs/engine-reference/godot/` before implementing
integration stories (018, 019).

## Open prerequisites (resolve before/while starting)

1. Rig spec `design/gdd/rigs/pudge.md` is `DRAFT — pending rigger/animator review`.
   Sign off before Phase 2 (rig) begins.
2. In-session Blender edits (crescent removal, etc.) are **unsaved** — on-disk
   `anime_pudge.blend` still has the AI source + high-poly bake source intact.
   The high-poly (`textured_mesh_bake_hp`) is the bake source for Story 005 — do
   not lose it.

## Stories

| # | Story | Type | Status | Spec |
|---|-------|------|--------|------|
| 001 | Reconcile loader socket bone names | Integration | Ready | rig §7 + loader |
| 002 | Finalize body retopo LOD0 | Visual/Feel | Ready | retopo §D |
| 003 | Model hook prop LOD0 | Visual/Feel | Ready | retopo §C |
| 004 | UV unwrap body + hook | Visual/Feel | Ready | retopo §E |
| 005 | Bake PBR maps | Visual/Feel | Ready | retopo §F |
| 006 | Generate LOD1/LOD2 | Config/Data | Ready | pipeline §2/§13 |
| 007 | Build arm_pudge skeleton + A-pose bind | Visual/Feel | Ready | rig §1–2 |
| 008 | Helper bones (BellyJiggle/Jaw/ChainLink) | Visual/Feel | Ready | rig §4 |
| 009 | Skin / weight paint + deform QA gate | Visual/Feel | Ready | rig §5 |
| 010 | Define 5 bone sockets | Integration | Ready | rig §7 |
| 011 | Locomotion clips (idle/walk/run/turn) | Visual/Feel | Ready | rig §8 |
| 012 | Hook clips (throw/recover) | Visual/Feel | Ready | rig §8 |
| 013 | Combat/reaction clips (attack/hit) | Visual/Feel | Ready | rig §8 |
| 014 | Terminal clips (death/victory) | Visual/Feel | Ready | rig §8 |
| 015 | Animation events + export naming | Integration | Ready | rig §8/§9 |
| 016 | Migrate file + export pudge.glb | Config/Data | Ready | pipeline §1/§8 |
| 017 | Godot load + BoneAttachment3D sockets | Integration | Ready | rig §7 + loader |
| 018 | AnimationTree (StateMachine + BlendSpace1D) | Integration | Ready | rig §8 |
| 019 | Engine-side IK (SkeletonModifier3D) | Integration | Ready | rig §6 |

**Totals:** 19 stories — 11 Visual/Feel, 6 Integration, 2 Config/Data.
Work in order; each story's `Depends on:` lists its blockers.
