## Prototype Report: Hook Aiming

### Hypothesis
The "joystick controls both movement and aim direction" control scheme will feel
natural and satisfying on mobile touchscreen, making hook-based PvP viable as a
core mechanic.

### Approach
Built a minimal Godot 4.6 prototype with:
- 3D arena with left-right layout: Team A (left) vs Team B (right), gap in the middle
- Player (blue capsule) on left side, 3 orange target dummies on the right side
- Fixed virtual joystick (left side) controlling movement + facing direction
- Hook button (right side, tap anywhere) fires red sphere projectile in facing direction
- Chain visual (red line) from player to hook during flight and return
- Pull mechanic: hit targets get pulled to player position, then respawn after 3s
- Hook return animation: hook flies back to player at 1.5x forward speed
- Player locked in place during hook flight and return
- Orthographic camera with fixed angle, smooth follow, offset toward gap
- Stats tracking on screen: hooks fired, hit, missed, accuracy %
- Invisible collision walls for arena boundaries and gap edges

### Result
**PROCEED** — The core mechanic feels good. Key observations:
- Joystick-as-aim is intuitive — movement IS aiming creates natural tension
- Lock-during-flight feels fair — commits the player, creates risk/reward
- Hook return animation adds satisfying feedback loop
- Left-to-right arena gives equal view of both sides
- Cross-gap hooks feel dramatic when pulling targets across

### Metrics
- Hook accuracy after practice: varies by target distance
- Time to feel competent: ~2-3 minutes
- Controls feel responsive and direct
- Left-right layout provides symmetric, fair viewing angle

### Recommendation: PROCEED

The core hypothesis is validated: hook-based combat with joystick-as-aim feels
satisfying. The "movement = aiming" creates the intended tension where positioning
for a hook means exposing yourself. The lock-during-flight adds meaningful risk to
every hook. The visual feedback (chain + return animation) makes each hook feel
impactful. Ready to move into production.

### If Proceeding
- Rewrite from scratch using proper Godot node architecture
- Separate scenes for Player, Hook, Arena, UI
- Use collision layers instead of manual distance checks
- Add proper physics-based hook collision (RayCast3D or Area3D)
- Implement sound effects (critical for hook feel — launch, travel, hit, miss, return)
- Add screen shake on hook hit
- Add slow-mo on long-range hits
- Profile on low-end Android for performance baseline
- Implement networking for multiplayer (server-authoritative hit detection)

### Lessons Learned
- Camera must use fixed rotation (not look_at every frame) to prevent view shifting
- Left-to-right arena orientation is better than diagonal for mobile isometric
- ISO_ANGLE = 0 with front-facing camera gives the most intuitive input mapping
- Hook return animation is important feedback — instant disappear feels broken
- Gap collision walls (invisible StaticBody3D) work well to block movement while allowing hooks through
