### [UI Throttle](https://www.nexusmods.com/warhammer40kdarktide/mods/1386)
<img width="863" height="863" alt="image" src="https://github.com/user-attachments/assets/d33c89bb-b258-4f1a-8f04-d7491f04022c" />

Throttles UI update rates to improve CPU performance.

This is a performance tool for people who want to squeeze out as many frames as possible, especially if your CPU is the bottleneck and you run a lot of HUD mods.

**How it works (the simple version):**
- Every HUD element (team panels, buff bars, markers, modded HUDs, etc.) normally refreshes its info every single frame. At 144 fps that's 144 times a second, way more than you can actually see.
- UI Throttle puts each element on a schedule instead (30 times a second by default, markers at 60) and skips the frames in between.
- Animations still move every frame so everything stays smooth, they just get new info less often.
- Anything that needs your input right away (tagging, crosshair, interacting, the tactical overlay, etc.) is never throttled.
- If a mod already throttles itself (like HUD Studio), UI Throttle notices and leaves it alone so it doesn't get slowed down twice.
- It turns itself off while you're in menus, chat, or have your cursor out.

If something from another mod looks off while using this, try it with UI Throttle turned off (the toggle hotkey works for this) before reporting it to that mod's author :P If UI Throttle is the cause, let me know so I can fix it!

**There is a protected element list at the top of `UIThrottle.lua` that you can edit to exempt elements that are having issues.**

**For mod authors:** if your HUD element already throttles itself, just add `self._ui_throttle_exempt = true` in its `init` (or put it on the class) and UI Throttle will skip it.

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
</details>

- **Links:** [Source Code](https://github.com/MaddyMarv/UI-Throttle) | [Nexus Mods Profile](https://www.nexusmods.com/profile/indicabunny) | [Support Me on Ko-fi](https://ko-fi.com/indicabunny)
