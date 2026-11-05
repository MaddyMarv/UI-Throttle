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
	group_general_hud = {
		en = "General HUD",
	},
	general_hud_fps = {
		en = "General HUD Rate (FPS)",
	},
	general_hud_fps_description = {
		en = "Target update rate for general and modded HUD elements (0 = off). Pings, crosshairs, and weapon inputs always stay at full monitor frame rate.",
	},
	group_player_team = {
		en = "Player & Team",
	},
	player_buffs_fps = {
		en = "Player Buffs Rate (FPS)",
	},
	player_buffs_fps_description = {
		en = "Update rate for player buff icons and durations (0 = off).",
	},
	personal_player_panel_fps = {
		en = "Personal Panel Rate (FPS)",
	},
	personal_player_panel_fps_description = {
		en = "Target update rate for your own player panel (0 = off).",
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
	group_world_feed = {
		en = "World & Feed",
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
	cmd_status_description = {
		en = "Shows how UI Throttle handles each HUD element. Add part of an element name to list only matches, e.g. /uithrottle_status peril",
	},
	status_no_hud = {
		en = "UI Throttle: no HUD is active right now.",
	},
	status_no_match = {
		en = "UI Throttle: no HUD element name contains \"%s\".",
	},
	status_header = {
		en = "UI Throttle: General HUD rate %s.",
	},
	status_paused = {
		en = "UI Throttle: throttling is paused by the toggle hotkey.",
	},
	status_summary = {
		en = "%s on General HUD Rate, %s with a rate override, %s exempt, %s protected, %s untouched.",
	},
	status_log_hint = {
		en = "Full list written to the console log. Add part of a name to list matches here, e.g. /uithrottle_status peril",
	},
	status_rate = {
		en = "%s Hz",
	},
	status_rate_off = {
		en = "off (full rate)",
	},
	status_general = {
		en = "general rate, %s",
	},
	status_general_pending = {
		en = "general rate, %s (not updated yet)",
	},
	status_exempt_flag = {
		en = "exempt (mod flag %s)",
	},
	status_exempt_detected = {
		en = "exempt (own timer detected: %s)",
	},
	status_protected = {
		en = "protected (never throttled)",
	},
	status_dedicated = {
		en = "rate override: %s = %s",
	},
	status_dedicated_panels = {
		en = "rate override: %s = %s, %s = %s",
	},
	status_buffs = {
		en = "rate override: %s = %s (buff polling only)",
	},
	status_untouched = {
		en = "untouched (no update of its own)",
	},
	status_overridden = {
		en = "untouched (another mod replaced its update)",
	},
	status_not_wrapped = {
		en = "not handled yet",
	},
}
