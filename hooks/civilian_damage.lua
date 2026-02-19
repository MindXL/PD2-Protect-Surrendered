-- CivilianDamage overrides several CopDamage methods with its own logic
-- (e.g. civ_harmless_bullets check). We must intercept at this level so the
-- protection check runs before any civilian-specific handling.
--
-- damage_tase is intentionally NOT wrapped: the official CivilianDamage
-- implementation does not deal damage — it only triggers intimidation.

local wrap = ProtectSurrendered.wrap_damage

wrap(CivilianDamage, "damage_bullet")
wrap(CivilianDamage, "damage_melee")
wrap(CivilianDamage, "damage_fire")
wrap(CivilianDamage, "damage_explosion")
