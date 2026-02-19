-- Build a BLT options menu.
local MENU_ID = "protect_surrendered_menu"

Hooks:Add("LocalizationManagerPostInit", "ProtectSurrendered_Localization", function(loc)
	loc:add_localized_strings({
		protect_surrendered_menu_title = "Protect Surrendered",
		protect_surrendered_menu_desc = "Options for Protect Surrendered.",
		protect_surrendered_debug_title = "Enable debug logs",
		protect_surrendered_debug_desc = "Show debug logs in BLT log and local chat window.",
	})
end)

Hooks:Add("MenuManagerInitialize", "ProtectSurrendered_MenuInit", function(menu_manager)
	MenuCallbackHandler.ProtectSurrendered_SetDebug = function(self, item)
		-- BLT toggle values can arrive as booleans, strings, or numbers.
		local value = item:value()
		local enabled = value == true or value == "on" or value == "true" or value == 1
		ProtectSurrendered.set_debug(enabled, true)
	end
end)

Hooks:Add("MenuManagerSetupCustomMenus", "ProtectSurrendered_SetupMenu", function(menu_manager, nodes)
	MenuHelper:NewMenu(MENU_ID)
end)

Hooks:Add("MenuManagerPopulateCustomMenus", "ProtectSurrendered_PopulateMenu", function(menu_manager, nodes)
	MenuHelper:AddToggle({
		id = "protect_surrendered_debug_toggle",
		title = "protect_surrendered_debug_title",
		desc = "protect_surrendered_debug_desc",
		callback = "ProtectSurrendered_SetDebug",
		value = ProtectSurrendered._settings.debug == true,
		menu_id = MENU_ID,
		priority = 100,
	})
end)

Hooks:Add("MenuManagerBuildCustomMenus", "ProtectSurrendered_BuildMenu", function(menu_manager, nodes)
	nodes[MENU_ID] = MenuHelper:BuildMenu(MENU_ID)

	-- Different BLT forks expose different parent option nodes.
	local parent = nodes.blt_options or nodes.lua_mod_options_menu or nodes.options
	if parent then
		MenuHelper:AddMenuItem(parent, MENU_ID, "protect_surrendered_menu_title", "protect_surrendered_menu_desc")
	else
		ProtectSurrendered._log("No compatible parent menu node found")
	end
end)
