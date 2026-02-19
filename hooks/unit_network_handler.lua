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
local function _should_block_network_damage(unit)
	-- character_damage() guard avoids touching non-combat units accidentally.
	return alive(unit) and unit:character_damage() and ProtectSurrendered.is_protected(unit)
end

local function _log_blocked_network_damage(unit, handler_name)
	ProtectSurrendered._log("Blocked net:" .. handler_name .. " on " .. ProtectSurrendered._unit_id(unit))
end

function UnitNetworkHandler:action_hurt_start(
	unit,
	hurt_type,
	body_part,
	death_type,
	type,
	variant,
	direction_vec,
	hit_pos
)
	if _should_block_network_damage(unit) then
		_log_blocked_network_damage(unit, "action_hurt_start")
		return
	end
	return _original_action_hurt_start(
		self,
		unit,
		hurt_type,
		body_part,
		death_type,
		type,
		variant,
		direction_vec,
		hit_pos
	)
end

-- Also block the UnitNetworkHandler:damage_* entry points themselves so that
-- no side-effects from the handler run before sync_damage_* is even reached.

local function _bind_damage_handler(handler_name)
	local original = UnitNetworkHandler[handler_name]
	if type(original) ~= "function" then
		return
	end

	UnitNetworkHandler[handler_name] = function(self, subject_unit, ...)
		if _should_block_network_damage(subject_unit) then
			_log_blocked_network_damage(subject_unit, handler_name)
			return
		end
		return original(self, subject_unit, ...)
	end
end

local _damage_handlers = {
	"damage_bullet",
	"damage_melee",
	"damage_fire",
	"damage_explosion_fire",
	"damage_explosion_stun",
	"damage_tase",
	"damage_dot",
	"damage_simple",
}

for _, handler_name in ipairs(_damage_handlers) do
	_bind_damage_handler(handler_name)
end
