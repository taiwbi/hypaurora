-- Hypaurora Hyprland configuration
--
-- This is the native Lua configuration format supported by Hyprland 0.55+.
-- The session is intended to be started from the "Hyprland (uwsm-managed)"
-- login entry so graphical services belong to the systemd user session.

local main_mod = "SUPER"
local terminal = "uwsm app -- kitty"
local file_manager = "uwsm app -- nautilus --new-window"
local browser = "uwsm app -- brave-origin --new-window"
local neovide = 'uwsm app -- "$HOME/Documents/hypaurora/code/nvim.sh"'
local launcher = "hyprlauncher"

-- Environment consumed by GTK, Qt, portals, cursors, and applications.
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_MENU_PREFIX", "arch-")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("GTK_USE_PORTAL", "1")
hl.env("GTK_THEME", "Colloid-Dark-Catppuccin")
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_SIZE", "24")

-- A blank monitor rule is Hyprland's safe fallback for any monitor layout.
hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = 1.0,
})

hl.config({
	debug = {
		vfr = true,
	},

	general = {
		gaps_in = 6,
		gaps_out = 10,
		border_size = 2,
		resize_on_border = true,
		extend_border_grab_area = 8,
		hover_icon_on_border = true,
		allow_tearing = false,
		layout = "dwindle",
		col = {
			active_border = { colors = { "rgb(cba6f7)", "rgb(89b4fa)" }, angle = 45 },
			inactive_border = "rgba(45475aaa)",
		},
	},

	decoration = {
		rounding = 14,
		active_opacity = 1.0,
		inactive_opacity = 0.94,
		fullscreen_opacity = 1.0,
		shadow = {
			enabled = true,
			range = 24,
			render_power = 3,
			color = "rgba(00000055)",
		},
		blur = {
			enabled = true,
			size = 8,
			passes = 3,
			noise = 0.03,
			contrast = 1.0,
			brightness = 1.0,
			vibrancy = 0.18,
			ignore_opacity = true,
		},
	},

	animations = {
		enabled = true,
	},

	dwindle = {
		preserve_split = true,
		smart_split = true,
		smart_resizing = true,
	},

	master = {
		new_status = "slave",
		mfact = 0.55,
		orientation = "left",
	},

	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		force_default_wallpaper = 0,
		focus_on_activate = true,
		middle_click_paste = false,
		animate_manual_resizes = true,
		animate_mouse_windowdragging = true,
		enable_swallow = true,
		swallow_regex = "^(kitty)$",
	},

	cursor = {
		hide_on_key_press = true,
		inactive_timeout = 4,
		no_hardware_cursors = 2,
		enable_hyprcursor = true,
	},

	input = {
		kb_layout = "us,ir",
		kb_options = "caps:escape",
		numlock_by_default = true,
		repeat_rate = 50,
		repeat_delay = 300,
		follow_mouse = 1,
		float_switch_override_focus = 1,
		sensitivity = 1,
		accel_profile = "flat",
		touchpad = {
			natural_scroll = true,
			tap_to_click = true,
			disable_while_typing = true,
			middle_button_emulation = true,
		},
	},

	gestures = {
		workspace_swipe_distance = 350,
		workspace_swipe_cancel_ratio = 0.15,
		workspace_swipe_min_speed_to_force = 5,
		workspace_swipe_direction_lock = true,
		workspace_swipe_direction_lock_threshold = 10,
	},

	xwayland = {
		force_zero_scaling = true,
	},

	binds = {
		allow_workspace_cycles = true,
		workspace_back_and_forth = true,
		hide_special_on_workspace_change = true,
	},
})

-- Hyprland 0.56 replaced the old workspace_swipe_* boolean/finger settings
-- with explicit gesture declarations.
hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

-- A restrained motion system keeps the glass theme feeling responsive.
hl.curve("hypauroraEase", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.animation({ leaf = "global", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.5, bezier = "hypauroraEase" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.5, bezier = "hypauroraEase", style = "popin 85%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3.5, bezier = "hypauroraEase", style = "popin 85%" })
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "hypauroraEase" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "hypauroraEase", style = "fade" })

-- Keep common dialogs centered without turning normal application windows
-- into floating windows. Nautilus remains tiled; its chooser dialogs float.
hl.window_rule({
	name = "portal-file-chooser",
	match = {
		class = "^(org.gnome.Nautilus|xdg-desktop-portal-gnome)$",
		title = "(?i)^(open|save|choose|select|pick|file chooser)",
	},
	float = true,
	center = true,
})

hl.window_rule({
	name = "hyprlauncher",
	match = { class = "^(hyprlauncher)$" },
	float = true,
	center = true,
})

hl.window_rule({
	name = "polkit-agent",
	match = { class = "^(hyprpolkitagent)$" },
	float = true,
	center = true,
})

hl.window_rule({
	name = "suppress-maximize",
	match = { class = ".*" },
	suppress_event = "maximize",
})

local function exec(command)
	return hl.dsp.exec_cmd(command)
end

local function focus(direction)
	hl.bind(main_mod .. " + " .. direction.key, hl.dsp.focus({ direction = direction.value }))
end

local function move(direction)
	hl.bind(main_mod .. " + SHIFT + " .. direction.key, hl.dsp.window.swap({ direction = direction.value }))
end

local function resize(direction)
	hl.bind(
		main_mod .. " + CTRL + " .. direction.key,
		hl.dsp.window.resize({
			x = direction.x,
			y = direction.y,
			relative = true,
		})
	)
end

-- Launch systemd-managed services and make the compositor environment visible
-- to D-Bus activation. This deliberately does not start polkit or portal
-- daemons by hand: their packaged user services own those processes.
hl.on("hyprland.start", function()
	hl.exec_cmd(
		"dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE HYPRLAND_INSTANCE_SIGNATURE"
	)
	hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark")
	hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme Colloid-Dark-Catppuccin")
	hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme Bibata-Modern-Classic")
	hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size 24")
end)

-- Core applications.
hl.bind(main_mod .. " + RETURN", exec(terminal), { description = "Open terminal" })
hl.bind(main_mod .. " + A", exec(launcher), { description = "Open application launcher" })
hl.bind(main_mod .. " + X", exec(file_manager), { description = "Open Nautilus" })
hl.bind(main_mod .. " + B", exec(browser), { description = "Open browser" })
hl.bind(main_mod .. " + BACKSLASH", exec(neovide), { description = "Open Neovide" })
hl.bind(main_mod .. " + P", exec("uwsm app -- gnome-control-center"), { description = "Open GNOME settings" })
hl.bind(main_mod .. " + ESCAPE", exec("hyprlock"), { description = "Lock screen" })
hl.bind(main_mod .. " + ALT + M", exec("hyprshutdown"), { description = "Log out" })
hl.bind(main_mod .. " + SHIFT + ESCAPE", exec("hyprshutdown"), { description = "Log out" })
-- Layout and window actions.
hl.bind(main_mod .. " + Q", hl.dsp.window.close(), { description = "Close focused window" })
hl.bind(main_mod .. " + SHIFT + Q", hl.dsp.window.kill(), { description = "Force-close focused window" })
hl.bind(main_mod .. " + V", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle floating" })
hl.bind(main_mod .. " + I", hl.dsp.layout("togglesplit"), { description = "Toggle split direction" })
hl.bind(main_mod .. " + F", hl.dsp.window.fullscreen(), { description = "Toggle fullscreen" })
hl.bind(main_mod .. " + S", hl.dsp.workspace.toggle_special("magic"), { description = "Toggle scratchpad" })

for _, direction in ipairs({
	{ key = "H", value = "left", x = -40, y = 0 },
	{ key = "L", value = "right", x = 40, y = 0 },
	{ key = "K", value = "up", x = 0, y = -40 },
	{ key = "J", value = "down", x = 0, y = 40 },
}) do
	focus(direction)
	move(direction)
	resize(direction)
end

-- Keyboard layout switching is intentionally a compositor dispatch. The
-- per-window Rust helper observes it and remembers the selected layout for
-- each application/window.
hl.bind(main_mod .. " + SPACE", exec("hyprctl switchxkblayout current next"), {
	description = "Switch between US and Persian layout",
})

for _, binding in ipairs({
	{ "1", 1 },
	{ "2", 2 },
	{ "3", 3 },
	{ "4", 4 },
	{ "5", 5 },
	{ "6", 6 },
	{ "7", 7 },
	{ "8", 8 },
	{ "9", 9 },
	{ "0", 10 },
}) do
	local key = binding[1]
	local workspace = binding[2]
	hl.bind(
		main_mod .. " + " .. key,
		hl.dsp.focus({ workspace = workspace }),
		{ description = "Switch to workspace " .. workspace }
	)
	hl.bind(main_mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }), {
		description = "Move window to workspace " .. workspace,
	})
end

hl.bind(main_mod .. " + SHIFT + TAB", hl.dsp.window.move({ workspace = "special:magic" }), {
	description = "Move window to scratchpad",
})
hl.bind(main_mod .. " + TAB", hl.dsp.focus({ workspace = "previous" }), { description = "Previous workspace" })
hl.bind(main_mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(main_mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Multimedia keys.
hl.bind(
	"XF86AudioRaiseVolume",
	exec("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true }
)
hl.bind("XF86AudioLowerVolume", exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", exec("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", exec("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Screenshots, clipboard color picking, and the system picker.
hl.bind(
	"PRINT",
	exec("grim - | tee \"$HOME/Pictures/Screenshots/Hyprland $(date +'%Y-%m-%d %H-%M-%S').png\" | wl-copy"),
	{
		description = "Copy full-screen screenshot",
	}
)
hl.bind(
	main_mod .. " + PRINT",
	exec('grim -g "$(slurp)" - | tee "$HOME/Pictures/Screenshots/Region $(date +\'%Y-%m-%d %H-%M-%S\').png" | wl-copy'),
	{
		description = "Copy selected screenshot",
	}
)
hl.bind(main_mod .. " + SHIFT + P", exec("hyprpicker -a"), { description = "Pick a color" })

-- Mouse actions.
hl.bind(main_mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(main_mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.workspace_rule({ workspace = "special:magic", gaps_in = 8, gaps_out = 12 })
