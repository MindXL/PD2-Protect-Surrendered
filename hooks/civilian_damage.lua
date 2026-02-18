-- CivilianDamage overrides several CopDamage methods with its own logic
-- (e.g. civ_harmless_bullets check). We must intercept at this level so the
-- protection check runs before any civilian-specific handling.

-- Hook CivilianDamage:damage_bullet
local _original_civ_damage_bullet = CivilianDamage.damage_bullet
function CivilianDamage:damage_bullet(attack_data)
	if ProtectSurrendered.is_protected(self._unit) then
		return
	end
	return _original_civ_damage_bullet(self, attack_data)
end

-- Hook CivilianDamage:damage_melee
local _original_civ_damage_melee = CivilianDamage.damage_melee
function CivilianDamage:damage_melee(attack_data)
	if ProtectSurrendered.is_protected(self._unit) then
		return
	end
	return _original_civ_damage_melee(self, attack_data)
end

-- Hook CivilianDamage:damage_fire
local _original_civ_damage_fire = CivilianDamage.damage_fire
function CivilianDamage:damage_fire(attack_data)
	if ProtectSurrendered.is_protected(self._unit) then
		return
	end
	return _original_civ_damage_fire(self, attack_data)
end

-- Hook CivilianDamage:damage_explosion
local _original_civ_damage_explosion = CivilianDamage.damage_explosion
function CivilianDamage:damage_explosion(attack_data)
	if ProtectSurrendered.is_protected(self._unit) then
		return
	end
	return _original_civ_damage_explosion(self, attack_data)
end
