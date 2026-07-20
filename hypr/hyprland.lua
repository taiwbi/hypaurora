------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = "1",
})

---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use
local terminal = "ghostty"
local fileManager = "nautilus"
local codeEditor = os.getenv("HOME") .. "/.local/bin/zed"
local menu = "ags request launcher"
local browser = "firefox"

-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
hl.on("hyprland.start", function()
	hl.exec_cmd("eval $(/usr/bin/gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)")
	hl.exec_cmd("/usr/libexec/polkit-mate-authentication-agent-1")
	hl.exec_cmd('eval "$(ssh-agent -s)"')
	hl.exec_cmd("systemctl --user start xdg-desktop-portal-gnome")

    hl.exec_cmd("pkill orca")

    hl.exec_cmd(os.getenv("HOME") .. "/.config/ags/run.sh")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_THEME", "MacTahoe")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.env("GTK_USE_PORTAL", "1")

hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_QPA_QPLATFORMTHEME", "gnome")

hl.env("ICON_THEME", "Neuwaita")
hl.env("SSH_AUTH_SOCK", "/run/user/1000/keyring/ssh")

-----------------------
----- PERMISSIONS -----
-----------------------

-- TODO: See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--   ecosystem = {
--     enforce_permissions = true,
--   },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")

-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
-- Migrated from hypr-old/look.conf
hl.config({
	general = {
		gaps_in = 3,
		gaps_out = 5,
		border_size = 2,

		col = {
			active_border = { colors = { "rgb(b8bb26)", "rgb(b16286)" }, angle = 25 },
			inactive_border = { colors = { "rgb(282828)" }, angle = 25 },
		},

		allow_tearing = false,
		layout = "dwindle",
	},

	group = {
		col = {
			border_active = { colors = { "rgb(585588)", "rgb(689d6a)" }, angle = 25 },
			border_inactive = { colors = { "rgb(282828)" }, angle = 25 },
		},

		groupbar = {
			enabled = true,
			font_family = "Geist",
			font_size = 14,
			gradients = true,
			font_weight_active = "bold",
			font_weight_inactive = "light",
			height = 31,
			rounding = 0,
			indicator_height = 3,
			col = {
				active = "rgb(282828)",
				inactive = "rgba(282828aa)",
			},
			keep_upper_gap = false,
		},
	},

	decoration = {
		rounding = 12,

		active_opacity = 1,
		inactive_opacity = 0.9,
		fullscreen_opacity = 1,

		blur = {
			enabled = true,
			size = 12,
			passes = 3,
			noise = 0.05,
			ignore_opacity = true,
			special = true,
			popups = true,
		},

		shadow = {
			enabled = true,
			color = 0x66131313, -- rgba(19, 19, 19, 0.4)
			range = 18,
		},
	},

	animations = {
		enabled = true,
	},
})

-- Beziers migrated from hypr-old/animations.conf
hl.curve("easeInSine", { type = "bezier", points = { { 0.12, 0 }, { 0.39, 0 } } })
hl.curve("easeOutSine", { type = "bezier", points = { { 0.61, 1 }, { 0.88, 1 } } })
hl.curve("easeInOutSine", { type = "bezier", points = { { 0.37, 0 }, { 0.63, 1 } } })

hl.curve("easeInQuad", { type = "bezier", points = { { 0.11, 0 }, { 0.5, 0 } } })
hl.curve("easeOutQuad", { type = "bezier", points = { { 0.5, 1 }, { 0.89, 1 } } })
hl.curve("easeInOutQuad", { type = "bezier", points = { { 0.45, 0 }, { 0.55, 1 } } })

hl.curve("easeInCubic", { type = "bezier", points = { { 0.32, 0 }, { 0.67, 0 } } })
hl.curve("easeOutCubic", { type = "bezier", points = { { 0.33, 1 }, { 0.68, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0 }, { 0.35, 1 } } })

hl.curve("easeInQuart", { type = "bezier", points = { { 0.5, 0 }, { 0.75, 0 } } })
hl.curve("easeOutQuart", { type = "bezier", points = { { 0.25, 1 }, { 0.5, 1 } } })
hl.curve("easeInOutQuart", { type = "bezier", points = { { 0.76, 0 }, { 0.24, 1 } } })

hl.curve("easeInQuint", { type = "bezier", points = { { 0.64, 0 }, { 0.78, 0 } } })
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.22, 1 }, { 0.36, 1 } } })
hl.curve("easeInOutQuint", { type = "bezier", points = { { 0.83, 0 }, { 0.17, 1 } } })

hl.curve("easeInExpo", { type = "bezier", points = { { 0.7, 0 }, { 0.84, 0 } } })
hl.curve("easeOutExpo", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })
hl.curve("easeInOutExpo", { type = "bezier", points = { { 0.87, 0 }, { 0.13, 1 } } })

hl.curve("easeInCirc", { type = "bezier", points = { { 0.55, 0 }, { 1, 0.45 } } })
hl.curve("easeOutCirc", { type = "bezier", points = { { 0, 0.55 }, { 0.45, 1 } } })
hl.curve("easeInOutCirc", { type = "bezier", points = { { 0.85, 0 }, { 0.15, 1 } } })

hl.curve("easeInBack", { type = "bezier", points = { { 0.36, 0 }, { 0.66, -0.56 } } })
hl.curve("easeOutBack", { type = "bezier", points = { { 0.34, 1.56 }, { 0.64, 1 } } })
hl.curve("easeInOutBack", { type = "bezier", points = { { 0.68, -0.6 }, { 0.32, 1.6 } } })

-- Elastic/bounce curves are approximations (true elastic/bounce need keyframes), same as in hypr-old
hl.curve("easeInElastic", { type = "bezier", points = { { 0.5, -0.5 }, { 0.75, 1.25 } } })
hl.curve("easeOutElastic", { type = "bezier", points = { { 0.25, -0.25 }, { 0.5, 1.5 } } })
hl.curve("easeInOutElastic", { type = "bezier", points = { { 0.5, -0.5 }, { 0.5, 1.5 } } })

hl.curve("easeInBounce", { type = "bezier", points = { { 0.3, 0 }, { 0.7, 0.3 } } })
hl.curve("easeOutBounce", { type = "bezier", points = { { 0.3, 0.7 }, { 0.7, 1 } } })
hl.curve("easeInOutBounce", { type = "bezier", points = { { 0.68, -0.55 }, { 0.265, 1.55 } } })
hl.curve("test", { type = "bezier", points = { { 0, 1 }, { 0, 1 } } })

hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "easeOutExpo", style = "fade" })
hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "easeInElastic", style = "popin 80%" })
hl.animation({ leaf = "layers", enabled = true, speed = 4, bezier = "easeOutExpo", style = "popin 90%" })

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
-- hypr-old only configures dwindle (general.layout = dwindle); master/scrolling
-- blocks were removed since they weren't set in hypr-old.
hl.config({
	dwindle = {
		preserve_split = true,
		force_split = 2,
		smart_resizing = true,
	},
})

----------------
----  MISC  ----
----------------

-- Migrated from hypr-old/look.conf misc{} block
hl.config({
	misc = {
		disable_hyprland_logo = true,
		disable_autoreload = false,
		anr_missed_pings = 5,
	},
})

---------------
---- INPUT ----
---------------

hl.config({
	input = {
		kb_layout = "us,ir",
		kb_variant = "",
		kb_model = "",
		kb_options = "caps:escape",
		kb_rules = "",

		follow_mouse = 1,
		mouse_refocus = false,
		float_switch_override_focus = 0,
		scroll_factor = 1.0,

		sensitivity = 0.3, -- -1.0 - 1.0, 0 means no modification.
		accel_profile = "flat",

		touchpad = {
			natural_scroll = true,
			disable_while_typing = true,
			middle_button_emulation = true,
			clickfinger_behavior = true,
			drag_lock = true,
			tap_and_drag = true,
			tap_to_click = true,
		},
	},

	xwayland = {
		use_nearest_neighbor = true,
		force_zero_scaling = true,
	},
})

hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

-- TODO:: Checkout what other gestures you can do :)

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
-- hl.device({
-- 	name = "epic-mouse-v1",
-- 	sensitivity = -0.5,
-- })

hl.device({
	name = "elan1300:00-04f3:3087-touchpad",
	enabled = true,
})

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

hl.bind(mainMod .. " + ALT + M", hl.dsp.exit())
hl.bind(mainMod .. " + space", hl.dsp.exec_cmd(os.getenv("HOME") .. '/Documents/hypaurora/code/osd/keyboard'))

-- Migrated from hypr-old/keybind.conf
hl.bind(
	mainMod .. " + Return",
	hl.dsp.exec_cmd("__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia " .. terminal)
)

hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + backslash", hl.dsp.exec_cmd(codeEditor))
hl.bind(mainMod .. " + ALT + backslash", hl.dsp.exec_cmd(os.getenv("HOME") .. "/Documents/hypaurora/code/nvim.sh"))
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + SHIFT + X", hl.dsp.exec_cmd("nautilus -q"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("XDG_CURRENT_DESKTOP=GNOME gnome-control-center"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("XDG_CURRENT_DESKTOP=GNOME " .. browser .. " --new-window"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("XDG_CURRENT_DESKTOP=GNOME flatpak run org.telegram.desktop"))

hl.bind(mainMod .. " + code:59", hl.dsp.exec_cmd("pkill hyprpaper"))
hl.bind(mainMod .. " + ALT + code:59", hl.dsp.exec_cmd("hyprpaper"))

-- Move focus with mainMod + vim direction keys
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

-- swap active with mainMod + SHIFT + vim direction keys
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.swap({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.swap({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.swap({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.swap({ direction = "d" }))

-- Resize focus with mainMod + CTRL + vim direction keys (repeating, like the old `binde`)
hl.bind(mainMod .. " + CTRL + H", hl.dsp.window.resize({ x = -100, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + L", hl.dsp.window.resize({ x = 100, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + K", hl.dsp.window.resize({ x = 0, y = -100, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + J", hl.dsp.window.resize({ x = 0, y = 100, relative = true }), { repeating = true })

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Switch workspaces with mainMod + [1-5, Q-T, "-"]
hl.bind(mainMod .. " + 1", hl.dsp.focus({ workspace = 1 }))
hl.bind(mainMod .. " + 2", hl.dsp.focus({ workspace = 2 }))
hl.bind(mainMod .. " + 3", hl.dsp.focus({ workspace = 3 }))
hl.bind(mainMod .. " + 4", hl.dsp.focus({ workspace = 4 }))
hl.bind(mainMod .. " + 5", hl.dsp.focus({ workspace = 5 }))
hl.bind(mainMod .. " + Q", hl.dsp.focus({ workspace = 6 }))
hl.bind(mainMod .. " + W", hl.dsp.focus({ workspace = 7 }))
hl.bind(mainMod .. " + E", hl.dsp.focus({ workspace = 8 }))
hl.bind(mainMod .. " + R", hl.dsp.focus({ workspace = 9 }))
hl.bind(mainMod .. " + T", hl.dsp.focus({ workspace = 10 }))
hl.bind(mainMod .. " + code:20", hl.dsp.focus({ workspace = 11 })) -- Key "-"

-- Move active window to a workspace with mainMod + SHIFT + [1-5, Q-T]
hl.bind(mainMod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = 1 }))
hl.bind(mainMod .. " + SHIFT + 2", hl.dsp.window.move({ workspace = 2 }))
hl.bind(mainMod .. " + SHIFT + 3", hl.dsp.window.move({ workspace = 3 }))
hl.bind(mainMod .. " + SHIFT + 4", hl.dsp.window.move({ workspace = 4 }))
hl.bind(mainMod .. " + SHIFT + 5", hl.dsp.window.move({ workspace = 5 }))
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.move({ workspace = 6 }))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.window.move({ workspace = 7 }))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.window.move({ workspace = 8 }))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.window.move({ workspace = 9 }))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.window.move({ workspace = 10 }))

-- Special workspace (scratchpad) - old had a stray `SHIFT+S -> movetoworkspace +1`
-- bind that got overridden later in the same file by the special-workspace bind
-- below, so only the final, effective behavior was migrated.
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(mainMod .. " + SHIFT + ALT + A", hl.dsp.window.move({ workspace = "special" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e+1" }))

-- Grouping window shortcuts
hl.bind(mainMod .. " + G", hl.dsp.group.toggle())
hl.bind(mainMod .. " + TAB", hl.dsp.group.next())

-- Move window/group with mainMod + arrow keys
hl.bind(mainMod .. " + right", hl.dsp.window.move({ direction = "r", group_aware = true }))
hl.bind(mainMod .. " + left", hl.dsp.window.move({ direction = "l", group_aware = true }))
hl.bind(mainMod .. " + up", hl.dsp.window.move({ direction = "u", group_aware = true }))
hl.bind(mainMod .. " + down", hl.dsp.window.move({ direction = "d", group_aware = true }))

-- Change window states
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.window.kill())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen_state({ internal = 0, client = 2 }))
hl.bind(mainMod .. " + ALT + F", hl.dsp.window.fullscreen_state({ internal = 2, client = 0 }))
hl.bind(mainMod .. " + D", hl.dsp.window.fullscreen_state({ internal = 0, client = 0 }))
hl.bind(mainMod .. " + Y", hl.dsp.window.center())
hl.bind(mainMod .. " + I", hl.dsp.layout("togglesplit")) -- dwindle only

-- Keyboard system tweak keys (old pointed these at custom osd scripts, not wpctl/brightnessctl directly)
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd(os.getenv("HOME") .. "/Documents/hypaurora/code/osd/volume --raise 5"),
	{ repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd(os.getenv("HOME") .. "/Documents/hypaurora/code/osd/volume --lower 5"),
	{ repeating = true }
)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(os.getenv("HOME") .. "/Documents/hypaurora/code/osd/volume --toggle-mute"))
hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd(os.getenv("HOME") .. "/Documents/hypaurora/code/osd/brightness --raise 5")
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd(os.getenv("HOME") .. "/Documents/hypaurora/code/osd/brightness --lower 5")
)
hl.bind("XF86TouchpadToggle", hl.dsp.exec_cmd(os.getenv("HOME") .. "/Documents/hypaurora/code/osd/touchpad"))

-- Take screenshot
hl.bind(
	"SHIFT + Print",
	hl.dsp.exec_cmd(
		"grim - | tee \"$HOME/Pictures/Screenshots/HyprShot From $(date +'%Y-%m-%d %H-%M-%S.png')\" | wl-copy"
	),
	{ locked = true }
)
hl.bind(
	"Print",
	hl.dsp.exec_cmd(
		'geometry=$(slurp -d) && grim -g "$geometry" - | tee "$HOME/Pictures/Screenshots/HyprShot From $(date +\'%Y-%m-%d %H-%M-%S.png\')" | wl-copy'
	)
)
hl.bind(
	"CTRL + Print",
	hl.dsp.exec_cmd(
		"hyprpicker 2>/dev/null | grep -Eo '[0-9a-fA-F]{6}' | head -n1 | awk '{printf \"\\x23%s\", $0}' | tr -d '\\n' | wl-copy"
	)
)

-- Accessibility
hl.bind(mainMod .. " + ALT + code:21", hl.dsp.exec_cmd("pypr zoom ++0.5")) -- + =
hl.bind(mainMod .. " + ALT + code:20", hl.dsp.exec_cmd("pypr zoom --0.5")) -- - _
hl.bind(mainMod .. " + ALT + 0", hl.dsp.exec_cmd("pypr zoom"))
hl.bind(mainMod .. " + code:49", hl.dsp.focus({ workspace = 25 }))
hl.bind(mainMod .. " + SHIFT + code:49", hl.dsp.focus({ workspace = "previous" }))

-- Lock the screen
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd(os.getenv("HOME") .. "/Documents/hypaurora/code/lock.sh"))

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Migrated from hypr-old/window.conf

hl.window_rule({
	-- Ignore maximize requests from all apps. You'll probably like this.
	name = "suppress-maximize-events",
	match = { class = ".*" },

	suppress_event = "maximize",
})

-- Size
hl.window_rule({
	name = "shotwell-add-tags-size",
	match = { class = "org.gnome.Shotwell", title = "Add Tags" },
	size = "15% 40%",
})
hl.window_rule({
	name = "shotwell-modify-tags-size",
	match = { class = "org.gnome.Shotwell", title = "Modify Tags" },
	size = "15% 40%",
})
hl.window_rule({
	name = "shotwell-profile-size",
	match = { class = "org.gnome.Shotwell", title = "Choose Shotwell's profile" },
	size = "430 560",
})
hl.window_rule({
	name = "xdg-portal-gtk-size",
	match = { class = "xdg-desktop-portal-gtk" },
	size = "55% 70%",
})
hl.window_rule({
	name = "choose-files-size",
	match = { title = "Choose Files" },
	size = "55% 70%",
})
hl.window_rule({
	name = "gnome-builder-prefs-size",
	match = { class = "gnome-builder", title = "Builder — Preferences" },
	size = "55% 70%",
})
hl.window_rule({
	name = "packettracer-size",
	match = { class = "PacketTracer", title = "^(.*[1-9])$" },
	size = "55% 70%",
})
hl.window_rule({
	name = "jetbrains-welcome-size",
	match = { class = "jetbrains-.*", title = "^(Welcome to .*)$" },
	size = "55% 70%",
})

-- Center, float, sized
hl.window_rule({
	name = "packet-window",
	match = { class = "io.github.nozwock.Packet" },
	size = "430 750",
	float = true,
	center = true,
})
hl.window_rule({
	name = "amberol-window",
	match = { class = "io.bassi.Amberol" },
	size = "430 750",
	float = true,
	center = true,
})

-- Center & float
hl.window_rule({
	name = "packettracer-float",
	match = { title = "^(.*[1-9])$", class = "PacketTracer" },
	float = true,
	center = true,
})
hl.window_rule({
	name = "import-files-dialog",
	match = { title = "^(Import Files…)$" },
	float = true,
	center = true,
})
hl.window_rule({
	name = "nautilus-open",
	match = { class = "org.gnome.Nautilus", title = "^(.*open)" },
	float = true,
	center = true,
})
hl.window_rule({
	name = "nautilus-save",
	match = { class = "org.gnome.Nautilus", title = "^(.*save)" },
	float = true,
	center = true,
})
hl.window_rule({
	name = "nautilus-pick",
	match = { class = "org.gnome.Nautilus", title = "^(Pick.*)" },
	float = true,
	center = true,
})
hl.window_rule({
	name = "nautilus-open2",
	match = { class = "org.gnome.Nautilus", title = "^(Open.*)" },
	float = true,
	center = true,
})
hl.window_rule({
	name = "nautilus-save2",
	match = { class = "org.gnome.Nautilus", title = "^(Save.*)" },
	float = true,
	center = true,
})
hl.window_rule({
	name = "nautilus-select",
	match = { class = "org.gnome.Nautilus", title = "^(Select.*)" },
	float = true,
	center = true,
})
hl.window_rule({
	name = "nautilus-choose",
	match = { class = "org.gnome.Nautilus", title = "^(Choose.*)" },
	float = true,
	center = true,
})
hl.window_rule({
	name = "nautilus-set",
	match = { class = "org.gnome.Nautilus", title = "^(Set.*)" },
	float = true,
	center = true,
})
hl.window_rule({
	name = "shotwell-add-tags-center",
	match = { class = "org.gnome.Shotwell", title = "Add Tags" },
	center = true,
})
hl.window_rule({
	name = "shotwell-modify-tags-center",
	match = { class = "org.gnome.Shotwell", title = "Modify Tags" },
	center = true,
})
hl.window_rule({
	name = "shotwell-profile-float",
	match = { class = "org.gnome.Shotwell", title = "Choose Shotwell's profile" },
	float = true,
	center = true,
})
hl.window_rule({
	name = "xdg-portal-gtk-float",
	match = { class = "xdg-desktop-portal-gtk" },
	float = true,
	center = true,
})
hl.window_rule({
	name = "choose-files-float",
	match = { title = "Choose Files" },
	float = true,
	center = true,
})
hl.window_rule({
	name = "gnome-builder-prefs-float",
	match = { class = "gnome-builder", title = "Builder — Preferences" },
	float = true,
	center = true,
})
hl.window_rule({
	name = "libreoffice-startcenter-center",
	match = { class = "libreoffice-startcenter" },
	center = true,
})
hl.window_rule({
	name = "jetbrains-welcome-float",
	match = { class = "jetbrains-.*", title = "^(Welcome to .*)$" },
	float = true,
	center = true,
})
hl.window_rule({
	name = "vscode-center",
	match = { class = "Code" },
	center = true,
})
hl.window_rule({
	name = "file-picker-float",
	match = { class = "^(file-.*)$" },
	float = true,
	center = true,
})
hl.window_rule({
	name = "hyprland-share-picker",
	match = { class = "^(hyprland-share-picker)$" },
	float = true,
	center = true,
})
hl.window_rule({
	name = "cursor-center",
	match = { class = "^(Cursor)$" },
	center = true,
})
hl.window_rule({
	name = "windsurf-center",
	match = { class = "^(Windsurf)$" },
	center = true,
})

-- Immediate (no vsync, for games)
-- NOTE: `immediate` as a window_rule field is a guess (single-word literal
-- Hyprland dispatcher name) - verify.
hl.window_rule({
	name = "minecraft-immediate",
	match = { class = "Minecraft.*" },
	immediate = true,
})
hl.window_rule({
	name = "lunar-immediate",
	match = { class = "Lunar.*" },
	immediate = true,
})

-- Others
-- NOTE: `stay_focused` field name is a guess (snake_case of `stayfocused`) - verify.
hl.window_rule({
	name = "shotwell-add-tags-stayfocused",
	match = { class = "org.gnome.Shotwell", title = "Add Tags" },
	stay_focused = true,
})
hl.window_rule({
	name = "shotwell-modify-tags-stayfocused",
	match = { class = "org.gnome.Shotwell", title = "Modify" },
	stay_focused = true,
})

-- Fix some dragging issues with XWayland
hl.window_rule({
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},

	no_focus = true,
})

-- Layer rules
-- TODO: `ignorezero` from hypr-old (ignore layer alpha==0 for blur purposes)
-- has no working field name yet - `ignore_zero` errored. Check the hl API
-- docs for the correct key and add it to the three rules below.
hl.layer_rule({ name = "gtk-layer-shell-blur", match = { namespace = "^gtk-layer-shell$" }, blur = true })
hl.layer_rule({ name = "bar-blur", match = { namespace = "^bar$" }, blur = true })
hl.layer_rule({ name = "notifications-blur", match = { namespace = "^notifications$" }, blur = true })

hl.layer_rule({ name = "selection-noanim", match = { namespace = "^selection$" }, no_anim = true })
hl.layer_rule({ name = "hyprpicker-noanim", match = { namespace = "^hyprpicker$" }, no_anim = true })
hl.layer_rule({
	name = "hypaurora-notifications-noanim",
	match = { namespace = "^hypaurora-notifications$" },
	no_anim = true,
})
