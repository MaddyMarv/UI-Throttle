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
				tab = mod:localize("tab_general"),
				sub_widgets = {
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
				},
			},
			{
				setting_id = "group_rates",
				type = "group",
				tab = mod:localize("tab_rates"),
				sub_widgets = {
					{
						setting_id = "player_buffs_fps",
						type = "numeric",
						default_value = 10,
						range = { 0, 30 },
						decimals_number = 0,
						step_size_value = 1,
					},
					{
						setting_id = "team_panels_fps",
						type = "numeric",
						default_value = 30,
						range = { 0, 60 },
						decimals_number = 0,
						step_size_value = 1,
					},
					{
						setting_id = "stagger_team_panels",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "personal_player_panel_fps",
						type = "numeric",
						default_value = 30,
						range = { 0, 60 },
						decimals_number = 0,
						step_size_value = 1,
					},
					{
						setting_id = "world_markers_fps",
						type = "numeric",
						default_value = 60,
						range = { 0, 120 },
						decimals_number = 0,
						step_size_value = 1,
					},
					{
						setting_id = "combat_feed_fps",
						type = "numeric",
						default_value = 30,
						range = { 0, 60 },
						decimals_number = 0,
						step_size_value = 1,
					},
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
		},
	},
}
