-- Block all damage types on CopDamage for surrendered / intimidated units.
-- Each wrapper returns early when the target is protected, skipping the
-- original damage function entirely.

local _original_damage_bullet = CopDamage.damage_bullet
function CopDamage:damage_bullet(attack_data)
	if ProtectSurrendered.is_protected(self._unit) then
		return
	end
	return _original_damage_bullet(self, attack_data)
end

-- Hook CopDamage:damage_melee – blocks melee damage to protected units
local _original_damage_melee = CopDamage.damage_melee
function CopDamage:damage_melee(attack_data)
	if ProtectSurrendered.is_protected(self._unit) then
		return
	end
	return _original_damage_melee(self, attack_data)
end

-- Hook CopDamage:damage_fire – blocks fire/incendiary damage to protected units
local _original_damage_fire = CopDamage.damage_fire
function CopDamage:damage_fire(attack_data)
	if ProtectSurrendered.is_protected(self._unit) then
		return
	end
	return _original_damage_fire(self, attack_data)
end

-- Hook CopDamage:damage_explosion – blocks explosion damage to protected units
local _original_damage_explosion = CopDamage.damage_explosion
function CopDamage:damage_explosion(attack_data)
	if ProtectSurrendered.is_protected(self._unit) then
		return
	end
	return _original_damage_explosion(self, attack_data)
end

-- Hook CopDamage:damage_tase – blocks taser damage to protected units
local _original_damage_tase = CopDamage.damage_tase
function CopDamage:damage_tase(attack_data)
	if ProtectSurrendered.is_protected(self._unit) then
		return
	end
	return _original_damage_tase(self, attack_data)
end
