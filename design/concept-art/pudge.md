# Pudge — Stage 1 Concept Sheet

> **Status**: APPROVED — Silhouette **B (Coiled Hook Carry)** locked 2026-04-28. Apron: **yes — small bloodied stub tucked under belt** (resolves Open Note #1 to character-artist).
> **Hero ID**: `pudge`
> **Stage**: 1 of 8 (Concept)
> **Concept artist**: `concept-artist` agent
> **Date**: 2026-04-28
> **Brief**: `/design/characters/pudge_brief.md`
> **Next stage gate**: User picks one silhouette → `character-artist` begins high-poly sculpt

---

## Summary

Pudge is a 3-head-tall chibi butcher whose silhouette is dominated by an
enormous bloated belly that hangs forward beyond his feet, a nearly neckless
head sunk into hunched shoulders, and a left arm visibly heavier than the right
due to its role as the hook-throwing working arm. The personality target is
menacing-but-goofy: the chibi proportions turn a horror-show butcher into
something a player finds threatening and amusing at the same time, in the
tradition of Brawl Stars brawlers wearing Dota 2 Pudge's identity. Every
silhouette proposal below satisfies the brief's locked features (bloated belly
with stitches, crooked teeth grin, asymmetric eyes, ratty boots, meat hook and
chain on the left arm, chunky left arm, no-neck hunch, brown leather belt) and
must read cleanly at 1080p from a top-down camera approximately 12 meters away
at 30 degrees pitch.

---

## Three Silhouette Proposals

---

### A — Classic Butcher

**Silhouette description**

The dominant read at thumbnail size is a perfect teardrop: an enormous round
belly at the bottom, narrowing up through hunched shoulders to a small round
head. Both arms hang low and outward, left visibly wider than right. The gut
protrudes so far forward that the boots are barely visible beneath it. The hook
hangs at the end of the left arm, pointing straight down, with chain coiling
back up to the belt on the left hip. The cleaver is held flat against the right
thigh. Nothing competes with the belly sphere for dominance — the shape reads
as a single large blob with four small stubs (head, two arms, two legs barely
distinguishable). This is the most immediately legible option from altitude: one
shape, one idea.

```
        ___
       /   \
      | o O |     <- asymmetric eyes; O is larger left eye
       \ w /      <- wide grin
      __| |__
     /         \
    /   (( ))   \  <- chain loop at belt
   |  STITCHES   |
   |     |||     |  <- vertical + horizontal stitch lines
    \   _____   /
     | |     | |   <- belt band
    /|           |\
   ( |           | )
    \|   ( G )   |/  <- gut bulge forward
      \  _____  /
       \/     \/
        | | | |     <- barely-visible stubby legs
        |_| |_|
       [_] [_]      <- ratty boots, splayed laces
```

**3 distinguishing features**

1. Perfectly symmetrical left-right pose — arms equidistant from body, creating the clean teardrop read.
2. Hook hangs pointing straight down along the left leg, chain visible as a loose arc from hand to belt.
3. Cleaver rests flat against the right thigh rather than raised, keeping the silhouette compact and blob-like.

**Risk**

Symmetry makes the silhouette read as "generic round enemy." At extreme camera
distance the left-arm asymmetry (heavier arm) may be lost because the pose
balances it out.

**Pros**

- Clearest thumbnail read of all three options; one dominant shape.
- Easiest rigging and skinning — neutral A-pose aligns with the brief's bind pose.
- Fewest hard edges, lowest polycount risk for the belly sphere approach.
- "Classic" immediately communicates "butcher" to players unfamiliar with Dota.

**Cons**

- Least visually exciting at medium zoom; may need texture and material detail
  to carry character at the distances where the camera lives.
- Left-arm asymmetry (hook arm chunkier) is readable in the model but not
  forceful at 12m top-down — relies on animation to communicate "hook arm."

---

### B — Coiled Hook Carry

**Silhouette description**

Pudge is mid-waddle: left arm raised and cocked outward at shoulder height,
holding the hook horizontally so the curved tip points outward to the left.
The chain drapes from the raised hand in a visible catenary arc back to the
belt. The right arm hangs lower and inward, cleaver angled down. This creates
a strongly asymmetric outline: a tall spike of chain+hook on the left side
breaking the teardrop, versus a compact right side. The head is turned very
slightly left (3/4 tilt) hinting that Pudge is always watching for a target.
From overhead the raised arm reads as an extra horizontal spike extending past
the belly circumference, making the hero's "hook side" instantly identifiable
in team fights.

```
          ___
    _    /   \    
   | \  | o O |   <- head tilted slight left; O large left eye
   |H \ \ w  /    <- H = hook (horizontal, tip pointing left)
   |===\  | |
   chain\ |_|__
    arc  /      \
        /  (( ))  \  <- chain coil on left hip
       |  STITCHES |
       |    |||    |
        \  _____  /
         ||     ||   <- belt
        /|       |\
       ( | ( G ) | )  <- gut forward
        \|       |/
          |   |
          |_| |_|
         [_] [_]
```

**3 distinguishing features**

1. Hook is raised and extended horizontally left — creates an asymmetric spike at shoulder height that reads instantly from overhead.
2. Chain catenary arc is part of the resting silhouette, immediately communicating Pudge's hook mechanic to new players before they read any UI.
3. Head has a subtle 3/4 tilt toward the hook side — personality pose, not neutral.

**Risk**

The raised arm extends the silhouette width on the left. If multiple Pudges
are on screen (mirror match), the two raised hooks could create mirrored
confusion. Chain drape also adds triangle budget and complexity for the chain
geometry artist.

**Pros**

- The hook is a gameplay-critical prop — raising it into the silhouette makes
  the mechanic readable from the moment the player selects the hero.
- Asymmetric outline is unmistakable at 12m top-down; no other brawler with a
  round belly would have that left-spike profile.
- The "coiled and ready" pose communicates Pudge's role (hooker/puller) without
  a single line of UI.

**Cons**

- Rest animation must consistently hold this arm position, which affects the
  idle and walk cycles (arm stays semi-raised, not fully relaxed).
- More complex bind pose; deviates from brief's A-pose recommendation — rigger
  will need to account for the raised-arm rest.
- Polycount risk: chain in silhouette needs enough segments to read as organic
  curve at texel density, pushing toward the high end of the 6k-8k budget.

---

### C — Squat Lurch

**Silhouette description**

Pudge is lower and wider than either option above — legs bent outward in a
permanent squat, torso tipped forward so the gut almost touches the ground
plane. The head is pulled so far forward and down that from overhead it appears
in front of the torso mass rather than above it. Arms spread wide and low like a
wrestler about to grapple. The hook hangs between the left hand and the ground,
chain flat on the floor in a coil. The overall silhouette is a flattened
diamond or shield: very wide at the arm span, very low to the ground, with the
gut as the forward-most point. This is the most distinctive outline of the three
— no other chibi brawler has this "low and spreading" language.

```
      _   ___   _
     ( ) /   \ ( )   <- arms spread wide, low
      \|/ o O \|/    <- large left eye O
       | \ w / |     <- grin
       |  | |  |
       | _|_|_ |
      /|/     \|\
     / /  [B]  \ \   <- [B] belly mass, tipped forward
    | | STITCHES| |
    | |  |||||  | |
     \ \  ___  / /
      \ \/   \/ /
       \|belt |/
        |_____|
       /       \     <- squat legs, wide stance
      /|       |\
    [_]|       |[_]  <- boots splayed outward
        \_____/      <- coiled chain on ground between feet
         (===)
```

**3 distinguishing features**

1. Permanently squatted stance — legs bent outward, lowest center of gravity of any three options; reads as immovable and brutish.
2. Head is tipped forward and low, appearing to jut out from the front of the torso mass from top-down angle — unique silhouette landmark.
3. Chain coils on the ground between feet at rest — communicates "heavy, slack, dangerous" rather than "ready to throw."

**Risk**

From a strict top-down 30-degree pitch the squatted stance may compress the
torso and legs into a single mass, reducing vertical separation between belly
and boots. Could read as priest/toad from far if the gut-forward tilt is not
pronounced enough. The ground-level chain coil may be invisible from camera
angle without deliberate upward-facing chain geometry.

**Pros**

- Most distinctive silhouette of the three — the low spread diamond is unlike
  any standard chibi bipedal template.
- Reinforces Pudge's "slow, immovable tank" feel at a glance; posture IS the
  gameplay tell.
- Chain as ground element reads as environmental detail and threat (player
  steps into Pudge's chain radius zone intuitively).

**Cons**

- Bent-leg squat stance is harder to retarget for animation — walk and run
  cycles need specialized handling to preserve the wide low stance without
  sliding feet.
- Top-down camera compression is a real risk: at 12m/30-degree pitch, the
  height differential between squatted legs and belly is reduced, flattening
  the silhouette's most interesting axis.
- Chain on ground requires careful geometry planning to be visible at all;
  likely needs a slight upward coil or prop stand-in rather than flat ground
  contact.

---

## Recommendation

**Proposal B — Coiled Hook Carry** is the recommended pick.

The brief's primary gameplay identity is the hook-puller mechanic. Raising the
hook into the resting silhouette does something the other two proposals do not:
it teaches the player what Pudge does before the first tutorial prompt appears.
In a top-down brawler with fast visual reads, connecting the hero's most
distinct prop to the hero's outline shape is the highest-value design decision
available at this stage. The asymmetric spike also solves the "generic round
blob" risk of Proposal A and avoids the top-down compression risk of Proposal C.

The risk — deviating from the brief's A-pose bind pose — is manageable. The
rigger can author the bind pose in A-pose and drive the raised arm rest position
through a pose library or animation layer rather than baking it into the bind
pose itself. This is standard practice for characters with signature held poses
(see: Brawl Stars Colt revolver at hip, Shelly shotgun at shoulder).

The final decision belongs to the art director and user. Proposals A and C
remain valid and each has a clear production path.

---

## Material Callouts

These values apply to whichever silhouette is chosen. The `Color(0.5, 0.8, 0.2)`
hero tint is applied via shader uniform at runtime; base skin must be a
desaturated neutral that accepts tint without fighting it. All roughness and
metallic values are for the ORM channel pack (R=AO baked separately, G=Roughness,
B=Metallic).

| Surface | Base Color Hex | Roughness (G) | Metallic (B) | Notes |
|---|---|---|---|---|
| Skin (base) | `#8A8A7A` | 0.75 | 0.05 | Desaturated warm grey; team tint shader multiplies over this. Avoid any green in the base — the tint provides the green. |
| Skin (shadow/cavity) | `#6B6B5E` | 0.70 | 0.08 | Darken 25% from base; used for underside of belly, armpits, neck fold. Fake SSS: warm the shadows slightly toward `#7A6A5E`. |
| Skin (highlight/lit) | `#9E9E8E` | 0.80 | 0.05 | Lighten 10% from base; belly front highlight baked into base color. |
| Scar / stitch thread | `#332519` | 0.90 | 0.00 | Near-black brown, matte. Thread should be a separate painted element on the base color map, not geometry at LOD1+. |
| Stitch hole / wound edge | `#5C1A1A` | 0.85 | 0.00 | Deep red-brown, slightly more saturated than stitch thread. Painted within 2-3 px of thread line. |
| Teeth | `#C8B87A` | 0.80 | 0.00 | Yellowed off-white, matte. Missing tooth gaps painted as dark interior `#1A0E0E`. Sharp teeth slightly brighter `#D4C68A`. |
| Eye sclera | `#F5E870` | 0.20 | 0.00 | Yellow-white per brief (`Color(1.0, 0.85, 0.1)`). Low roughness to read as wet/bulging. Emissive: yes. |
| Eye emissive | `#FFB800` | — | — | Emissive layer only. Intensity 3.0 per brief. Applied to sclera and inner rim only, not pupil. |
| Eye pupil | `#1A0A0A` | 0.90 | 0.00 | Near-black, matte. No emissive. Painted as dark spot within sclera area. |
| Belt leather | `#59330F` | 0.70 | 0.15 | Mid brown, slightly shiny — worn but not cracked. Scuff highlights `#7A4E1F` painted on edges. |
| Belt buckle (metal) | `#726E6A` | 0.35 | 0.70 | Iron/steel, moderate specular. Scratches painted as lighter streaks `#9A9590`. |
| Boot leather | `#4A2E0A` | 0.75 | 0.10 | Darker than belt — ratty, more worn. Scuffs and wear marks lighter `#6B4520`. Lace area: near-black `#1A1008`. |
| Boot sole | `#1A1510` | 0.90 | 0.00 | Near-black compressed leather/rubber, fully matte. Crack lines painted in darker. |
| Chain links (iron) | `#4A4844` | 0.45 | 0.65 | Dark iron, moderate metallic. Individual link edges brighter `#7A7672` — painted highlight on upper faces of each link. |
| Hook body (iron) | `#3E3C38` | 0.40 | 0.70 | Darker than chain — hook is older, heavier iron. Slightly more metallic to read as dense. |
| Hook tip / blood | `#8A1A1A` | 0.80 | 0.10 | Dried blood dark red-brown, matte. Painted as spatter on the inner curve and tip only — not covering the whole hook, just the business end. Fresh blood accent `#C02020` as small streak, roughness 0.60. |
| Meat / offal (belt trophies) | `#7A3030` | 0.85 | 0.00 | If any belt-dangled meat scraps are added in sculpt, use this as base. Optional detail, not in brief spec. |

---

## Turnaround Sheet Description

The following describes what each orthographic view would show for the
recommended pick (B — Coiled Hook Carry). These descriptions are the reference
for the character-artist during high-poly sculpt.

### Front View (0 degrees)

The belly sphere dominates the lower two-thirds of the frame. The belt band
sits just below the belly equator with the buckle centered. The vertical stitch
runs from the belt up to the chest; three horizontal stitches cross it at
equal intervals. The left arm is raised to approximately 45 degrees above
horizontal, elbow bent slightly outward; the meat hook is visible in the
left fist with the curved tip pointing to viewer-left. Chain links are
visible from the fist, draping in a catenary arc to a coil visible at the
left hip just above the belt. The right arm hangs at a slight outward angle,
right hand holds the cleaver with blade angled downward. The head sits with
no visible neck between the shoulders — the chin rests almost on the chest
plane. Both eyes are visible: left eye noticeably larger and slightly higher
than the right. Wide grin dominates the lower face; crooked teeth visible
across the full mouth width. Legs are barely visible below the gut overhang —
just the tops of the boots showing. Ratty laces on boots are visible as
loose strands.

### Side View (90 degrees — viewer-left, hook-arm side)

The forward belly protrusion is most dramatic from this angle: the gut
extends approximately 0.3 model units ahead of the toes. The hunch is
clearly visible — the spine curves forward so the head is in front of the
torso center line, not above it. The left arm is raised and cocked forward;
the hook's full curved profile is visible in silhouette — the classic
J-shape with the point facing forward. Chain droops from the hook back
to the belt hip coil. Boot profile shows the worn sole and the slightly
too-small fit (toes slightly beyond the front of the boot box). The belly
stitches are visible in profile as raised geometry on the front face of
the gut. The belt buckle is NOT visible from this angle — it is front-facing.
The cleaver on the right hand is hidden behind the torso mass.

### Back View (180 degrees)

The most important reveal from the back: several meat hook loops or scraps
of chain are visible hanging from the back of the belt — these are the
"extra chain supply" that feeds the hook throw animation. Two or three
additional chain links dangle from the belt back. The back of the boots
shows the most wear — heel scuffing and a split seam on one boot (left
preferably, as character detail). The apron ties, if the character-artist
chooses to add a back apron strap, would be visible here — this is an open
design choice flagged to the character-artist (see Open Notes). The back of
the head shows a bald or extremely close-cropped scalp — no hair. Ears
are small and pressed flat, barely readable at game camera distance. Spine
curve from hunch is visible: upper back is convex, pushing the head forward.

### Three-Quarter View (45 degrees, front-left — hook-arm side forward)

This is the hero select/portrait angle. The raised hook arm reads as the
primary silhouette spike. The hook J-curve is visible in semi-profile — the
curved tip reads as a distinct shape landmark. The belly's forward protrusion
and the head's forward position are both visible simultaneously, selling the
hunch. The asymmetric eyes are most readable from this angle — the large left
eye catches the light while the smaller right eye is partly in shadow. The
grin is angled slightly toward the viewer. The chain drape from fist to hip
is in near-full view. The cleaver in the right hand is visible behind the
torso on the far side. This is the angle the character-artist should use for
the primary sculpt review pass.

---

## Open Notes for Next Stages

### For `character-artist`

1. **Apron decision**: The brief does not specify a front/back apron, but a
   blood-stained butcher's apron (even a stub of it tucked under the belt)
   would add texture variety and a readable material zone. Flag to art director
   before sculpting; do not add without sign-off as it affects material count.
2. **Teeth geometry**: At 6k-8k tri budget, individual tooth geometry is
   expensive. Recommendation: sculpt teeth as a single low-poly row with the
   grin shape baked into base color at the face level. The mouth opening should
   be a recessed dark interior; the tooth row is painted, not individually
   modeled. Confirm with art director.
3. **Hook arm mass difference**: The left arm is specified as "chunkier." In
   the sculpt this should be a meaningful difference — at least 15-20% larger
   radius at forearm and bicep — not a subtle variation. The asymmetry must
   be visible at game camera distance.
4. **No-neck hunch**: The brief calls for "almost no neck." In the sculpt,
   the trapezius/shoulder mass should merge directly into the base of the
   skull with at most 1-2 cm of visible neck column. This is an extreme chibi
   compression — ensure it is not softened during retopo.
5. **Boot toe splaying**: Ratty boots that are "slightly too small" should show
   toes pressing against the front of the boot — the boot box front face has a
   slight outward bulge or seam stress line at the toe area. This is a sculpt
   detail that does not survive to LOD1+ but adds personality at LOD0.
6. **Bind pose vs. rest pose for Proposal B**: If B is chosen, clarify with
   rigger whether the raised arm is authored as the bind pose or driven by a
   rest pose animation layer. Recommendation: keep bind pose at A-pose per
   brief, drive the raised-arm rest through an idle animation clip.

### For `texture-artist`

1. **Tint channel separation**: The skin base color must be a neutral desaturated
   tone (see material table). Do not bake any green into the base color — the
   team tint shader provides that. Test the material under three tint values
   (green, red, blue) before finalizing the base color map.
2. **Emissive isolation**: The emissive map should contain ONLY the eye sclera
   region. Nothing else should be emissive. Eyes are the only "screen-readable
   at distance" element that needs to glow; everything else relies on the scene
   lighting.
3. **Chain links**: At 512px hook prop texture, individual chain link detail
   is approximately 8-12 px per link. Hand-paint the highlight on the upper
   face of each link; do not rely on the normal map alone — at mobile renderer
   settings the normal detail at this texel density may not resolve.
4. **Blood placement**: Dried blood belongs on the hook tip inner curve only.
   A small fresh-blood streak as a secondary value. Do not blood-paint the
   chain links — the brief establishes "iron links," not gore-covered chains.
   Keep it readable as iron for material clarity.
5. **ORM packing**: Confirm the AO bake is authored in Blender with the full
   chain-and-body scene so the chain casts AO onto the hook hand socket area.
   Do not bake AO on body and prop separately — the hand-to-hook contact zone
   will have incorrect AO if baked isolated.

### For `rigging-animator`

1. **Belly jiggle bone**: The brief specifies one belly jiggle bone. Drive it
   from the Hips bone with a spring/lag constraint rather than authored
   keyframes if the engine supports it. Godot 4.6's restored IK
   (`SkeletonModification3D`) is confirmed in the brief — test whether a
   spring-based modifier can drive the belly bone, reducing animation workload.
2. **Hook chain simulation**: The chain between hand and belt is a visual
   element. For the LOD0 idle, a small number of animated chain bones (3-4
   matching the 3-4 visible links in the brief) would give organic sway. Budget:
   3 extra chain bones. These collapse to static at LOD1.
3. **Death animation detail**: The brief specifies "gut deflates last" in the
   death clip. This requires the belly jiggle bone to also be keyframed during
   the death — a secondary squash on the belly sphere after the body falls.
   Flag to animator as a non-trivial key to get right.
4. **Hook throw event marker**: The brief specifies a `hook_release` event
   marker at the moment the hook leaves the hand. In Godot 4.6 this is an
   Animation track event. Confirm the marker fires on the correct frame with
   the gameplay programmer before finalizing the animation.
5. **IK ground adaptation**: Brief specifies 2-bone IK on each leg for ground
   adapt. Given the squat-forward stance of Proposal B or C, ensure the IK
   rest target is set to the boot sole position in the authored pose, not the
   default straight-leg position. Pudge should not straighten his legs when
   walking on flat ground.
