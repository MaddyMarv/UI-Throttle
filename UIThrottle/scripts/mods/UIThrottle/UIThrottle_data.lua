local mod = get_mod("UIThrottle")

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "general_settings",
				type = "group",
				tab = mod:localize("tab_general"),
				sub_widgets = {
					{
						setting_id = "enable_hud_throttle",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "general_hud_fps",
						type = "numeric",
						default_value = 30,
						range = { 0.2, 60 },
						decimals_number = 1,
						step_size_value = 0.5,
					},
					{
						setting_id = "override_world_markers",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "world_markers_fps",
						type = "numeric",
						default_value = 60,
						range = { 1, 120 },
						decimals_number = 0,
						step_size_value = 1,
					},
					{
						setting_id = "override_team_panels",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "team_panels_fps",
						type = "numeric",
						default_value = 1,
						range = { 0.2, 60 },
						decimals_number = 1,
						step_size_value = 0.5,
					},
					{
						setting_id = "override_hud_studio",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "hud_studio_fps",
						type = "numeric",
						default_value = 30,
						range = { 0.2, 60 },
						decimals_number = 1,
						step_size_value = 0.5,
					},
					{
						setting_id = "show_tick_echo",
						type = "checkbox",
						default_value = false,
					},
				},
			},
		},
	},
}
