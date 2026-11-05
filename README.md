### [UI Throttle](https://www.nexusmods.com/warhammer40kdarktide/mods/1386)
<img width="863" height="863" alt="image" src="https://github.com/user-attachments/assets/d33c89bb-b258-4f1a-8f04-d7491f04022c" />

Throttles UI update rates to improve CPU performance.

This is a performance tool for people who want to squeeze out as many frames as possible, especially if your CPU is the bottleneck and you run a lot of HUD mods.

**How it works (the simple version):**
- Every HUD element (team panels, buff bars, markers, modded HUDs, etc.) normally refreshes its info every single frame. At 144 fps that's 144 times a second, way more than you can actually see.
- UI Throttle puts each element on a schedule instead (30 times a second by default, markers at 60) and skips the frames in between.
- Animations still move every frame so everything stays smooth, they just get new info less often.
- Anything that needs your input right away (tagging, crosshair, interacting, the tactical overlay, etc.) is never throttled.
- If a mod opts out or already throttles itself (like HUD Studio), UI Throttle leaves it alone so it doesn't get slowed down twice.
- It turns itself off while you're in menus, chat, or have your cursor out.

Modded HUDs, and vanilla gauges like stamina, dodges and peril, run at the General HUD rate unless they opt out. That includes timing cues like a charge-ready indicator. If one feels a little late, raise General HUD Rate or set it to 0.

If something from another mod looks off while using this, try it with UI Throttle turned off (the toggle hotkey works for this) before reporting it to that mod's author :P If UI Throttle is the cause, let me know so I can fix it! Typing `/uithrottle_status` in chat shows what UI Throttle is doing with each HUD element, and pasting that into your report helps a lot.

**There is a protected element list at the top of `UIThrottle.lua` that you can edit to exempt elements that are having issues.**

<details>
<summary><b>For mod authors</b></summary>

- If your element needs to run every frame or already throttles itself, set `self._ui_throttle_exempt = true` in `init` (or on the class). Auto-detection only sees timers stored on the element itself.
- Throttling skips the whole `update()`, including any hooks on it. `draw()` still runs every frame. To opt out a vanilla element you hook, set the flag on its class with `mod:hook_require`.
- Check how your element is handled with `/uithrottle_status <name>`.

```lua
-- Your own element
HudElementMyThing.init = function(self, parent, draw_layer, start_scale)
	HudElementMyThing.super.init(self, parent, draw_layer, start_scale, Definitions)
	self._ui_throttle_exempt = true
end

-- A vanilla element you hook
mod:hook_require("scripts/ui/hud/elements/dodge_counter/hud_element_dodge_counter", function(HudElementDodgeCounter)
	HudElementDodgeCounter._ui_throttle_exempt = true
end)
```
</details>

The lower you set the rates the choppier things can look, so test what feels best for you. Markers under 60 can start to lag behind when you move the camera.

<details>
<summary><b>Mod Settings / Commands</b></summary>

**General & Controls**
- Bypass in Menus & Cursor
- Toggle UI Throttle Key (Hotkey)

**General HUD**
- General HUD Rate (FPS) (0 = off)

**Player & Team**
- Player Buffs Rate (FPS) (0 = off)
- Personal Panel Rate (FPS) (0 = off)
- Teammate Panels Rate (FPS) (0 = off)
- Stagger Teammate Updates

**World & Feed**
- World Markers & Nameplates Rate (FPS) (0 = off)
- Combat Feed Rate (FPS) (0 = off)

**Commands**
- `/uithrottle_status` - Shows how UI Throttle handles each HUD element (summary in chat, full list in the console log). Add part of a name to list only matches, e.g. `/uithrottle_status peril`.
</details>

- **Links:** [Source Code](https://github.com/MaddyMarv/UI-Throttle) | [Nexus Mods Profile](https://www.nexusmods.com/profile/indicabunny) | [Support Me on Ko-fi](https://ko-fi.com/indicabunny)
