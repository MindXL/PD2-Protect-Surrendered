-- Early initialization via pre_hook.
-- This script runs before any game script that our hooks depend on, ensuring
-- the global ProtectSurrendered table and all shared functions are available
-- regardless of which hook fires first.

ProtectSurrendered = ProtectSurrendered or {}

-- Returns true if the unit should be immune to all damage:
--   - Must be alive
--   - Game must NOT be in stealth (whisper) mode
--   - Unit must NOT be a converted cop (Joker)
--   - Unit must be in a surrendered / intimidated state
function ProtectSurrendered.is_protected(unit)
	if not alive(unit) then
		return false
	end

	local groupai = managers and managers.groupai
	local group_state = groupai and groupai:state()
	if not group_state then
		return false
	end

	-- In stealth, surrendered hostages / enemies remain vulnerable
	if group_state:whisper_mode() then
		return false
	end

	local brain = unit:brain()
	if not brain then
		return false
	end

	-- Converted (Joker) cops take damage normally
	if brain._logic_data and brain._logic_data.is_converted then
		return false
	end

	-- Cop brain: "intimidated" logic
	if brain.surrendered and brain:surrendered() then
		return true
	end

	-- Civilian brain: "surrender" logic
	if brain.is_current_logic and brain:is_current_logic("surrender") then
		return true
	end

	-- Fallback: check animation states that indicate an ongoing surrender sequence
	-- (hands_up -> hands_back -> hands_tied)
	local anim = unit.anim_data and unit:anim_data()
	if anim and (anim.surrender or anim.hands_up or anim.hands_back or anim.hands_tied) then
		return true
	end

	return false
end

-- Wraps a damage method on `class` so that calls on protected units are
-- silently dropped. All wrapped damage functions share the same signature
-- (self, attack_data), which is verified by the game source for every
-- CopDamage / CivilianDamage damage_* method.
function ProtectSurrendered.wrap_damage(class, method_name)
	local original = class[method_name]
	class[method_name] = function(self, attack_data)
		if ProtectSurrendered.is_protected(self._unit) then
			return
		end
		return original(self, attack_data)
	end
end

-- Called when the game transitions from stealth to loud.
-- Moves all currently surrendered units to Slot 22 so bullets pass through.
function ProtectSurrendered._update_surrendered_slots()
	local enemy_manager = managers and managers.enemy
	if not enemy_manager then
		return
	end

	-- Update surrendered enemies (cops)
	local enemies = enemy_manager:all_enemies() or {}
	for _, u_data in pairs(enemies) do
		local unit = u_data.unit
		local brain = alive(unit) and unit.brain and unit:brain()
		if brain then
			if brain.surrendered and brain:surrendered() then
				local is_converted = brain._logic_data and brain._logic_data.is_converted
				if not is_converted then
					unit:base():set_slot(unit, 22)
				end
			end
		end
	end

	-- Update surrendered civilians
	local civilians = enemy_manager:all_civilians() or {}
	for _, u_data in pairs(civilians) do
		local unit = u_data.unit
		local brain = alive(unit) and unit.brain and unit:brain()
		if brain then
			if brain.is_current_logic and brain:is_current_logic("surrender") then
				unit:base():set_slot(unit, 22)
			end
		end
	end
end
