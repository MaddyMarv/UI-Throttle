local mod = get_mod("UIThrottle")

local protected_elements = {
	HudElementSmartTagging = true,
	HudElementCrosshair = true,
	HudElementDamageIndicator = true,
	HudElementPlayerWeaponHandler = true,
	HudElementPlayerAbilityHandler = true,
	HudElementWieldInfo = true,
	HudElementEmoteWheel = true,
	HudElementInteraction = true,
	HudElementTacticalOverlay = true,
	HudElementPrologueTutorialInfoBox = true,
}

local TOLERANCE = 0.9

local settings = {
	bypass_in_menus = true,
	general_hud_fps = 30,
	player_buffs_fps = 30,
	personal_player_panel_fps = 30,
	team_panels_fps = 30,
	stagger_team_panels = true,
	world_markers_fps = 60,
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

local function is_throttle_footprint_key(k)
	if type(k) ~= "string" or k:find("^_ui_throttle_") then return false end

	local lk = k:lower()

	return lk:find("interval", 1, true) ~= nil
		or lk:find("throttle", 1, true) ~= nil
		or lk:find("poll", 1, true) ~= nil
		or lk:find("update_time", 1, true) ~= nil
		or lk:find("update_timer", 1, true) ~= nil
		or lk:find("^_?last_[%w_]*_t$") ~= nil
		or lk:find("^_?last_[%w_]*_time$") ~= nil
		or lk:find("^_?next_[%w_]*_t$") ~= nil
		or lk:find("_ammo_t", 1, true) ~= nil
		or lk:find("displayed_second", 1, true) ~= nil
end

local function has_self_throttling_footprint(tbl)
	if type(tbl) ~= "table" then return false end

	if tbl.__ui_throttle_ignore or tbl._ui_throttle_exempt or tbl._is_throttled or tbl.throttled or tbl.is_throttled then
		return true
	end

	for k in pairs(tbl) do
		if is_throttle_footprint_key(k) then
			return true
		end
	end

	return false
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
			if has_self_throttling_footprint(self) then
				self._ui_throttle_timer = false
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
			local super_class = self.super
			if super_class and super_class.update then
				return super_class.update(self, dt, t, ui_renderer, render_settings, input_service)
			end
		end
	end
end

mod:hook("HudElementWorldMarkers", "update", function(func, self, dt, t, ui_renderer, render_settings, input_service)
	local timer = self._ui_throttle_timer
	if not timer then
		timer = pacing_new()
		self._ui_throttle_timer = timer
		return func(self, dt, t, ui_renderer, render_settings, input_service)
	end

	if should_bypass_throttling(t) then
		pacing_reset(timer)
		return func(self, dt, t, ui_renderer, render_settings, input_service)
	end

	local target_fps = settings.world_markers_fps or 60
	if target_fps <= 0 then
		pacing_reset(timer)
		return func(self, dt, t, ui_renderer, render_settings, input_service)
	end

	local due, elapsed = pacing_due(timer, dt, target_fps)
	if due then
		return run_due_update(func, self, dt, elapsed, t, ui_renderer, render_settings, input_service)
	else
		local markers = self._markers
		if markers then
			local alive_table = rawget(_G, "ALIVE")
			for i = #markers, 1, -1 do
				local marker = markers[i]
				local unit = marker.unit
				if marker.remove or (unit and alive_table and not alive_table[unit]) then
					self:_unregister_marker(marker)
				end
			end
		end

		local super_class = self.super
		if super_class and super_class.update then
			return super_class.update(self, dt, t, ui_renderer, render_settings, input_service)
		end
	end
end)

local base_update = require("scripts/ui/hud/elements/hud_element_base").update

mod:hook("HudElementBase", "update", function(func, self, dt, ...)
	local base_dt = rawget(self, "_ui_throttle_base_dt")
	if base_dt then
		self._ui_throttle_base_dt = nil
		return func(self, base_dt, ...)
	end
	return func(self, dt, ...)
end)

mod:hook("HudElementNameplates", "update", function(func, self, dt, t)
	local timer = self._ui_throttle_timer
	if not timer then
		timer = pacing_new()
		self._ui_throttle_timer = timer
		return func(self, dt, t)
	end

	if should_bypass_throttling(t) then
		pacing_reset(timer)
		return func(self, dt, t)
	end

	local target_fps = settings.world_markers_fps or 60
	if target_fps <= 0 then
		pacing_reset(timer)
		return func(self, dt, t)
	end

	local due, elapsed = pacing_due(timer, dt, target_fps)
	if due then
		return func(self, elapsed, t)
	end
end)

mod:hook("HudElementCombatFeed", "update", make_element_throttle("combat_feed_fps"))

local function make_panel_throttle(fps_setting_id, stagger)
	return function(func, self, dt, t, player, ui_renderer)
		local timer = self._ui_throttle_timer
		if timer == nil then
			local res = func(self, dt, t, player, ui_renderer)
			if has_self_throttling_footprint(self) then
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

mod:hook("HudElementTeamPlayerPanel", "_update_player_features", make_panel_throttle("team_panels_fps", true))
mod:hook("HudElementPersonalPlayerPanel", "_update_player_features", make_panel_throttle("personal_player_panel_fps", false))

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
	HudElementWorldMarkers = true,
	HudElementNameplates = true,
	HudElementCombatFeed = true,
	HudElementTeamPanelHandler = true,
}

local general_throttle = make_element_throttle("general_hud_fps")

local function wrap_element(element)
	if type(element) ~= "table" or rawget(element, "_ui_throttle_wrapped") then return end
	element._ui_throttle_wrapped = true

	local class_name = element.__class_name
	local cls = getmetatable(element)
	if not cls or protected_elements[class_name] or dedicated_elements[class_name] then return end

	if cls._update_buffs then
		if rawget(element, "_update_buffs") then return end
		element._update_buffs = function(self, t, ui_renderer)
			if not mod:is_enabled() then
				return cls._update_buffs(self, t, ui_renderer)
			end
			return handle_update_buffs(cls._update_buffs, self, t, ui_renderer)
		end
		return
	end

	if not cls.update or cls.update == base_update or rawget(element, "update") or has_self_throttling_footprint(cls) then return end

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
