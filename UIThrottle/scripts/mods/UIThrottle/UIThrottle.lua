local mod = get_mod("UIThrottle")

local TOLERANCE = 0.9

local function pacing_new()
	return { debt = 0, elapsed = 0 }
end

local function pacing_reset(timer)
	timer.debt = 0
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

local hud_timer = pacing_new()
local world_markers_timer = pacing_new()
local team_panels_timer = pacing_new()
local personal_panel_timer = pacing_new()

local entire_hud_ticks = 0

local team_robin_index = 0

mod._throttle_disabled = false

local function reset_timers()
	pacing_reset(hud_timer)
	pacing_reset(world_markers_timer)
	pacing_reset(team_panels_timer)
	pacing_reset(personal_panel_timer)
	team_robin_index = 0
end

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

	if hud and hud.using_input and hud:using_input() then
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

mod.on_enabled = function()
	reset_timers()
end

mod.on_disabled = function()
	reset_timers()
end

mod.on_setting_changed = function(setting_id)
	reset_timers()
end

mod:hook("UIHud", "update", function(func, self, dt, t, input_service)
	if not mod:is_enabled() or should_bypass_throttling(self) then
		pacing_reset(hud_timer)
		pacing_reset(world_markers_timer)
		return func(self, dt, t, input_service)
	end

	local target_fps = mod:get("general_hud_fps") or 30
	if target_fps <= 0 then
		pacing_reset(hud_timer)
		pacing_reset(world_markers_timer)
		return func(self, dt, t, input_service)
	end

	local due, elapsed = pacing_due(hud_timer, dt, target_fps)

	world_markers_timer.elapsed = world_markers_timer.elapsed + dt
	world_markers_timer.debt = world_markers_timer.debt + dt

	if due then
		entire_hud_ticks = entire_hud_ticks + 1
		if mod:get("show_tick_echo") then
			mod:echo(string.format("{#color(100,255,100)}[HUD TICK #%d] (%.1fms){#reset()}", entire_hud_ticks, elapsed * 1000))
		end

		func(self, elapsed, t, input_service)
		pacing_reset(world_markers_timer)
	else
		local wm_fps = mod:get("world_markers_fps") or 60
		if wm_fps > target_fps then
			local wm_due, wm_elapsed = pacing_due(world_markers_timer, 0, wm_fps)

			if wm_due then
				local ui_renderer = self._ui_renderer
				local render_settings = self._render_settings
				local visible_elements = self._currently_visible_elements
				local elements = self._elements

				if elements and visible_elements then
					local default_scale = (render_settings and render_settings.scale) or (RESOLUTION_LOOKUP and RESOLUTION_LOOKUP.scale) or 1
					if ui_renderer then
						ui_renderer.scale = default_scale
						ui_renderer.inverse_scale = 1 / default_scale
					end

					local wm = elements.HudElementWorldMarkers
					if wm and visible_elements.HudElementWorldMarkers and wm.update then
						local applied_scale = false
						if self._elements_hud_scale_lookup and self._elements_hud_scale_lookup.HudElementWorldMarkers then
							applied_scale = true
							self:_apply_hud_scale()
							if ui_renderer and render_settings then
								ui_renderer.scale = render_settings.scale
								ui_renderer.inverse_scale = render_settings.inverse_scale
							end
						end

						wm:update(wm_elapsed, t, ui_renderer, render_settings, input_service)

						if applied_scale then
							self:_abort_hud_scale()
							if ui_renderer and render_settings then
								ui_renderer.scale = render_settings.scale
								ui_renderer.inverse_scale = render_settings.inverse_scale
							end
						end
					end

					local np = elements.HudElementNameplates
					if np and visible_elements.HudElementNameplates and np.update then
						local applied_scale = false
						if self._elements_hud_scale_lookup and self._elements_hud_scale_lookup.HudElementNameplates then
							applied_scale = true
							self:_apply_hud_scale()
							if ui_renderer and render_settings then
								ui_renderer.scale = render_settings.scale
								ui_renderer.inverse_scale = render_settings.inverse_scale
							end
						end

						np:update(wm_elapsed, t, ui_renderer, render_settings, input_service)

						if applied_scale then
							self:_abort_hud_scale()
							if ui_renderer and render_settings then
								ui_renderer.scale = render_settings.scale
								ui_renderer.inverse_scale = render_settings.inverse_scale
							end
						end
					end
				end
			end
		end
	end
end)

mod:hook("HudElementTeamPanelHandler", "update", function(func, self, dt, t, ui_renderer, render_settings, input_service)
	if not mod:is_enabled() or should_bypass_throttling() then
		pacing_reset(team_panels_timer)
		pacing_reset(personal_panel_timer)
		return func(self, dt, t, ui_renderer, render_settings, input_service)
	end

	HudElementTeamPanelHandler.super.update(self, dt, t, ui_renderer, render_settings, input_service)
	self:_player_scan(ui_renderer)

	local player_panels_array = self._player_panels_array
	if not player_panels_array then
		return
	end

	local personal_fps = mod:get("personal_player_panel_fps") or 30
	local personal_due, personal_elapsed = pacing_due(personal_panel_timer, dt, personal_fps)

	local team_fps = mod:get("team_panels_fps") or 15
	local team_due, team_elapsed = pacing_due(team_panels_timer, dt, team_fps)

	local stagger = mod:get("stagger_team_panels") ~= false
	local base_class = rawget(_G, "CLASS") and CLASS.HudElementBase

	local teammates = {}
	local teammate_count = 0

	for i = 1, #player_panels_array do
		local data = player_panels_array[i]
		local panel = data.panel
		local player = data.player
		if panel and panel.update and player and not player.__deleted then
			if data.is_my_player then
				if personal_due then
					panel:update(personal_elapsed, t, ui_renderer, render_settings, input_service)
				elseif base_class and base_class.update then
					base_class.update(panel, dt, t, ui_renderer, render_settings, input_service)
				end
			else
				teammate_count = teammate_count + 1
				teammates[teammate_count] = { data = data, panel = panel }
			end
		end
	end

	if team_due and teammate_count > 0 then
		if stagger and teammate_count > 1 then
			team_robin_index = (team_robin_index % teammate_count) + 1
			local chosen = teammates[team_robin_index]
			chosen.panel:update(team_elapsed, t, ui_renderer, render_settings, input_service)

			if base_class and base_class.update then
				for i = 1, teammate_count do
					if i ~= team_robin_index then
						base_class.update(teammates[i].panel, dt, t, ui_renderer, render_settings, input_service)
					end
				end
			end
		else
			for i = 1, teammate_count do
				teammates[i].panel:update(team_elapsed, t, ui_renderer, render_settings, input_service)
			end
		end
	elseif teammate_count > 0 then
		if base_class and base_class.update then
			for i = 1, teammate_count do
				base_class.update(teammates[i].panel, dt, t, ui_renderer, render_settings, input_service)
			end
		end
	end
end)

local function handle_buff_update(func, self, dt, t, ui_renderer, render_settings, input_service)
	local timer = self._ui_throttle_timer
	if not timer then
		timer = pacing_new()
		self._ui_throttle_timer = timer
	end

	if not mod:is_enabled() or should_bypass_throttling() or not self._syncronized then
		pacing_reset(timer)
		return func(self, dt, t, ui_renderer, render_settings, input_service)
	end

	local buffs_fps = mod:get("player_buffs_fps") or 10
	if buffs_fps <= 0 or buffs_fps >= 60 then
		pacing_reset(timer)
		return func(self, dt, t, ui_renderer, render_settings, input_service)
	end

	local due, elapsed = pacing_due(timer, dt, buffs_fps)
	if due then
		return func(self, elapsed, t, ui_renderer, render_settings, input_service)
	else
		local base_class = rawget(_G, "CLASS") and CLASS.HudElementBase
		if base_class and base_class.update then
			return base_class.update(self, dt, t, ui_renderer, render_settings, input_service)
		end
	end
end

mod:hook("HudElementPlayerBuffs", "update", handle_buff_update)

local buff_bar_hooked = false
if rawget(_G, "HudElementBuffBar") or (rawget(_G, "CLASS") and CLASS.HudElementBuffBar) then
	mod:hook("HudElementBuffBar", "update", handle_buff_update)
	buff_bar_hooked = true
end

mod.on_all_mods_loaded = function()
	if not buff_bar_hooked and (rawget(_G, "HudElementBuffBar") or (rawget(_G, "CLASS") and CLASS.HudElementBuffBar)) then
		mod:hook("HudElementBuffBar", "update", handle_buff_update)
		buff_bar_hooked = true
	end
end


