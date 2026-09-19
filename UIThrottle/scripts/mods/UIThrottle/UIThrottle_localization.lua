local mod = get_mod("UIThrottle")

return {
	mod_name = {
		en = "UI Throttle",
	},
	mod_description = {
		en = "Throttles UI update rates to test CPU overhead reduction.",
	},
	group_general = {
		en = "General Settings",
	},
	enable_hud_throttle = {
		en = "Enable General HUD Throttle",
	},
	general_hud_fps = {
		en = "General HUD Target FPS",
	},
	override_world_markers = {
		en = "Override: World Markers",
	},
	world_markers_fps = {
		en = "World Markers Target FPS",
	},
	show_tick_echo = {
		en = "Show On-Screen Tick Indicator",
	},
	bypass_in_menus = {
		en = "Bypass in Menus & When Cursor Active",
	},
	bypass_in_menus_description = {
		en = "Automatically suspends UI throttling while menus, views, editors (like HUD Studio), or the mouse cursor are active so grabbing, dragging, and navigation remain smooth.",
	},
	toggle_throttle_key = {
		en = "Toggle Throttling Keybind",
	},
	toggle_throttle_key_description = {
		en = "Keybind to quickly enable or disable all UI throttling.",
	},
	msg_throttle_disabled = {
		en = "{#color(255,100,100)}[UI Throttle] Throttling disabled{#reset()}",
	},
	msg_throttle_enabled = {
		en = "{#color(100,255,100)}[UI Throttle] Throttling enabled{#reset()}",
	},
	group_team = {
		en = "Team & Personal Panels",
	},
	override_personal_player_panel = {
		en = "Override: Personal Player Panel",
	},
	personal_player_panel_fps = {
		en = "Personal Player Panel Target FPS",
	},
	override_team_panels = {
		en = "Override: Teammate Panels",
	},
	team_panels_fps = {
		en = "Teammate Panels Target FPS",
	},
	group_hud_studio = {
		en = "HUD Studio",
	},
	override_hud_studio = {
		en = "Override: HUD Studio",
	},
	hud_studio_fps = {
		en = "HUD Studio Target FPS",
	},
}
