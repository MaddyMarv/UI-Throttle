local mod = get_mod("UIThrottle")

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "group_general",
				type = "group",
				sub_widgets = {
					{
						setting_id = "enable_hud_throttle",
						type = "checkbox",
						default_value = true,
						sub_widgets = {
							{
								setting_id = "general_hud_fps",
								type = "numeric",
								default_value = 30,
								range = { 0, 60 },
								decimals_number = 0,
								step_size_value = 1,
							},
						},
					},
					{
						setting_id = "bypass_in_menus",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "toggle_throttle_key",
						type = "keybind",
						default_value = {},
						keybind_global = true,
						keybind_trigger = "pressed",
						keybind_type = "function_call",
						function_name = "toggle_throttle",
					},
					{
						setting_id = "override_world_markers",
						type = "checkbox",
						default_value = true,
						sub_widgets = {
							{
								setting_id = "world_markers_fps",
								type = "numeric",
								default_value = 60,
								range = { 0, 120 },
								decimals_number = 0,
								step_size_value = 1,
							},
						},
					},
					{
						setting_id = "show_tick_echo",
						type = "checkbox",
						default_value = false,
					},
				},
			},
			{
				setting_id = "group_team",
				type = "group",
				sub_widgets = {
					{
						setting_id = "override_personal_player_panel",
						type = "checkbox",
						default_value = true,
						sub_widgets = {
							{
								setting_id = "personal_player_panel_fps",
								type = "numeric",
								default_value = 30,
								range = { 0, 60 },
								decimals_number = 0,
								step_size_value = 1,
							},
						},
					},
					{
						setting_id = "override_team_panels",
						type = "checkbox",
						default_value = true,
						sub_widgets = {
							{
								setting_id = "team_panels_fps",
								type = "numeric",
								default_value = 15,
								range = { 0, 60 },
								decimals_number = 0,
								step_size_value = 1,
							},
						},
					},
				},
			},
			{
				setting_id = "group_hud_studio",
				type = "group",
				sub_widgets = {
					{
						setting_id = "override_hud_studio",
						type = "checkbox",
						default_value = true,
						sub_widgets = {
							{
								setting_id = "hud_studio_fps",
								type = "numeric",
								default_value = 30,
								range = { 0, 60 },
								decimals_number = 0,
								step_size_value = 1,
							},
						},
					},
				},
			},
		},
	},
}
