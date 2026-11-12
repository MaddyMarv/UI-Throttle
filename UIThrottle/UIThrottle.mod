return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`UIThrottle` encountered an error loading the Darktide Mod Framework.")

		new_mod("UIThrottle", {
			mod_script       = "UIThrottle/scripts/mods/UIThrottle/UIThrottle",
			mod_data         = "UIThrottle/scripts/mods/UIThrottle/UIThrottle_data",
			mod_localization = "UIThrottle/scripts/mods/UIThrottle/UIThrottle_localization",
		})
	end,
	packages = {},
}
