-- Early initialization via pre_hook.
-- This script runs before any game script that our hooks depend on, ensuring
-- the global ProtectSurrendered table and all shared functions are available
-- regardless of which hook fires first.

ProtectSurrendered = ProtectSurrendered or {}

ProtectSurrendered._save_path = (SavePath or "") .. "protect_surrendered_settings.json"
ProtectSurrendered._settings = ProtectSurrendered._settings
	or {
		protect_surrendering_enemies = false,
		debug = false,
	}

local _LOG_PREFIX = "[ProtectSurrendered] "

-- Sends a local system-chat message when chat APIs are available.
-- Safe no-op if chat is unavailable in the current game/menu state.
function ProtectSurrendered._chat(msg)
	local chat_manager = managers and managers.chat
	if not chat_manager or not chat_manager._receive_message then
		return
	end

	local channel_id = (ChatManager and ChatManager.GAME) or 1
	local color = (tweak_data and tweak_data.system_chat_color) or nil
	chat_manager:_receive_message(channel_id, "ProtectSurrendered", msg, color)
end

-- Emits debug output only when the runtime debug toggle is enabled.
function ProtectSurrendered._log(msg)
	if ProtectSurrendered._settings.debug == true then
		ProtectSurrendered._announce(msg)
	end
end

-- Broadcast helper used by debug/status flows:
-- writes to BLT log and mirrors to local chat for quick visibility.
function ProtectSurrendered._announce(msg)
	log(_LOG_PREFIX .. msg)
	ProtectSurrendered._chat(msg)
end

-- Returns a stable, human-readable unit label for diagnostics.
-- Prefers tweak table names and falls back to unit:name().
function ProtectSurrendered._unit_id(unit)
	if not alive(unit) then
		return "<dead>"
	end
	local base = unit:base()
	local tweak = base and base._tweak_table
	return tweak or tostring(unit:name())
end

function ProtectSurrendered.load_settings()
	local file = io.open(ProtectSurrendered._save_path, "r")
	if file then
		local raw = file:read("*all")
		file:close()

		if raw and raw ~= "" then
			local ok, data = pcall(json.decode, raw)
			if ok and type(data) == "table" then
				ProtectSurrendered._settings.protect_surrendering_enemies = data.protect_surrendering_enemies == true
				ProtectSurrendered._settings.debug = data.debug == true
			end
		end
	end
end

function ProtectSurrendered.save_settings()
	local file = io.open(ProtectSurrendered._save_path, "w+")
	if not file then
		return
	end
	file:write(json.encode(ProtectSurrendered._settings))
	file:close()
end

function ProtectSurrendered.set_protect_surrendering_enemies(enabled, announce)
	local value = enabled == true
	ProtectSurrendered._settings.protect_surrendering_enemies = value
	ProtectSurrendered.save_settings()

	if announce then
		local state = value and "enabled" or "disabled"
		ProtectSurrendered._announce("Protect surrendering enemies " .. state .. " via menu")
	end
end

function ProtectSurrendered.set_debug(enabled, announce)
	local value = enabled == true
	ProtectSurrendered._settings.debug = value
	ProtectSurrendered.save_settings()

	if announce then
		local state = value and "enabled" or "disabled"
		ProtectSurrendered._announce("DEBUG " .. state .. " via menu")
	end
end

ProtectSurrendered.load_settings()

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
		if ProtectSurrendered._settings.protect_surrendering_enemies == true then
			return true
		end

		-- Strict mode for enemies: only protect fully surrendered (tied) cops.
		local logic_data = brain._logic_data
		local internal = logic_data and logic_data.internal_data
		if internal and internal.tied then
			return true
		end
	end

	-- Civilian brain: "surrender" logic
	if brain.is_current_logic and brain:is_current_logic("surrender") then
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
	if type(original) ~= "function" then
		return
	end
	class[method_name] = function(self, attack_data)
		if ProtectSurrendered.is_protected(self._unit) then
			ProtectSurrendered._log("Blocked " .. method_name .. " on " .. ProtectSurrendered._unit_id(self._unit))
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

	local function _apply_slot_to_units(units, should_update)
		for _, u_data in pairs(units) do
			local unit = u_data.unit
			local brain = alive(unit) and unit.brain and unit:brain()
			if brain and should_update(brain) then
				ProtectSurrendered._log("Slot -> 22 (stealth transition): " .. ProtectSurrendered._unit_id(unit))
				unit:base():set_slot(unit, 22)
			end
		end
	end

	-- Update surrendered enemies (cops)
	_apply_slot_to_units(enemy_manager:all_enemies() or {}, function(brain)
		if not (brain.surrendered and brain:surrendered()) then
			return false
		end
		return not (brain._logic_data and brain._logic_data.is_converted)
	end)

	-- Update surrendered civilians
	_apply_slot_to_units(enemy_manager:all_civilians() or {}, function(brain)
		return brain.is_current_logic and brain:is_current_logic("surrender")
	end)
end
