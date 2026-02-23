# Technical Details

This document describes how Protect Surrendered works internally and explains the networking limitations in multiplayer.

## Protection Criteria

A unit is protected when **all** of the following are true:

- The game is **not** in stealth (whisper) mode.
- The unit is **not** a converted cop (Joker).
- For enemies (cops): the unit is in `"intimidated"` logic **and** either:
  - `protect_surrendering_enemies` is enabled, or
  - the cop is fully surrendered (`internal_data.tied`).
- For civilians: the unit is in `"surrender"` brain logic (always protected in this logic state, regardless of enemy toggle).

## Damage Blocking — Local

The mod wraps every damage entry point on `CopDamage` and `CivilianDamage`:

| Function | Damage Type |
|---|---|
| `damage_bullet` | Bullets / projectiles |
| `damage_melee` | Melee attacks |
| `damage_fire` | Fire / incendiary |
| `damage_explosion` | Explosions |
| `damage_tase` | Taser |

Before the original function runs, `ProtectSurrendered.is_protected(unit)` checks whether the target should be immune. If so, the function returns early and no damage is dealt.

`CivilianDamage` overrides several `CopDamage` methods with its own logic (e.g. `civ_harmless_bullets` check), so the mod hooks both classes separately to ensure protection runs before any class-specific handling.

## Damage Blocking — Network

PAYDAY 2 has **two separate network paths** for damage from remote players:

1. **Game-state damage** — `UnitNetworkHandler:damage_bullet`, `damage_fire`, `damage_melee`, `damage_explosion_fire`, `damage_explosion_stun`, `damage_tase`, `damage_dot`, `damage_simple` → these call `CopDamage:sync_damage_*` to apply health changes.
2. **Hurt/death animation** — `UnitNetworkHandler:action_hurt_start` → this applies the hurt or death action on the unit's movement system, independently of path 1.

Both paths must be blocked. The mod hooks all `UnitNetworkHandler:damage_*` variants and `action_hurt_start` to return early when the target unit is protected. This prevents both the game-state damage and the death animation from being applied on the host.

## Bullet Pass-Through

PAYDAY 2 uses a **slot system** for physics collision. Weapon raycasts only test against specific slots (e.g. Slot 12 for active enemies). When an enemy enters the surrendered state in loud mode, the mod moves them to **Slot 22** (the same slot used for tied hostages), which is excluded from weapon raycast masks. This makes bullets physically pass through them. The game's own `CopLogicIntimidated.exit` restores Slot 12 when the unit leaves the intimidated state.

When the game transitions from stealth to loud, a `whisper_mode` event listener retroactively updates all currently surrendered units to Slot 22.

## Initialization

The mod uses a `pre_hook` on `lib/entry` to load `hooks/init.lua` before any other game scripts. This ensures the global `ProtectSurrendered` table and all shared functions (`is_protected`, `_update_surrendered_slots`) are available regardless of which hook fires first, avoiding load-order issues.

`ProtectSurrendered.wrap_damage(class, method_name)` also validates that the target method exists before wrapping. This keeps compatibility with game/mod variants where a method may be absent or overridden unexpectedly.

## Why Host-Only Installation Causes Visual Desync

PAYDAY 2 uses a **peer-to-peer** networking model built on the Diesel engine. When a player shoots, the game applies damage **locally first** for responsiveness, then broadcasts the result to other peers via `unit:network():send()`.

```
Player B shoots surrendered unit
  ├─ B applies damage locally → unit dies on B's screen
  ├─ B broadcasts to Host A → mod blocks damage ✓
  └─ B broadcasts to Player C → C has no mod → unit dies on C's screen ✗
```

The key constraint is that `unit:network():send()` delivers messages **directly between peers** — they are not relayed through the host. The host has no ability to intercept or suppress a message traveling from Player B to Player C. This is a Diesel engine limitation that cannot be worked around in Lua.

When all players have the mod installed, each player's local `damage_bullet` hook blocks the damage before it is applied, so no desync occurs.

## File Overview

| File | Purpose |
|---|---|
| `mod.txt` | SuperBLT mod definition — 1 pre-hook + 5 hook entries |
| `hooks/init.lua` | Early initialization — global table, `is_protected()` check, `_update_surrendered_slots()` |
| `hooks/cop_damage.lua` | Wraps 5 `CopDamage` damage functions to block local damage on protected units |
| `hooks/civilian_damage.lua` | Wraps 4 `CivilianDamage` damage functions to block local damage on protected civilians |
| `hooks/unit_network_handler.lua` | Wraps 8 `UnitNetworkHandler` damage handlers + `action_hurt_start` to block remote damage and death animations |
| `hooks/cop_logic_intimidated.lua` | PostHook on `CopLogicIntimidated.enter` — moves surrendered units to Slot 22 |
| `hooks/group_ai_state.lua` | PostHook on `GroupAIStateBase.init` — registers `whisper_mode` listener for stealth-to-loud slot update |
