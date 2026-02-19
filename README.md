# PD2-Protect-Surrendered

A PAYDAY 2 mod that makes surrendered (intimidated) enemies and civilians immune to all damage in loud mode, and allows bullets to physically pass through them.

## Features

- **Full damage immunity** — Surrendered enemies and civilians cannot be harmed by bullets, melee, fire, explosions, or tasers.
- **Bullet penetration** — Bullets pass through surrendered units instead of stopping on contact, so they won't block your shots at active threats behind them.
- **Covers the entire surrender sequence** — Protection kicks in as soon as the enemy begins their surrender animation (hands up), not just after they are fully tied.
- **Multiplayer support** — Works in both singleplayer and multiplayer. See [Multiplayer Behavior](#multiplayer-behavior) for details.
- **Converted cops (Jokers) are unaffected** — Enemies that have been converted to fight for your team still take damage normally, matching vanilla behavior.
- **Stealth exception** — While the game is in stealth (whisper) mode, surrendered hostages and enemies remain vulnerable as usual.
- **Stealth-to-loud transition** — If enemies surrendered during stealth and the alarm is then raised, the mod retroactively updates them so bullets pass through.

## Requirements

- [SuperBLT](https://superblt.znix.xyz/) (or compatible BLT mod loader)

## Installation

1. Download or clone this repository.
2. Copy the `ProtectSurrendered` folder into your PAYDAY 2 `mods/` directory.
3. Launch the game. SuperBLT will load the mod automatically.

```
PAYDAY 2/
  mods/
    ProtectSurrendered/
      mod.txt
      hooks/
        init.lua
        cop_damage.lua
        civilian_damage.lua
        cop_logic_intimidated.lua
        group_ai_state.lua
        unit_network_handler.lua
```

## Multiplayer Behavior

### Recommended: all players install the mod

When every player in the lobby has the mod installed, protection works perfectly on all machines — no one can damage surrendered units, and there are no visual desyncs.

### Host-only installation

If only the **host** has the mod installed:

- **Host** — Fully protected. Surrendered units cannot be damaged or killed by anyone. The authoritative game state (health, alive/dead, mission objectives) is always correct.
- **Other players** — They may see surrendered units take damage or die on their own screens. This is a visual desync only; the host's game state remains correct, so missions will not fail due to "killed" hostages, and surrendered units will continue to function.

### Why other players see a desync

PAYDAY 2 uses a **peer-to-peer** networking model. When a player shoots, the game applies damage **locally first** for responsiveness, then sends the result to other peers.

```
Player B shoots surrendered unit
  ├─ B applies damage locally → unit dies on B's screen
  ├─ B broadcasts to Host A → mod blocks damage ✓
  └─ B broadcasts to Player C → C has no mod → unit dies on C's screen ✗
```

The Diesel engine's `unit:network():send()` delivers messages **directly between peers**, not relayed through the host. The host cannot intercept or suppress messages that travel from one client to another.

## How It Works

### Protection Criteria

A unit is protected when **all** of the following are true:

- The game is **not** in stealth (whisper) mode.
- The unit is **not** a converted cop (Joker).
- The unit is in the `"intimidated"` brain logic (cops), the `"surrender"` brain logic (civilians), **or** is playing a surrender animation (`surrender`, `hands_up`, `hands_back`, `hands_tied`).

### Damage Blocking — Local (host player)

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

### Damage Blocking — Network (other players' damage)

PAYDAY 2 has **two separate network paths** for damage from remote players:

1. **Game-state damage** — `UnitNetworkHandler:damage_bullet`, `damage_fire`, `damage_melee`, `damage_explosion_fire`, `damage_explosion_stun`, `damage_tase`, `damage_dot`, `damage_simple` → these call `CopDamage:sync_damage_*` to apply health changes.
2. **Hurt/death animation** — `UnitNetworkHandler:action_hurt_start` → this applies the hurt or death action on the unit's movement system, independently of path 1.

Both paths must be blocked. The mod hooks all `UnitNetworkHandler:damage_*` variants and `action_hurt_start` to return early when the target unit is protected. This prevents both the game-state damage and the death animation from being applied on the host.

### Bullet Pass-Through

PAYDAY 2 uses a **slot system** for physics collision. Weapon raycasts only test against specific slots (e.g. Slot 12 for active enemies). When an enemy enters the surrendered state in loud mode, the mod moves them to **Slot 22** (the same slot used for tied hostages), which is excluded from weapon raycast masks. This makes bullets physically pass through them. The game's own `CopLogicIntimidated.exit` restores Slot 12 when the unit leaves the intimidated state.

When the game transitions from stealth to loud, a `whisper_mode` event listener retroactively updates all currently surrendered units to Slot 22.

### Initialization

The mod uses a `pre_hook` on `lib/entry` to load `hooks/init.lua` before any other game scripts. This ensures the global `ProtectSurrendered` table and all shared functions (`is_protected`, `_update_surrendered_slots`) are available regardless of which hook fires first, avoiding load-order issues.

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

## License

This mod is provided as-is for personal use. Feel free to modify and redistribute.
