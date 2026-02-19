-- Block all damage types on CopDamage for surrendered / intimidated units.

local wrap = ProtectSurrendered.wrap_damage

wrap(CopDamage, "damage_bullet")
wrap(CopDamage, "damage_melee")
wrap(CopDamage, "damage_fire")
wrap(CopDamage, "damage_explosion")
wrap(CopDamage, "damage_tase")
