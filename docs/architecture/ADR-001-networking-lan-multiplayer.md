# ADR-001: LAN Multiplayer Architecture

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-04-03 |
| **Decision Makers** | technical-director, lead-programmer |
| **Sprint** | Sprint 3 |

## Context

The game needs multiplayer support for playtesting. Sprint 3 targets LAN play
(two players on the same network). The architecture must support future online
play (Sprint 4+) without a full rewrite.

### Requirements
- 2-player LAN matches (expandable to team sizes later)
- Server-authoritative match state (scores, kills, timer, match flow)
- Low-latency hook projectile sync (critical for skillshot gameplay)
- Host/join lobby with hero selection and ready state
- Graceful disconnect handling

## Decision

**Use Godot's built-in ENetMultiplayerPeer with a host-as-server model.**

### Architecture

```
Host (Server + Player 1)          Client (Player 2)
┌─────────────────────┐          ┌─────────────────────┐
│ MatchStateManager   │◄────────►│ MatchStateManager   │
│   (authoritative)   │  RPCs    │   (receives state)  │
│ ScoreSystem         │          │ ScoreSystem         │
│   (authoritative)   │          │   (receives state)  │
│ Player1 (local)     │          │ Player2 (local)     │
│ Player2 (remote)    │          │ Player1 (remote)    │
└─────────────────────┘          └─────────────────────┘
```

### Authority Model

| System | Authority | Sync Method | Rationale |
|--------|-----------|-------------|-----------|
| **Movement** | Client-authoritative | MultiplayerSynchronizer (unreliable) | LAN latency <5ms; trust is acceptable. Simplifies implementation. |
| **Hook Fire** | Client-authoritative (fire event) | RPC (reliable) | Client sends fire direction; all peers simulate projectile locally. |
| **Hook Hit Detection** | Server-authoritative | RPC (reliable) | Server validates hit, broadcasts result. Prevents desync on kills. |
| **Health/Damage** | Server-authoritative | RPC (reliable) | All damage applied on server, synced to clients. |
| **Match State** | Server-authoritative | RPC (reliable) | Timer, scores, state transitions owned by host. |
| **Respawn** | Server-authoritative | RPC (reliable) | Server controls respawn timing and spawn point. |
| **Lobby/Ready** | Server-authoritative | RPC (reliable) | Host controls match start. |

### Networking Layer Design

```
NetworkManager (Autoload)
├── Manages ENetMultiplayerPeer lifecycle
├── Handles peer connect/disconnect
├── Provides is_host() / is_client() / get_local_peer_id()
└── Emits: player_joined, player_left, connection_failed

LobbyManager (Scene)
├── Hero selection per player
├── Ready state tracking
├── IP display (host) / IP input (client)
└── Emits: all_ready, lobby_closed

GameSession (Scene — replaces single-player Main)
├── Spawns PlayerController per connected peer
├── Sets multiplayer authority per player node
├── Routes signals through RPCs where needed
└── Manages networked versions of existing systems
```

### Hook Projectile Sync Strategy

Hooks are the core mechanic. Sync strategy prioritizes visual consistency:

1. **Fire**: Client sends `fire_hook.rpc(direction)` to server
2. **Server broadcasts**: `_on_hook_fired.rpc(peer_id, direction)` to all
3. **Each client simulates** the projectile locally (same speed, same direction)
4. **Hit detection**: Server runs authoritative hit check
5. **Result**: Server broadcasts `hook_hit.rpc(target_id)` or `hook_missed.rpc()`

This avoids syncing projectile position every frame (which would jitter on LAN)
and keeps the visual smooth on all clients.

## Alternatives Considered

### 1. WebRTC (Peer-to-Peer)
- **Pro**: No dedicated server needed, works better for NAT traversal
- **Con**: More complex setup, Godot's WebRTC support is less mature than ENet
- **Con**: Still need a signaling server for connection setup
- **Verdict**: Overkill for LAN. Reconsider for online play in Sprint 4.

### 2. Full Server-Authoritative (including movement)
- **Pro**: Maximum security, no cheating possible
- **Con**: Requires client-side prediction and reconciliation for movement
- **Con**: Significantly more complex for Sprint 3 scope
- **Verdict**: Not needed for LAN (trusted environment). Add prediction later for online.

### 3. Lockstep / Deterministic
- **Pro**: Minimal bandwidth, perfect sync
- **Con**: Requires deterministic physics, floating-point consistency
- **Con**: Godot's physics engine is not deterministic
- **Verdict**: Not viable with Godot's physics pipeline.

## Consequences

### Positive
- Uses well-tested Godot networking primitives (ENet, RPCs, MultiplayerSynchronizer)
- Existing single-player systems need minimal refactoring — add RPCs to existing signals
- Hook sync strategy avoids per-frame position sync (bandwidth friendly)
- Clear upgrade path to online: swap ENetMultiplayerPeer for WebSocketMultiplayerPeer or relay

### Negative
- Client-authoritative movement is exploitable (acceptable for LAN, must change for online)
- Host has inherent latency advantage (0ms vs ~1-5ms on LAN — negligible)
- Host crash ends the game for all players (no host migration in Sprint 3)

### Migration to Online (Sprint 4+)
- Add client-side prediction for movement
- Move hit detection fully server-side with lag compensation
- Add relay server or NAT punch-through
- Add authentication layer

## Implementation Plan

1. Create `NetworkManager` autoload (S3-04)
2. Create `LobbyManager` scene with host/join UI (S3-05)
3. Refactor `Main` → `GameSession` to spawn players per peer (S3-04)
4. Add RPCs to `MatchStateManager`, `ScoreSystem`, `RespawnSystem` (S3-06)
5. Implement hook fire/hit RPCs in `HookSystem` (S3-06)
6. Add `MultiplayerSynchronizer` to `PlayerController` for position (S3-04)
