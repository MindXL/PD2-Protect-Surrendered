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

This is a fundamental limitation of PAYDAY 2's peer-to-peer networking — see [TECHNICAL.md](TECHNICAL.md) for a full explanation.
