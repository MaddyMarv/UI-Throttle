local mod = get_mod("UIThrottle")

return {
	mod_name = {
		en = "UI Throttle",
	},
	mod_description = {
		en = "Reduces CPU overhead by throttling individual HUD element update rates without affecting input handling.",
	},
	tab_rates = {
		en = "Frame Rates",
	},
	group_rates = {
		en = "Target Frame Rates",
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
	combat_feed_fps = {
		en = "Combat Feed Rate (FPS)",
	},
	combat_feed_fps_description = {
		en = "Target update rate for killfeed and pickup notification popups.",
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
	msg_throttle_disabled = {
		en = "{#color(255,100,100)}[UI Throttle] Throttling disabled{#reset()}",
	},
	msg_throttle_enabled = {
		en = "{#color(100,255,100)}[UI Throttle] Throttling enabled{#reset()}",
	},
}
