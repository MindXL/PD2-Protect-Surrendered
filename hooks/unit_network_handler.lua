-- Block hurt/death actions and damage network messages for protected
-- (surrendered) units arriving from remote peers.
--
-- PD2's networking has TWO separate paths for damage:
--   1. damage_bullet / damage_fire / ... → sync_damage_* (game-state damage)
--   2. action_hurt_start                  (hurt/death animation)
-- Both originate from the shooting client independently, so blocking only
-- sync_damage_* leaves the death animation playing on the host. This hook
-- catches the animation path.

local _original_action_hurt_start = UnitNetworkHandler.action_hurt_start
function UnitNetworkHandler:action_hurt_start(unit, hurt_type, body_part, death_type, type, variant, direction_vec, hit_pos)
	if alive(unit) and unit:character_damage() and ProtectSurrendered.is_protected(unit) then
		return
	end
	return _original_action_hurt_start(self, unit, hurt_type, body_part, death_type, type, variant, direction_vec, hit_pos)
end

-- Also block the UnitNetworkHandler:damage_* entry points themselves so that
-- no side-effects from the handler run before sync_damage_* is even reached.

local _original_net_damage_bullet = UnitNetworkHandler.damage_bullet
function UnitNetworkHandler:damage_bullet(subject_unit, attacker_unit, damage, i_body, height_offset, variant, death, sender)
	if alive(subject_unit) and subject_unit:character_damage() and ProtectSurrendered.is_protected(subject_unit) then
		return
	end
	return _original_net_damage_bullet(self, subject_unit, attacker_unit, damage, i_body, height_offset, variant, death, sender)
end

local _original_net_damage_melee = UnitNetworkHandler.damage_melee
function UnitNetworkHandler:damage_melee(subject_unit, attacker_unit, damage, damage_effect, i_body, height_offset, variant, death, sender)
	if alive(subject_unit) and subject_unit:character_damage() and ProtectSurrendered.is_protected(subject_unit) then
		return
	end
	return _original_net_damage_melee(self, subject_unit, attacker_unit, damage, damage_effect, i_body, height_offset, variant, death, sender)
end

local _original_net_damage_fire = UnitNetworkHandler.damage_fire
function UnitNetworkHandler:damage_fire(subject_unit, attacker_unit, damage, start_dot_dance_antimation, death, direction, weapon_type, weapon_unit, healed, sender)
	if alive(subject_unit) and subject_unit:character_damage() and ProtectSurrendered.is_protected(subject_unit) then
		return
	end
	return _original_net_damage_fire(self, subject_unit, attacker_unit, damage, start_dot_dance_antimation, death, direction, weapon_type, weapon_unit, healed, sender)
end

local _original_net_damage_explosion_fire = UnitNetworkHandler.damage_explosion_fire
function UnitNetworkHandler:damage_explosion_fire(subject_unit, attacker_unit, damage, i_attack_variant, death, direction, weapon_unit, sender)
	if alive(subject_unit) and subject_unit:character_damage() and ProtectSurrendered.is_protected(subject_unit) then
		return
	end
	return _original_net_damage_explosion_fire(self, subject_unit, attacker_unit, damage, i_attack_variant, death, direction, weapon_unit, sender)
end

local _original_net_damage_explosion_stun = UnitNetworkHandler.damage_explosion_stun
function UnitNetworkHandler:damage_explosion_stun(subject_unit, attacker_unit, damage, i_attack_variant, death, direction, sender)
	if alive(subject_unit) and subject_unit:character_damage() and ProtectSurrendered.is_protected(subject_unit) then
		return
	end
	return _original_net_damage_explosion_stun(self, subject_unit, attacker_unit, damage, i_attack_variant, death, direction, sender)
end

local _original_net_damage_tase = UnitNetworkHandler.damage_tase
function UnitNetworkHandler:damage_tase(subject_unit, attacker_unit, damage, variant, death, sender)
	if alive(subject_unit) and subject_unit:character_damage() and ProtectSurrendered.is_protected(subject_unit) then
		return
	end
	return _original_net_damage_tase(self, subject_unit, attacker_unit, damage, variant, death, sender)
end

local _original_net_damage_dot = UnitNetworkHandler.damage_dot
function UnitNetworkHandler:damage_dot(subject_unit, attacker_unit, damage, death, variant, hurt_animation, weapon_id, sender)
	if alive(subject_unit) and subject_unit:character_damage() and ProtectSurrendered.is_protected(subject_unit) then
		return
	end
	return _original_net_damage_dot(self, subject_unit, attacker_unit, damage, death, variant, hurt_animation, weapon_id, sender)
end

local _original_net_damage_simple = UnitNetworkHandler.damage_simple
function UnitNetworkHandler:damage_simple(subject_unit, attacker_unit, damage, i_attack_variant, i_result, death, sender)
	if alive(subject_unit) and subject_unit:character_damage() and ProtectSurrendered.is_protected(subject_unit) then
		return
	end
	return _original_net_damage_simple(self, subject_unit, attacker_unit, damage, i_attack_variant, i_result, death, sender)
end
