-- Move surrendered enemies to Slot 22 (not in weapon raycast masks) so bullets
-- pass through them. Only applied in loud mode; in stealth the slot stays
-- unchanged so bullets still connect. The original CopLogicIntimidated.exit
-- restores Slot 12 when the unit leaves the intimidated state.

Hooks:PostHook(CopLogicIntimidated, "enter", "ProtectSurrendered_IntimidatedEnter", function(data, new_logic_name, enter_params)
	local groupai = managers and managers.groupai
	local group_state = groupai and groupai:state()
	if group_state and not group_state:whisper_mode() and alive(data.unit) then
		ProtectSurrendered._log("Slot -> 22 (intimidated enter): " .. ProtectSurrendered._unit_id(data.unit))
		data.unit:base():set_slot(data.unit, 22)
	end
end)
