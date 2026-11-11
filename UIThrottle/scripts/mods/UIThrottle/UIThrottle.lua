local mod = get_mod("UIThrottle")

local HudElementBase = require("scripts/ui/hud/elements/hud_element_base")
local base_update = HudElementBase.update

local protected_elements = {
	HudElementSmartTagging = true,
	HudElementCrosshair = true,
	HudElementDamageIndicator = true,
	HudElementPlayerWeaponHandler = true,
	HudElementPlayerAbilityHandler = true,
	HudElementWieldInfo = true,
	HudElementEmoteWheel = true,
	HudElementInteraction = true,
	HudElementPrologueTutorialInfoBox = true,
	HudElementNameplates = true,
	HudCanvas = true,
}

local TOLERANCE = 0.9

local settings = {
	bypass_in_menus = true,
	general_hud_fps = 30,
	player_buffs_fps = 30,
	personal_player_panel_fps = 30,
	team_panels_fps = 30,
	stagger_team_panels = true,
	world_markers_fps = 30,
	world_markers_position_fps = 60,
	combat_feed_fps = 30,
}

local function refresh_settings()
	for id in pairs(settings) do
		local val = mod:get(id)
		if val ~= nil then
			settings[id] = val
		end
	end
end

refresh_settings()

mod.on_setting_changed = function(setting_id)
	if settings[setting_id] ~= nil then
		settings[setting_id] = mod:get(setting_id)
	end
end

local function pacing_new(phase)
	phase = phase or 0
	return { debt = phase, elapsed = 0, phase = phase }
end

local function pacing_reset(timer)
	timer.debt = timer.phase
	timer.elapsed = 0
end

local function pacing_due(timer, dt, fps)
	local elapsed = timer.elapsed + dt
	if fps <= 0 then
		timer.debt = 0
		timer.elapsed = 0
		return true, elapsed
	end
	local interval = 1 / fps
	local debt = timer.debt + dt
	if debt < interval * TOLERANCE then
		timer.debt = debt
		timer.elapsed = elapsed
		return false, 0
	end
	debt = debt - interval
	if debt > interval then
		debt = interval
	elseif debt < 0 then
		debt = 0
	end
	timer.debt = debt
	timer.elapsed = 0
	return true, elapsed
end

mod._throttle_disabled = false

local _last_bypass_t = -1
local _cached_bypass = false

local function should_bypass_throttling(t)
	if mod._throttle_disabled then
		return true
	end

	if not settings.bypass_in_menus then
		return false
	end

	if t and t == _last_bypass_t then
		return _cached_bypass
	end

	local hud_studio = rawget(_G, "get_mod") and get_mod("hud_studio")
	if hud_studio and hud_studio.hud_studio_editor_active then
		_last_bypass_t = t or -1
		_cached_bypass = true
		return true
	end

	local input_manager = rawget(_G, "Managers") and Managers.input
	if input_manager and input_manager.cursor_active and input_manager:cursor_active() then
		_last_bypass_t = t or -1
		_cached_bypass = true
		return true
	end

	local ui_manager = rawget(_G, "Managers") and Managers.ui
	if ui_manager then
		if ui_manager.has_active_view and ui_manager:has_active_view() then
			_last_bypass_t = t or -1
			_cached_bypass = true
			return true
		end
		if ui_manager.using_input and ui_manager:using_input() then
			_last_bypass_t = t or -1
			_cached_bypass = true
			return true
		end
		if ui_manager.chat_using_input and ui_manager:chat_using_input() then
			_last_bypass_t = t or -1
			_cached_bypass = true
			return true
		end
	end

	_last_bypass_t = t or -1
	_cached_bypass = false
	return false
end

mod.toggle_throttle = function()
	mod._throttle_disabled = not mod._throttle_disabled
	if mod._throttle_disabled then
		mod:echo(mod:localize("msg_throttle_disabled"))
	else
		mod:echo(mod:localize("msg_throttle_enabled"))
	end
end

local function is_throttle_field(k, v)
	local tv = type(v)
	if tv == "number" then
		local lk = k:lower()
		return lk:find("throttle", 1, true) ~= nil
			or lk:find("interval", 1, true) ~= nil
			or lk:find("^_?next_[%w_]*_t$") ~= nil
	elseif tv == "table" then
		return type(rawget(v, "elapsed")) == "number"
			and (type(rawget(v, "debt")) == "number" or type(rawget(v, "accumulator")) == "number" or type(rawget(v, "interval")) == "number")
	end
	return false
end

local exempt_flags = { "_ui_throttle_exempt", "__ui_throttle_ignore", "_is_throttled", "throttled", "is_throttled" }
local exempt_flag_lookup = {}
for i = 1, #exempt_flags do
	exempt_flag_lookup[exempt_flags[i]] = true
end

local function self_throttle_reason(element)
	if type(element) ~= "table" then return nil end

	for i = 1, #exempt_flags do
		local flag = exempt_flags[i]
		if element[flag] then
			return flag
		end
	end

	for k, v in pairs(element) do
		if type(k) == "string" and not k:find("^_ui_throttle_") and is_throttle_field(k, v) then
			return k
		end
	end

	return nil
end

local function run_due_update(func, self, dt, elapsed, t, ui_renderer, render_settings, input_service)
	self._ui_throttle_base_dt = dt
	func(self, elapsed, t, ui_renderer, render_settings, input_service)
	self._ui_throttle_base_dt = nil
end

local function make_element_throttle(fps_setting_id)
	return function(func, self, dt, t, ui_renderer, render_settings, input_service)
		local timer = self._ui_throttle_timer
		if timer == nil then
			local res = func(self, dt, t, ui_renderer, render_settings, input_service)
			local reason = self_throttle_reason(self)
			if reason then
				self._ui_throttle_timer = false
				self._ui_throttle_reason = reason
			else
				self._ui_throttle_timer = pacing_new()
			end
			return res
		end

		if timer == false then
			return func(self, dt, t, ui_renderer, render_settings, input_service)
		end

		if should_bypass_throttling(t) then
			pacing_reset(timer)
			return func(self, dt, t, ui_renderer, render_settings, input_service)
		end

		local target_fps = settings[fps_setting_id] or 60
		if target_fps <= 0 then
			pacing_reset(timer)
			return func(self, dt, t, ui_renderer, render_settings, input_service)
		end

		local due, elapsed = pacing_due(timer, dt, target_fps)
		if due then
			return run_due_update(func, self, dt, elapsed, t, ui_renderer, render_settings, input_service)
		else
			if self._ui_throttle_is_base then
				return HudElementBase.update(self, dt, t, ui_renderer, render_settings, input_service)
			end
		end
	end
end

local marker_logic_skip = false
local marker_logic_dt = nil

local function wrap_marker_template(name, template)
	local current = template.update_function
	if not current or current == template._ui_throttle_update then
		return
	end
	if string.find(name, "nameplate", 1, true) then
		template._ui_throttle_update = current
		return
	end
	local wrapper = function(parent, ui_renderer, widget, marker, marker_template, dt, t)
		if marker_logic_skip then
			return
		end
		return current(parent, ui_renderer, widget, marker, marker_template, marker_logic_dt or dt, t)
	end
	template.update_function = wrapper
	template._ui_throttle_update = wrapper
end

local function wrap_marker_templates(templates)
	for name, template in pairs(templates) do
		wrap_marker_template(name, template)
	end
end

mod:hook("HudElementWorldMarkers", "_template_by_type", function(func, self, marker_type, clone)
	local template = func(self, marker_type, clone)
	if template then
		wrap_marker_template(marker_type, template)
	end
	return template
end)

local companion_marker_types = { "nameplate_companion", "nameplate_companion_hub" }

local function refresh_companion_markers(self, ui_renderer, t)
	local markers_by_type = self._markers_by_type
	if not markers_by_type then return end
	for n = 1, #companion_marker_types do
		local markers = markers_by_type[companion_marker_types[n]]
		if markers then
			for i = 1, #markers do
				local marker = markers[i]
				local template = marker.template
				local update_function = template and template.update_function
				if update_function and marker.update then
					update_function(self, ui_renderer, marker.widget, marker, template, 0, t)
				end
			end
		end
	end
end

local function remove_dead_markers(self)
	local markers = self._markers
	if not markers then return end
	local alive_table = rawget(_G, "ALIVE")
	for i = #markers, 1, -1 do
		local marker = markers[i]
		local unit = marker.unit
		if marker.remove or (unit and alive_table and not alive_table[unit]) then
			self:_unregister_marker(marker)
		end
	end
end

mod:hook("HudElementWorldMarkers", "update", function(func, self, dt, t, ui_renderer, render_settings, input_service)
	marker_logic_skip = false
	marker_logic_dt = nil

	local position_timer = self._ui_throttle_timer
	if not position_timer then
		self._ui_throttle_timer = pacing_new()
		self._ui_throttle_logic_timer = pacing_new()
		return func(self, dt, t, ui_renderer, render_settings, input_service)
	end

	local logic_timer = self._ui_throttle_logic_timer
	local logic_fps = settings.world_markers_fps or 30
	local position_fps = settings.world_markers_position_fps or 60
	if (logic_fps <= 0 and position_fps <= 0) or should_bypass_throttling(t) then
		pacing_reset(position_timer)
		pacing_reset(logic_timer)
		self._ui_throttle_logic_pending = nil
		return func(self, dt, t, ui_renderer, render_settings, input_service)
	end

	local logic_due, logic_elapsed = pacing_due(logic_timer, dt, logic_fps)
	if logic_due then
		self._ui_throttle_logic_pending = (self._ui_throttle_logic_pending or 0) + logic_elapsed
	end

	local position_due, position_elapsed = pacing_due(position_timer, dt, position_fps)
	if not position_due then
		remove_dead_markers(self)
		refresh_companion_markers(self, ui_renderer, t)
		return HudElementBase.update(self, dt, t, ui_renderer, render_settings, input_service)
	end

	local pending = self._ui_throttle_logic_pending
	if pending then
		wrap_marker_templates(self._marker_templates)
		marker_logic_dt = pending
		self._ui_throttle_logic_pending = nil
	else
		marker_logic_skip = true
	end

	run_due_update(func, self, dt, position_elapsed, t, ui_renderer, render_settings, input_service)

	marker_logic_skip = false
	marker_logic_dt = nil
end)

mod:hook("HudElementCombatFeed", "update", make_element_throttle("combat_feed_fps"))

local function make_panel_throttle(fps_setting_id, stagger)
	return function(func, self, dt, t, player, ui_renderer)
		local timer = self._ui_throttle_timer
		if timer == nil then
			local res = func(self, dt, t, player, ui_renderer)
			if self_throttle_reason(self) then
				self._ui_throttle_timer = false
			else
				local fps = settings[fps_setting_id] or 30
				local phase = (fps > 0 and stagger and settings.stagger_team_panels) and (math.random() / fps) or 0
				self._ui_throttle_timer = pacing_new(phase)
			end
			return res
		end

		if timer == false then
			return func(self, dt, t, player, ui_renderer)
		end

		if should_bypass_throttling(t) then
			pacing_reset(timer)
			return func(self, dt, t, player, ui_renderer)
		end

		local target_fps = settings[fps_setting_id] or 30
		if target_fps <= 0 then
			pacing_reset(timer)
			return func(self, dt, t, player, ui_renderer)
		end

		local due, elapsed = pacing_due(timer, dt, target_fps)
		if due then
			return func(self, elapsed, t, player, ui_renderer)
		end
	end
end

local team_panel_throttle = make_panel_throttle("team_panels_fps", true)
local personal_panel_throttle = make_panel_throttle("personal_player_panel_fps", false)

local panel_throttles = {
	HudElementTeamPlayerPanel = team_panel_throttle,
	HudElementTeamPlayerPanelHub = team_panel_throttle,
	HudElementPersonalPlayerPanel = personal_panel_throttle,
	HudElementPersonalPlayerPanelHub = personal_panel_throttle,
}

for class_name, throttle in pairs(panel_throttles) do
	mod:hook(class_name, "_update_player_features", function(func, self, dt, t, player, ui_renderer)
		if rawget(self, "_ui_throttle_panel_wrapped") then
			return func(self, dt, t, player, ui_renderer)
		end
		return throttle(func, self, dt, t, player, ui_renderer)
	end)
end

local function wrap_panel(panel)
	local throttle = panel_throttles[panel.__class_name]
	local cls = getmetatable(panel)
	if not throttle or not cls or rawget(panel, "_update_player_features") then
		panel._ui_throttle_panel_wrapped = false
		return
	end
	panel._ui_throttle_panel_wrapped = true
	panel._update_player_features = function(self, dt, t, player, ui_renderer)
		if not mod:is_enabled() then
			return cls._update_player_features(self, dt, t, player, ui_renderer)
		end
		return throttle(cls._update_player_features, self, dt, t, player, ui_renderer)
	end
end

local function handle_panel_handler_update(func, self, dt, t, ui_renderer, render_settings, input_service)
	local panels = self._player_panels_array
	for i = 1, #panels do
		local panel = panels[i].panel
		if rawget(panel, "_ui_throttle_panel_wrapped") == nil then
			wrap_panel(panel)
		end
	end

	local timer = self._ui_throttle_timer
	if not timer then
		self._ui_throttle_timer = pacing_new()
		return func(self, dt, t, ui_renderer, render_settings, input_service)
	end

	local target_fps = settings.team_panels_fps or 30
	if target_fps <= 0 or should_bypass_throttling(t) then
		pacing_reset(timer)
		return func(self, dt, t, ui_renderer, render_settings, input_service)
	end

	if pacing_due(timer, dt, target_fps) then
		return func(self, dt, t, ui_renderer, render_settings, input_service)
	end

	local num_panels = #panels
	for i = 1, num_panels do
		if panels[i].player.__deleted then
			return func(self, dt, t, ui_renderer, render_settings, input_service)
		end
	end

	HudElementBase.update(self, dt, t, ui_renderer, render_settings, input_service)
	for i = 1, num_panels do
		panels[i].panel:update(dt, t, ui_renderer, render_settings, input_service)
	end
end

local function tactical_overlay_busy(self)
	if self._active or (self._alpha_multiplier or 0) > 0 then
		return true
	end
	local input_service = Managers.input:get_input_service("Ingame")
	return input_service ~= nil and input_service:get("tactical_overlay_hold") or false
end

local idle_throttled_elements = {
	HudElementTacticalOverlay = tactical_overlay_busy,
}

local function handle_update_buffs(func, self, t, ui_renderer)
	local buffs_fps = settings.player_buffs_fps or 30
	if should_bypass_throttling(t) or buffs_fps <= 0 then
		return func(self, t, ui_renderer)
	end

	local buffs_data = self._active_buffs_data
	if buffs_data then
		for i = 1, #buffs_data do
			if buffs_data[i].remove then
				self._ui_throttle_last_t = t
				return func(self, t, ui_renderer)
			end
		end
	end

	local last_t = self._ui_throttle_last_t
	if last_t and t - last_t < TOLERANCE / buffs_fps then
		return
	end

	self._ui_throttle_last_t = t
	return func(self, t, ui_renderer)
end

local dedicated_elements = {
	HudElementWorldMarkers = "world_markers_fps",
	HudElementCombatFeed = "combat_feed_fps",
	HudElementTeamPanelHandler = "team_panels_fps",
}

local general_throttle = make_element_throttle("general_hud_fps")

local function is_base_descendant(cls)
	while cls do
		if cls == HudElementBase then
			return true
		end
		cls = rawget(cls, "super")
	end
	return false
end

local function wrap_animations(element, cls)
	local update_animations = cls._update_animations
	if not update_animations or rawget(element, "_update_animations") then return end
	element._update_animations = function(self, dt, t)
		return update_animations(self, rawget(self, "_ui_throttle_base_dt") or dt, t)
	end
end

local function wrap_element(element)
	if type(element) ~= "table" or rawget(element, "_ui_throttle_wrapped") then return end
	element._ui_throttle_wrapped = true

	local class_name = element.__class_name
	local cls = getmetatable(element)
	if not cls then return end

	element._ui_throttle_is_base = is_base_descendant(cls)

	if protected_elements[class_name] then
		element._ui_throttle_mode = "protected"
		return
	end

	if dedicated_elements[class_name] then
		element._ui_throttle_mode = "dedicated"
		if class_name ~= "HudElementTeamPanelHandler" then
			wrap_animations(element, cls)
		elseif not rawget(element, "update") then
			element.update = function(self, dt, t, ui_renderer, render_settings, input_service)
				if not mod:is_enabled() then
					return cls.update(self, dt, t, ui_renderer, render_settings, input_service)
				end
				return handle_panel_handler_update(cls.update, self, dt, t, ui_renderer, render_settings, input_service)
			end
		end
		return
	end

	local reason = self_throttle_reason(element)
	if reason then
		element._ui_throttle_mode = "exempt"
		element._ui_throttle_reason = reason
		return
	end

	if cls._update_buffs then
		if rawget(element, "_update_buffs") then
			element._ui_throttle_mode = "overridden"
			return
		end
		element._ui_throttle_mode = "buffs"
		element._update_buffs = function(self, t, ui_renderer)
			if not mod:is_enabled() then
				return cls._update_buffs(self, t, ui_renderer)
			end
			return handle_update_buffs(cls._update_buffs, self, t, ui_renderer)
		end
		return
	end

	if not cls.update or cls.update == base_update then
		element._ui_throttle_mode = "untouched"
		return
	end

	if rawget(element, "update") then
		element._ui_throttle_mode = "overridden"
		return
	end

	local is_busy = idle_throttled_elements[class_name]
	if is_busy then
		element._ui_throttle_mode = "idle"
		wrap_animations(element, cls)
		element.update = function(self, dt, t, ui_renderer, render_settings, input_service)
			if not mod:is_enabled() then
				return cls.update(self, dt, t, ui_renderer, render_settings, input_service)
			end
			if is_busy(self) then
				local timer = self._ui_throttle_timer
				if timer then
					pacing_reset(timer)
				end
				return cls.update(self, dt, t, ui_renderer, render_settings, input_service)
			end
			return general_throttle(cls.update, self, dt, t, ui_renderer, render_settings, input_service)
		end
		return
	end

	element._ui_throttle_mode = "general"
	wrap_animations(element, cls)
	element.update = function(self, dt, t, ui_renderer, render_settings, input_service)
		if not mod:is_enabled() then
			return cls.update(self, dt, t, ui_renderer, render_settings, input_service)
		end
		return general_throttle(cls.update, self, dt, t, ui_renderer, render_settings, input_service)
	end
end

local function wrap_hud(hud)
	local elements = hud and hud._elements_array
	if not elements then return end
	for i = 1, #elements do
		wrap_element(elements[i])
	end
end

local function wrap_existing_huds()
	local ui_manager = Managers.ui
	if not ui_manager then return end
	wrap_hud(ui_manager._hud)
	wrap_hud(ui_manager._spectator_hud)
end

mod.on_all_mods_loaded = function()
	refresh_settings()
	wrap_existing_huds()
end

mod.on_enabled = function()
	refresh_settings()
	wrap_existing_huds()
end

mod:hook_safe("UIHud", "_add_element", function(_, definition, elements)
	local class_name = definition and definition.class_name
	if class_name and elements then
		wrap_element(elements[class_name])
	end
end)

local function rate_text(fps)
	if fps and fps > 0 then
		return mod:localize("status_rate", fps)
	end
	return mod:localize("status_rate_off")
end

local function exempt_text(reason)
	if exempt_flag_lookup[reason] then
		return mod:localize("status_exempt_flag", reason)
	end
	return mod:localize("status_exempt_detected", tostring(reason))
end

local function element_status(element)
	if rawget(element, "_ui_throttle_timer") == false then
		return "exempt", exempt_text(rawget(element, "_ui_throttle_reason"))
	end

	local mode = rawget(element, "_ui_throttle_mode")
	if mode == "general" then
		local key = rawget(element, "_ui_throttle_timer") and "status_general" or "status_general_pending"
		return "general", mod:localize(key, rate_text(settings.general_hud_fps))
	elseif mode == "idle" then
		return "general", mod:localize("status_idle", rate_text(settings.general_hud_fps))
	elseif mode == "exempt" then
		return "exempt", exempt_text(rawget(element, "_ui_throttle_reason"))
	elseif mode == "protected" then
		return "protected", mod:localize("status_protected")
	elseif mode == "dedicated" then
		local class_name = element.__class_name
		if class_name == "HudElementTeamPanelHandler" then
			return "dedicated", mod:localize("status_dedicated_panels",
				mod:localize("team_panels_fps"), rate_text(settings.team_panels_fps),
				mod:localize("personal_player_panel_fps"), rate_text(settings.personal_player_panel_fps))
		end
		if class_name == "HudElementWorldMarkers" then
			return "dedicated", mod:localize("status_dedicated_panels",
				mod:localize("world_markers_fps"), rate_text(settings.world_markers_fps),
				mod:localize("world_markers_position_fps"), rate_text(settings.world_markers_position_fps))
		end
		local setting_id = dedicated_elements[class_name]
		return "dedicated", mod:localize("status_dedicated", mod:localize(setting_id), rate_text(settings[setting_id]))
	elseif mode == "buffs" then
		return "dedicated", mod:localize("status_buffs", mod:localize("player_buffs_fps"), rate_text(settings.player_buffs_fps))
	elseif mode == "overridden" then
		return "untouched", mod:localize("status_overridden")
	elseif mode == "untouched" then
		return "untouched", mod:localize("status_untouched")
	end
	return "untouched", mod:localize("status_not_wrapped")
end

local function add_status_lines(hud, filter, lines, counts)
	local elements = hud and hud._elements_array
	if not elements then return end
	for i = 1, #elements do
		local element = elements[i]
		local name = tostring(element.__class_name)
		if not filter or name:lower():find(filter, 1, true) then
			local bucket, text = element_status(element)
			counts[bucket] = counts[bucket] + 1
			lines[#lines + 1] = name .. ": " .. text
		end
	end
end

mod:command("uithrottle_status", mod:localize("cmd_status_description"), function(filter)
	local ui_manager = Managers.ui
	local hud = ui_manager and ui_manager._hud
	local spectator_hud = ui_manager and ui_manager._spectator_hud
	if not hud and not spectator_hud then
		mod:echo(mod:localize("status_no_hud"))
		return
	end

	filter = filter and filter:lower()
	local lines = {}
	local counts = { general = 0, exempt = 0, protected = 0, dedicated = 0, untouched = 0 }
	add_status_lines(hud, filter, lines, counts)
	add_status_lines(spectator_hud, filter, lines, counts)

	if filter then
		if #lines == 0 then
			mod:echo(mod:localize("status_no_match", filter))
		end
		for i = 1, #lines do
			mod:echo(lines[i])
		end
		return
	end

	mod:echo(mod:localize("status_header", rate_text(settings.general_hud_fps)))
	if mod._throttle_disabled then
		mod:echo(mod:localize("status_paused"))
	end
	mod:echo(mod:localize("status_summary", counts.general, counts.dedicated, counts.exempt, counts.protected, counts.untouched))
	for i = 1, #lines do
		mod:info(lines[i])
	end
	mod:echo(mod:localize("status_log_hint"))
end)
