return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`UIThrottle` mod must be lower than DMF in load order.")

		new_mod("UIThrottle", {
			mod_script       = "UIThrottle/scripts/mods/UIThrottle/UIThrottle",
			mod_data         = "UIThrottle/scripts/mods/UIThrottle/UIThrottle_data",
			mod_localization = "UIThrottle/scripts/mods/UIThrottle/UIThrottle_localization",
		})
	end,
	packages = {},
}
