local mod = get_mod("UIThrottle")

local TOLERANCE = 0.9

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

local ui_filter_list = {}

local buff_bar_elements = {
	{ class_name = "HudElementPlayerBuffs" },
	{ class_name = "HudElementBuffBar" },
	{ class_name = "HudElementBBMBuffBar", mod_name = "better_buff_management" },
	{ class_name = "HudElementSbfBuffBar", mod_name = "SimpleBuffFilter" },
}

mod._throttle_disabled = false

local function should_bypass_throttling(hud)
	if mod._throttle_disabled then
		return true
	end

	local hud_studio = rawget(_G, "get_mod") and get_mod("hud_studio")
	if hud_studio and hud_studio.hud_studio_editor_active then
		return true
	end

	if not mod:get("bypass_in_menus") then
		return false
	end

	local input_manager = rawget(_G, "Managers") and Managers.input
	if input_manager and input_manager.cursor_active and input_manager:cursor_active() then
		return true
	end

	local ui_manager = rawget(_G, "Managers") and Managers.ui
	if ui_manager then
		if ui_manager.has_active_view and ui_manager:has_active_view() then
			return true
		end
		if ui_manager.using_input and ui_manager:using_input() then
			return true
		end
		if ui_manager.chat_using_input and ui_manager:chat_using_input() then
			return true
		end
	end

	local active_hud = hud or (ui_manager and ui_manager.get_hud and ui_manager:get_hud())
	if active_hud and active_hud.using_input and active_hud:using_input() then
		return true
	end

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

local function make_element_throttle(fps_setting_id_or_number)
	return function(func, self, dt, t, ui_renderer, render_settings, input_service)
		local timer = self._ui_throttle_timer
		if not timer then
			timer = pacing_new()
			self._ui_throttle_timer = timer
		end

		if not mod:is_enabled() or should_bypass_throttling() then
			pacing_reset(timer)
			return func(self, dt, t, ui_renderer, render_settings, input_service)
		end

		local target_fps = type(fps_setting_id_or_number) == "number" and fps_setting_id_or_number or (mod:get(fps_setting_id_or_number) or 60)
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
			else
				local base_class = rawget(_G, "CLASS") and CLASS.HudElementBase
				if base_class and base_class.update then
					return base_class.update(self, dt, t, ui_renderer, render_settings, input_service)
				end
			end
		end
	end
end


mod:hook("HudElementWorldMarkers", "update", make_element_throttle("world_markers_fps"))

mod:hook("HudElementNameplates", "update", function(func, self, dt, t)
	local timer = self._ui_throttle_timer
	if not timer then
		timer = pacing_new()
		self._ui_throttle_timer = timer
	end

	if not mod:is_enabled() or should_bypass_throttling() then
		pacing_reset(timer)
		return func(self, dt, t)
	end

	local target_fps = mod:get("world_markers_fps") or 60
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
		if not timer then
			local phase = stagger and mod:get("stagger_team_panels") and math.random() / mod:get(fps_setting_id)
			timer = pacing_new(phase)
			self._ui_throttle_timer = timer
			return func(self, dt, t, player, ui_renderer)
		end

		if not mod:is_enabled() or should_bypass_throttling() then
			pacing_reset(timer)
			return func(self, dt, t, player, ui_renderer)
		end

		local due, elapsed = pacing_due(timer, dt, mod:get(fps_setting_id))
		if due then
			return func(self, elapsed, t, player, ui_renderer)
		end
	end
end

mod:hook("HudElementTeamPlayerPanel", "_update_player_features", make_panel_throttle("team_panels_fps", true))
mod:hook("HudElementPersonalPlayerPanel", "_update_player_features", make_panel_throttle("personal_player_panel_fps", false))

local function handle_update_buffs(func, self, t, ui_renderer)
	local buffs_fps = mod:get("player_buffs_fps")
	if not mod:is_enabled() or should_bypass_throttling() then
		return func(self, t, ui_renderer)
	end

	local buffs_data = self._active_buffs_data
	for i = 1, #buffs_data do
		if buffs_data[i].remove then
			self._ui_throttle_last_t = t
			return func(self, t, ui_renderer)
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

local hooked_elements = {
	HudElementWorldMarkers = true,
	HudElementNameplates = true,
	HudElementCombatFeed = true,
	HudElementPlayerBuffs = true,
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

local function apply_ui_filter_list()
	for i = 1, #ui_filter_list do
		local entry = ui_filter_list[i]
		local class_name, target_fps
		if type(entry) == "string" then
			class_name = entry
			target_fps = 30
		elseif type(entry) == "table" then
			class_name = entry.class_name or entry[1]
			target_fps = entry.fps or entry.target_fps or entry[2] or 30
		end

		if class_name and not hooked_elements[class_name] then
			hooked_elements[class_name] = true
			mod:hook(class_name, "update", make_element_throttle(target_fps))
		end
	end
end

hook_buff_bars()
apply_ui_filter_list()

mod.on_all_mods_loaded = function()
	hook_buff_bars()
	apply_ui_filter_list()
end
