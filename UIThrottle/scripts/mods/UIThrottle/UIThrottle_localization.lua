local mod = get_mod("UIThrottle")

return {
	mod_name = {
		en = "UI Throttle",
	},
	mod_description = {
		en = "Reduces CPU overhead by throttling background HUD elements while keeping inputs and crosshairs at full frame rate.",
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
		en = "Disables throttling while in menus, chat, or when the cursor is active.",
	},
	toggle_throttle_key = {
		en = "Toggle UI Throttle Key",
	},
	toggle_throttle_key_description = {
		en = "Keybind to toggle UI throttling on or off.",
	},
	msg_throttle_enabled = {
		en = "UI Throttle: Enabled",
	},
	msg_throttle_disabled = {
		en = "UI Throttle: Disabled (Bypassed)",
	},
	tab_rates = {
		en = "Frame Rates",
	},
	group_rates = {
		en = "Target Frame Rates",
	},
	general_hud_fps = {
		en = "General HUD",
	},
	general_hud_fps_description = {
		en = "Target update rate for general and modded HUD elements (0 = off). Pings, crosshairs, and weapon inputs always stay at full monitor frame rate.",
	},
	player_buffs_fps = {
		en = "Player Buffs Rate (FPS)",
	},
	player_buffs_fps_description = {
		en = "Update rate for player buff icons and durations (0 = off).",
	},
	team_panels_fps = {
		en = "Teammate Panels Rate (FPS)",
	},
	team_panels_fps_description = {
		en = "Target update rate for teammate panels (0 = off).",
	},
	stagger_team_panels = {
		en = "Stagger Teammate Updates",
	},
	stagger_team_panels_description = {
		en = "Offsets teammate updates across frames to spread CPU load.",
	},
	personal_player_panel_fps = {
		en = "Personal Panel Rate (FPS)",
	},
	personal_player_panel_fps_description = {
		en = "Target update rate for your own player panel (0 = off).",
	},
	world_markers_fps = {
		en = "World Markers & Nameplates Rate (FPS)",
	},
	world_markers_fps_description = {
		en = "Target update rate for world markers and player nameplates (0 = off).",
	},
	combat_feed_fps = {
		en = "Combat Feed Rate (FPS)",
	},
	combat_feed_fps_description = {
		en = "Target update rate for killfeed and pickup notification popups (0 = off).",
	},
}
