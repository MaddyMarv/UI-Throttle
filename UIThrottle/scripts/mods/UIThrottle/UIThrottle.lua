local mod = get_mod("UIThrottle")

local general_hud_timer = 0
local entire_hud_ticks = 0
local team_panels_timer = 0
local personal_panel_timer = 0
local hud_studio_timer = 0
local hud_studio_ticks = 0
local world_markers_timer = 0
local hud_canvas_hooked = false

mod:hook("UIHud", "update", function(func, self, dt, t, input_service)
	if not mod:is_enabled() or not mod:get("enable_hud_throttle") then
		return func(self, dt, t, input_service)
	end

	local target_fps = mod:get("general_hud_fps") or 30
	if target_fps <= 0 then
		return func(self, dt, t, input_service)
	end

	local update_interval = 1 / target_fps

	general_hud_timer = general_hud_timer + dt
	world_markers_timer = world_markers_timer + dt

	if general_hud_timer >= update_interval then
		entire_hud_ticks = entire_hud_ticks + 1
		if mod:get("show_tick_echo") then
			mod:echo(string.format("{#color(100,255,100)}[HUD TICK #%d] (%.1fs){#reset()}", entire_hud_ticks, update_interval))
		end

		func(self, general_hud_timer, t, input_service)
		general_hud_timer = 0
		world_markers_timer = 0
	else
		if mod:get("override_world_markers") then
			local wm_fps = mod:get("world_markers_fps") or 60
			local wm_interval = wm_fps > 0 and (1 / wm_fps) or 0

			if wm_interval <= 0 or world_markers_timer >= wm_interval then
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

						wm:update(world_markers_timer, t, ui_renderer, render_settings, input_service)

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

						np:update(world_markers_timer, t, ui_renderer, render_settings, input_service)

						if applied_scale then
							self:_abort_hud_scale()
							if ui_renderer and render_settings then
								ui_renderer.scale = render_settings.scale
								ui_renderer.inverse_scale = render_settings.inverse_scale
							end
						end
					end
				end

				world_markers_timer = 0
			end
		end
	end
end)

mod:hook("HudElementTeamPanelHandler", "update", function(func, self, dt, t, ui_renderer, render_settings, input_service)
	if not mod:is_enabled() then
		return func(self, dt, t, ui_renderer, render_settings, input_service)
	end

	local override_team = mod:get("override_team_panels")
	local override_personal = mod:get("override_personal_player_panel")

	if not override_team and not override_personal then
		return func(self, dt, t, ui_renderer, render_settings, input_service)
	end

	HudElementTeamPanelHandler.super.update(self, dt, t, ui_renderer, render_settings, input_service)
	self:_player_scan(ui_renderer)

	local player_panels_array = self._player_panels_array
	if not player_panels_array then
		return
	end

	local team_fps = mod:get("team_panels_fps") or 15
	local team_interval = team_fps > 0 and (1 / team_fps) or 0
	team_panels_timer = team_panels_timer + dt
	local update_team = not override_team or team_interval <= 0 or team_panels_timer >= team_interval

	local personal_fps = mod:get("personal_player_panel_fps") or 30
	local personal_interval = personal_fps > 0 and (1 / personal_fps) or 0
	personal_panel_timer = personal_panel_timer + dt
	local update_personal = not override_personal or personal_interval <= 0 or personal_panel_timer >= personal_interval

	local base_class = rawget(_G, "CLASS") and CLASS.HudElementBase

	for i = 1, #player_panels_array do
		local data = player_panels_array[i]
		local panel = data.panel
		if panel and panel.update then
			if data.is_my_player then
				if update_personal then
					panel:update(personal_panel_timer, t, ui_renderer, render_settings, input_service)
				elseif base_class and base_class.update then
					base_class.update(panel, dt, t, ui_renderer, render_settings, input_service)
				end
			else
				if update_team then
					panel:update(team_panels_timer, t, ui_renderer, render_settings, input_service)
				elseif base_class and base_class.update then
					base_class.update(panel, dt, t, ui_renderer, render_settings, input_service)
				end
			end
		end
	end

	if update_personal then
		personal_panel_timer = 0
	end
	if update_team then
		team_panels_timer = 0
	end
end)

local function hook_hud_canvas()
	if hud_canvas_hooked then
		return
	end

	local hud_canvas = rawget(_G, "CLASS") and CLASS.HudCanvas
	if hud_canvas then
		hud_canvas_hooked = true
		mod:hook(hud_canvas, "update", function(func, self, dt, t, ui_renderer, render_settings, input_service)
			if not mod:is_enabled() or not mod:get("override_hud_studio") then
				return func(self, dt, t, ui_renderer, render_settings, input_service)
			end

			local hud_studio = rawget(_G, "get_mod") and get_mod("hud_studio")
			if hud_studio and hud_studio.hud_studio_editor_active then
				return func(self, dt, t, ui_renderer, render_settings, input_service)
			end

			local target_fps = mod:get("hud_studio_fps") or 30
			if target_fps <= 0 then
				return func(self, dt, t, ui_renderer, render_settings, input_service)
			end

			local update_interval = 1 / target_fps

			hud_studio_timer = hud_studio_timer + dt

			if hud_studio_timer >= update_interval then
				hud_studio_ticks = hud_studio_ticks + 1
				if mod:get("show_tick_echo") then
					mod:echo(string.format("{#color(255,100,100)}[HUD STUDIO TICK #%d] (%.1fs){#reset()}", hud_studio_ticks, update_interval))
				end

				func(self, hud_studio_timer, t, ui_renderer, render_settings, input_service)
				hud_studio_timer = 0
			else
				hud_canvas.super.update(self, dt, t, ui_renderer, render_settings, input_service)
			end
		end)
	end
end

hook_hud_canvas()

mod.on_all_mods_loaded = function()
	hook_hud_canvas()
end

mod:hook_safe("UIHud", "init", function(self)
	hook_hud_canvas()
end)
