-- When the game transitions from stealth to loud, units that surrendered
-- during stealth still have their original collision slot. Register a
-- "whisper_mode" listener via GroupAIStateBase's built-in event system to
-- update all surrendered units to Slot 22 at that moment.

Hooks:PostHook(GroupAIStateBase, "init", "ProtectSurrendered_GroupAIInit", function(self)
	self:add_listener("ProtectSurrendered_whisper", { "whisper_mode" }, function(enabled)
		if not enabled then
			ProtectSurrendered._update_surrendered_slots()
		end
	end)
end)
