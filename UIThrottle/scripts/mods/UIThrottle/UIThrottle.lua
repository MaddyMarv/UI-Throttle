local mod = get_mod("UIThrottle")

-- Elements here run at native frame rate and are never throttled:
local protected_elements = {
	HudElementSmartTagging = true,
	HudElementCrosshair = true,
	HudElementDamageIndicator = true,
	HudElementPlayerWeaponHandler = true,
	HudElementPlayerAbilityHandler = true,
	HudElementWieldInfo = true,
	HudElementEmoteWheel = true,
	HudElementInteraction = true,
}

local TOLERANCE = 0.9

local settings = {
	bypass_in_menus = true,
	general_hud_fps = 30,
	player_buffs_fps = 10,
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
	if type(k) ~= "string" then return false end
	if k == "_ui_throttle_timer" or k == "_ui_throttle_last_t" then return false end

	local lk = k:lower()

	-- Universal throttle/update footprints used across Darktide mods
	return lk:find("interval") ~= nil
		or lk:find("throttle") ~= nil
		or lk:find("poll") ~= nil
		or lk:find("update_time") ~= nil
		or lk:find("update_timer") ~= nil
		or lk:find("last_.*_t") ~= nil
		or lk:find("last_.*_time") ~= nil
		or lk:find("next_.*_t") ~= nil
		or lk:find("_ammo_t") ~= nil
		or lk:find("displayed_second") ~= nil
end

local function has_self_throttling_footprint(element, class_name)
	if not element and not class_name then return false end

	if type(element) == "table" then
		if element.__ui_throttle_ignore or element._ui_throttle_exempt or element._is_throttled or element.throttled or element.is_throttled then
			return true
		end

		for k in pairs(element) do
			if is_throttle_footprint_key(k) then
				element.__ui_throttle_ignore = true
				return true
			end
		end
	end

	if class_name then
		local class_table = rawget(_G, class_name) or (rawget(_G, "CLASS") and CLASS[class_name])
		if type(class_table) == "table" then
			if class_table.__ui_throttle_ignore or class_table._ui_throttle_exempt or class_table._is_throttled or class_table.throttled or class_table.is_throttled then
				return true
			end

			for k in pairs(class_table) do
				if is_throttle_footprint_key(k) then
					return true
				end
			end
		end
	end

	return false
end

local function make_element_throttle(fps_setting_id)
	return function(func, self, dt, t, ui_renderer, render_settings, input_service)
		if has_self_throttling_footprint(self) then
			return func(self, dt, t, ui_renderer, render_settings, input_service)
		end

		local timer = self._ui_throttle_timer
		if not timer then
			local res = func(self, dt, t, ui_renderer, render_settings, input_service)
			if has_self_throttling_footprint(self) then
				return res
			end
			timer = pacing_new()
			self._ui_throttle_timer = timer
			return res
		end

		if not mod:is_enabled() or should_bypass_throttling(t) then
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
			return func(self, elapsed, t, ui_renderer, render_settings, input_service)
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

	if not mod:is_enabled() or should_bypass_throttling(t) then
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
		return func(self, elapsed, t, ui_renderer, render_settings, input_service)
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

mod:hook("HudElementNameplates", "update", function(func, self, dt, t)
	local timer = self._ui_throttle_timer
	if not timer then
		timer = pacing_new()
		self._ui_throttle_timer = timer
		return func(self, dt, t)
	end

	if not mod:is_enabled() or should_bypass_throttling(t) then
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
		if has_self_throttling_footprint(self) then
			return func(self, dt, t, player, ui_renderer)
		end

		local timer = self._ui_throttle_timer
		if not timer then
			local res = func(self, dt, t, player, ui_renderer)
			if has_self_throttling_footprint(self) then
				return res
			end
			local fps = settings[fps_setting_id] or 30
			local phase = (fps > 0 and stagger and settings.stagger_team_panels) and (math.random() / fps) or 0
			timer = pacing_new(phase)
			self._ui_throttle_timer = timer
			return res
		end

		if not mod:is_enabled() or should_bypass_throttling(t) then
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
	local buffs_fps = settings.player_buffs_fps or 10
	if not mod:is_enabled() or should_bypass_throttling(t) or buffs_fps <= 0 then
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

mod:hook("HudElementPlayerBuffs", "_update_buffs", handle_update_buffs)

local buff_bar_elements = {
	{ class_name = "HudElementPlayerBuffs" },
	{ class_name = "HudElementBuffBar" },
	{ class_name = "HudElementBBMBuffBar", mod_name = "better_buff_management" },
	{ class_name = "HudElementSbfBuffBar", mod_name = "SimpleBuffFilter" },
}

local hooked_elements = {
	HudElementWorldMarkers = true,
	HudElementNameplates = true,
	HudElementCombatFeed = true,
	HudElementPlayerBuffs = true,
	HudElementBuffBar = true,
	HudElementBBMBuffBar = true,
	HudElementSbfBuffBar = true,
	HudElementTeamPlayerPanel = true,
	HudElementPersonalPlayerPanel = true,
	HudElementTeamPanelHandler = true,
}

local function hook_buff_bars()
	for i = 1, #buff_bar_elements do
		local entry = buff_bar_elements[i]
		local class_name = entry.class_name or entry
		local mod_name = entry.mod_name

		if not hooked_elements[class_name] then
			local should_hook = false
			if rawget(_G, class_name) or (rawget(_G, "CLASS") and CLASS[class_name]) then
				should_hook = true
			elseif mod_name and rawget(_G, "get_mod") and get_mod(mod_name) then
				should_hook = true
			end

			if should_hook then
				hooked_elements[class_name] = true
				mod:hook(class_name, "_update_buffs", handle_update_buffs)
			end
		end
	end
end

local function is_element_throttled_or_exempt(element, class_name)
	return has_self_throttling_footprint(element, class_name)
end

local function apply_background_hud_throttling()
	local hud = Managers.ui and (Managers.ui._hud or Managers.ui._spectator_hud)
	if not hud or not hud._elements_array then return end

	for i = 1, #hud._elements_array do
		local element = hud._elements_array[i]
		local class_name = element.__class_name
		if class_name and not protected_elements[class_name] and not hooked_elements[class_name] and not is_element_throttled_or_exempt(element, class_name) then
			hooked_elements[class_name] = true
			mod:hook(class_name, "update", make_element_throttle("general_hud_fps"))
		end
	end
end

hook_buff_bars()
apply_background_hud_throttling()

mod.on_all_mods_loaded = function()
	refresh_settings()
	hook_buff_bars()
	apply_background_hud_throttling()
end

mod:hook_safe("UIHud", "_add_element", function(self, definition)
	local class_name = definition and definition.class_name
	if class_name and not protected_elements[class_name] and not hooked_elements[class_name] and not is_element_throttled_or_exempt(nil, class_name) then
		hooked_elements[class_name] = true
		mod:hook(class_name, "update", make_element_throttle("general_hud_fps"))
	end
end)

mod:hook("UIHud", "init", function(func, self, ...)
	local r1, r2, r3 = func(self, ...)
	hook_buff_bars()
	apply_background_hud_throttling()
	return r1, r2, r3
end)
