local mod = get_mod("UIThrottle")

return {
	mod_name = {
		en = "UI Throttle",
	},
	mod_description = {
		en = "Reduces CPU overhead by throttling UI update rates with other features to reduce CPU load.",
	},
	tab_rates = {
		en = "Frame Rates",
	},
	group_rates = {
		en = "Target Frame Rates",
	},
	general_hud_fps = {
		en = "General HUD Rate (FPS)",
	},
	general_hud_fps_description = {
		en = "Target update rate for crosshair, tactical overlay, and general HUD elements.",
	},
	player_buffs_fps = {
		en = "Player Buffs Rate (FPS)",
	},
	player_buffs_fps_description = {
		en = "Target update rate for player buff icons.",
	},
	team_panels_fps = {
		en = "Teammate Panels Rate (FPS)",
	},
	team_panels_fps_description = {
		en = "Target update rate for teammate panels.",
	},
	stagger_team_panels = {
		en = "Stagger Teammate Updates",
	},
	stagger_team_panels_description = {
		en = "Updates only one teammate panel per tick.",
	},
	personal_player_panel_fps = {
		en = "Personal Panel Rate (FPS)",
	},
	personal_player_panel_fps_description = {
		en = "Target update rate for your own player panel.",
	},
	world_markers_fps = {
		en = "World Markers & Nameplates Rate (FPS)",
	},
	world_markers_fps_description = {
		en = "Target update rate for world markers and player nameplates.",
	},
	tab_general = {
		en = "General",
	},
	group_general = {
		en = "General & Controls",
	},
	bypass_in_menus = {
		en = "Bypass in Menus & Cursor",
	},
	bypass_in_menus_description = {
		en = "Temporarily disables UI throttling while menus, views, inventory, or the mouse cursor are active.",
	},
	toggle_throttle_key = {
		en = "Toggle Throttling Hotkey",
	},
	toggle_throttle_key_description = {
		en = "Keybind to quickly toggle all UI throttling on or off.",
	},
	show_tick_echo = {
		en = "Show Debug Tick Indicator",
	},
	show_tick_echo_description = {
		en = "Prints HUD tick updates and elapsed frame timings to chat for performance testing.",
	},
	msg_throttle_disabled = {
		en = "{#color(255,100,100)}[UI Throttle] Throttling disabled{#reset()}",
	},
	msg_throttle_enabled = {
		en = "{#color(100,255,100)}[UI Throttle] Throttling enabled{#reset()}",
	},
}
