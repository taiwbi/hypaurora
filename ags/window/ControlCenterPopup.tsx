import { createBinding, createComputed, createState, For, With } from "ags"
import app from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"
import Adw from "gi://Adw"
import Pango from "gi://Pango"
import GLib from "gi://GLib"
import Gio from "gi://Gio"
import Gdk from "gi://Gdk"
import Wp from "gi://AstalWp"
import Network from "gi://AstalNetwork"
import {
    controlCenterVisible,
    setControlCenterVisible,
    lockScreen,
    suspend,
    powerOff,
    getProxyMode,
    setProxyMode,
    getProxyAddress,
    getProxyConfig,
    setProxyConfig,
    connectToAccessPoint,
    activePowerProfile,
    setPowerProfile,
    powerProfilesAvailable,
    getBrightness,
    setBrightness,
    type PowerProfile,
    type ProxyProtocol,
    type ProxyConfig,
} from "../lib/controlcenter"

Adw.init()

// Shared proxy state so the main page tile and the proxy page stay in sync
const [proxyEnabled, setProxyEnabled] = createState(getProxyMode() === "manual")
const [proxyAddress, setProxyAddress] = createState(getProxyAddress())

function refreshProxyState() {
    setProxyEnabled(getProxyMode() === "manual")
    setProxyAddress(getProxyAddress())
}

// Power button component
function PowerButton({ icon, label, onClicked }: { icon: string, label: string, onClicked: () => void }) {
    return (
        <button cssName="power-button" onClicked={onClicked} tooltipText={label}>
            <Gtk.Image iconName={icon} pixelSize={18} />
        </button >
    )
}

// Power controls row
function PowerControls() {
    return (
        <box cssName="power-controls" spacing={12} halign={Gtk.Align.END}>
            <PowerButton
                icon="pan-up-symbolic"
                label="Suspend"
                onClicked={suspend}
            />
            <PowerButton
                icon="system-lock-screen-symbolic"
                label="Lock Screen"
                onClicked={lockScreen}
            />
            <PowerButton
                icon="system-shutdown-symbolic"
                label="Power Off"
                onClicked={powerOff}
            />
        </box>
    )
}

// User avatar + name, shown left of the power buttons
function UserProfile() {
    const username = GLib.get_user_name()
    const realName = GLib.get_real_name()
    const displayName = realName && realName !== "Unknown" ? realName : username

    const facePath = `${GLib.get_home_dir()}/.face`
    let texture: Gdk.Texture | null = null
    try {
        if (GLib.file_test(facePath, GLib.FileTest.EXISTS)) {
            texture = Gdk.Texture.new_from_file(Gio.File.new_for_path(facePath))
        }
    } catch (e) {
        console.error("Failed to load avatar:", e)
    }

    return (
        <box cssName="user-profile" spacing={10} halign={Gtk.Align.START} hexpand>
            <Adw.Avatar
                size={36}
                text={displayName}
                showInitials
                customImage={texture}
                valign={Gtk.Align.CENTER}
            />
            <label cssName="user-name" label={displayName} valign={Gtk.Align.CENTER} />
        </box>
    )
}

// Microphone tile: opens the microphone settings page
function MicTile({ nav }: { nav: () => Adw.NavigationView }) {
    const wp = Wp.get_default()
    const mic = wp?.audio?.default_microphone

    if (!mic) {
        return <box hexpand />
    }

    const muted = createBinding(mic, "mute")

    return (
        <NavTile
            icon="audio-input-microphone-symbolic"
            name="Microphone"
            description={muted((m: boolean) => m ? "Muted" : "On")}
            active={muted((m: boolean) => !m)}
            onClicked={() => nav().push_by_tag("mic")}
        />
    )
}

// Microphone page: mute switch, input volume slider, input device list
function MicPage({ nav }: { nav: () => Adw.NavigationView }) {
    const wp = Wp.get_default()
    const audio = wp?.audio

    if (!audio) {
        return (
            <Adw.NavigationPage tag="mic" title="Microphone">
                <box cssName="subpage" orientation={Gtk.Orientation.VERTICAL}>
                    <PageHeader title="Microphone" onBack={() => nav().pop()} />
                    <label label="No audio service found" />
                </box>
            </Adw.NavigationPage>
        )
    }

    const defaultMic = createBinding(audio, "defaultMicrophone")
    const microphones = createBinding(audio, "microphones")

    return (
        <Adw.NavigationPage tag="mic" title="Microphone">
            <box cssName="subpage" orientation={Gtk.Orientation.VERTICAL} spacing={12}>
                <With value={defaultMic}>
                    {(mic: Wp.Endpoint | null) => !mic ? (
                        <box orientation={Gtk.Orientation.VERTICAL}>
                            <PageHeader title="Microphone" onBack={() => nav().pop()} />
                            <label label="No microphone found" />
                        </box>
                    ) : (
                        <box orientation={Gtk.Orientation.VERTICAL} spacing={12}>
                            <PageHeader title="Microphone" onBack={() => nav().pop()}>
                                <Gtk.Switch
                                    valign={Gtk.Align.CENTER}
                                    tooltipText="Microphone on/off"
                                    active={createBinding(mic, "mute")((m: boolean) => !m)}
                                    $={(self: Gtk.Switch) => {
                                        self.connect("notify::active", () => {
                                            if (self.active === mic.mute) {
                                                mic.set_mute(!self.active)
                                            }
                                        })
                                    }}
                                />
                            </PageHeader>

                            <box cssName="slider-row" spacing={12}>
                                <Gtk.Image
                                    pixelSize={18}
                                    iconName={createBinding(mic, "mute")((m: boolean) =>
                                        m ? "microphone-sensitivity-muted-symbolic" : "audio-input-microphone-symbolic")}
                                />
                                <box cssName="slider-container" hexpand>
                                    <Gtk.Scale
                                        cssName="audio-slider"
                                        hexpand
                                        drawValue={false}
                                        $={(self: Gtk.Scale) => {
                                            const volume = createBinding(mic, "volume")
                                            const adjustment = new Gtk.Adjustment({
                                                lower: 0,
                                                upper: 1.0,
                                                step_increment: 0.01,
                                                page_increment: 0.1,
                                                value: mic.volume,
                                            })
                                            self.adjustment = adjustment

                                            let isUpdating = false
                                            volume.subscribe(() => {
                                                if (!isUpdating) {
                                                    isUpdating = true
                                                    adjustment.value = volume.get()
                                                    isUpdating = false
                                                }
                                            })
                                            self.connect("value-changed", () => {
                                                if (!isUpdating) {
                                                    isUpdating = true
                                                    mic.volume = adjustment.value
                                                    isUpdating = false
                                                }
                                            })
                                        }}
                                    />
                                </box>
                                <label
                                    cssName="slider-value"
                                    label={createBinding(mic, "volume")((v: number) => `${Math.round(v * 100)}%`)}
                                />
                            </box>
                        </box>
                    )}
                </With>

                <label cssName="section-label" label="Input Device" halign={Gtk.Align.START} />
                <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
                    <For each={microphones((mics: Wp.Endpoint[]) => mics ?? [])}>
                        {(mic: Wp.Endpoint) => {
                            const isDefault = createBinding(mic, "isDefault")
                            return (
                                <button
                                    cssName="wifi-row"
                                    class={isDefault((d: boolean) => d ? "active" : "")}
                                    onClicked={() => mic.set_is_default(true)}
                                >
                                    <box spacing={12}>
                                        <Gtk.Image iconName="audio-input-microphone-symbolic" pixelSize={16} />
                                        <label
                                            cssName="wifi-ssid"
                                            label={createBinding(mic, "description")((d: string) => d ?? "Unknown device")}
                                            halign={Gtk.Align.START}
                                            ellipsize={Pango.EllipsizeMode.END}
                                            hexpand
                                        />
                                        <Gtk.Image
                                            iconName="object-select-symbolic"
                                            pixelSize={14}
                                            visible={isDefault}
                                        />
                                    </box>
                                </button>
                            )
                        }}
                    </For>
                </box>
            </box>
        </Adw.NavigationPage>
    )
}

// Brightness slider (hidden when no backlight device supports software control)
function BrightnessSlider() {
    const [available, setAvailable] = createState(false)
    const [percent, setPercent] = createState(100)

    return (
        <box cssName="slider-row" spacing={12} visible={available}>
            <Gtk.Image iconName="display-brightness-symbolic" pixelSize={18} />
            <box cssName="slider-container" hexpand>
                <Gtk.Scale
                    cssName="audio-slider"
                    hexpand
                    drawValue={false}
                    $={(self: Gtk.Scale) => {
                        const adjustment = new Gtk.Adjustment({
                            lower: 0.01,
                            upper: 1.0,
                            step_increment: 0.01,
                            page_increment: 0.1,
                            value: 1.0,
                        })
                        self.adjustment = adjustment

                        let isUpdating = false

                        const refresh = async () => {
                            const value = await getBrightness()
                            if (value === null) {
                                setAvailable(false)
                                return
                            }
                            setAvailable(true)
                            isUpdating = true
                            adjustment.value = value
                            isUpdating = false
                        }

                        refresh()
                        controlCenterVisible.subscribe(() => {
                            if (controlCenterVisible.get()) refresh()
                        })

                        self.connect("value-changed", () => {
                            setPercent(Math.round(adjustment.value * 100))
                            if (!isUpdating) setBrightness(adjustment.value)
                        })
                    }}
                />
            </box>
            <label
                cssName="slider-value"
                label={percent((p) => `${p}%`)}
            />
        </box>
    )
}

// Audio slider component
function AudioSlider() {
    const wp = Wp.get_default()
    const audio = wp?.audio
    const speaker = audio?.default_speaker

    if (!speaker) {
        return <box />
    }

    const volume = createBinding(speaker, "volume")
    const muted = createBinding(speaker, "mute")

    const getIconName = (v: number, m: boolean) => {
        if (m) return "audio-volume-muted-symbolic"
        return v > 1.0
            ? "audio-volume-overamplified-symbolic"
            : v > 0.66
                ? "audio-volume-high-symbolic"
                : v > 0.33
                    ? "audio-volume-medium-symbolic"
                    : v > 0
                        ? "audio-volume-low-symbolic"
                        : "audio-volume-muted-symbolic"
    }

    return (
        <box cssName="slider-row" spacing={12}>
            <Gtk.Image
                pixelSize={18}
                $={(self: Gtk.Image) => {
                    const update = () => {
                        self.iconName = getIconName(volume.get(), muted.get())
                    }
                    update()
                    volume.subscribe(update)
                    muted.subscribe(update)
                }}
            />
            <box cssName="slider-container" hexpand>
                <Gtk.Scale
                    cssName="audio-slider"
                    hexpand
                    drawValue={false}
                    $={(self: Gtk.Scale) => {
                        // Create adjustment with initial volume value
                        const adjustment = new Gtk.Adjustment({
                            lower: 0,
                            upper: 1.0,
                            step_increment: 0.01,
                            page_increment: 0.1,
                            value: speaker.volume,
                        })

                        self.adjustment = adjustment

                        // Subscribe to volume changes to update slider
                        let isUpdating = false
                        volume.subscribe(() => {
                            if (!isUpdating && self.adjustment) {
                                isUpdating = true
                                self.adjustment.value = volume.get()
                                isUpdating = false
                            }
                        })

                        // Handle slider changes to update volume
                        self.connect("value-changed", () => {
                            if (!isUpdating && self.adjustment) {
                                isUpdating = true
                                speaker.volume = self.adjustment.value
                                isUpdating = false
                            }
                        })
                    }}
                />
            </box>
            <label
                cssName="slider-value"
                label={volume((v) => `${Math.round(v * 100)}%`)}
            />
        </box>
    )
}

// Tile on the main page that navigates to a subpage
function NavTile({ icon, name, description, active, onClicked }: {
    icon: any,
    name: string,
    description: any,
    active: any,
    onClicked: () => void,
}) {
    return (
        <button
            cssName="toggle-button"
            class={active((a: boolean) => a ? "active" : "")}
            onClicked={onClicked}
            hexpand
        >
            <box spacing={12}>
                <Gtk.Image iconName={icon} pixelSize={20} />
                <box orientation={Gtk.Orientation.VERTICAL} spacing={2} valign={Gtk.Align.CENTER} halign={Gtk.Align.START}>
                    <label cssName="toggle-name" label={name} halign={Gtk.Align.START} />
                    <label
                        cssName="toggle-description"
                        label={description((s: string) => s.slice(0, 15) + (s.length > 15 ? "..." : ""))}
                        halign={Gtk.Align.START}
                    />
                </box>
                <box hexpand />
                <Gtk.Image iconName="go-next-symbolic" pixelSize={14} valign={Gtk.Align.CENTER} />
            </box>
        </button>
    )
}

// Header used at the top of subpages: back button + title + extra widgets
function PageHeader({ title, onBack, children }: { title: string, onBack: () => void, children?: any }) {
    return (
        <box cssName="page-header" spacing={8}>
            <button cssName="header-button" onClicked={onBack} tooltipText="Back">
                <Gtk.Image iconName="go-previous-symbolic" pixelSize={16} />
            </button>
            <label cssName="page-title" label={title} halign={Gtk.Align.START} hexpand />
            {children}
        </box>
    )
}

// WiFi page: enable switch, refresh, access point list with inline password prompt
function WifiPage({ nav }: { nav: () => Adw.NavigationView }) {
    const network = Network.get_default()
    const wifi = network?.wifi

    if (!wifi) {
        return (
            <Adw.NavigationPage tag="wifi" title="Wi-Fi">
                <box orientation={Gtk.Orientation.VERTICAL}>
                    <PageHeader title="Wi-Fi" onBack={() => nav().pop()} />
                    <label label="No Wi-Fi adapter found" />
                </box>
            </Adw.NavigationPage>
        )
    }

    const enabled = createBinding(wifi, "enabled")
    const scanning = createBinding(wifi, "scanning")
    const activeAP = createBinding(wifi, "activeAccessPoint")
    const accessPoints = createBinding(wifi, "accessPoints")

    // Password prompt state: which AP is expanded, and an optional error message
    const [prompt, setPrompt] = createState<{ bssid: string, error: string } | null>(null)
    const [connecting, setConnecting] = createState<string | null>(null)

    // Deduplicate by SSID (keep strongest), drop hidden networks, sort by strength
    const apList = accessPoints((aps: Network.AccessPoint[]) => {
        const bySsid = new Map<string, Network.AccessPoint>()
        for (const ap of aps) {
            const ssid = ap.ssid
            if (!ssid) continue
            const existing = bySsid.get(ssid)
            if (!existing || ap.strength > existing.strength) {
                bySsid.set(ssid, ap)
            }
        }
        return [...bySsid.values()].sort((a, b) => b.strength - a.strength)
    })

    const connect = async (ap: Network.AccessPoint, password: string | null) => {
        setConnecting(ap.bssid)
        setPrompt(null)
        try {
            await connectToAccessPoint(ap, password)
        } catch (e) {
            console.error("Failed to connect to", ap.ssid, e)
            // Wrong password (or other auth failure): show the prompt (again)
            setPrompt({
                bssid: ap.bssid,
                error: password !== null
                    ? "Incorrect password, try again"
                    : (ap.requiresPassword ? "Authentication failed" : "Failed to connect"),
            })
        } finally {
            setConnecting(null)
        }
    }

    const onRowClicked = (ap: Network.AccessPoint) => {
        if (connecting.get()) return
        if (activeAP.get()?.bssid === ap.bssid) return

        const currentPrompt = prompt.get()
        if (currentPrompt?.bssid === ap.bssid) {
            setPrompt(null)
            return
        }

        // Saved connection or open network: connect directly, otherwise ask for a password
        if (ap.requiresPassword && ap.get_connections().length === 0) {
            setPrompt({ bssid: ap.bssid, error: "" })
        } else {
            connect(ap, null)
        }
    }

    return (
        <Adw.NavigationPage tag="wifi" title="Wi-Fi">
            <box cssName="subpage" orientation={Gtk.Orientation.VERTICAL} spacing={12}>
                <PageHeader title="Wi-Fi" onBack={() => nav().pop()}>
                    <button
                        cssName="header-button"
                        class={scanning((s: boolean) => s ? "spinning" : "")}
                        tooltipText="Scan for networks"
                        sensitive={scanning((s: boolean) => !s)}
                        onClicked={() => wifi.scan()}
                    >
                        <Gtk.Image iconName="view-refresh-symbolic" pixelSize={16} />
                    </button>
                    <Gtk.Switch
                        valign={Gtk.Align.CENTER}
                        active={enabled}
                        $={(self: Gtk.Switch) => {
                            self.connect("notify::active", () => {
                                if (self.active !== wifi.enabled) {
                                    wifi.set_enabled(self.active)
                                }
                            })
                        }}
                    />
                </PageHeader>

                <Gtk.ScrolledWindow
                    cssName="wifi-list-scroll"
                    hscrollbarPolicy={Gtk.PolicyType.NEVER}
                    vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
                    propagateNaturalHeight
                    maxContentHeight={400}
                    visible={enabled}
                >
                    <box cssName="wifi-list" orientation={Gtk.Orientation.VERTICAL} spacing={4}>
                        <For each={apList}>
                            {(ap: Network.AccessPoint) => {
                                const isActive = activeAP((a) => a?.bssid === ap.bssid)
                                const isConnecting = connecting((c) => c === ap.bssid)
                                const rowPrompt = prompt((p) => p?.bssid === ap.bssid ? p : null)

                                return (
                                    <box orientation={Gtk.Orientation.VERTICAL}>
                                        <button
                                            cssName="wifi-row"
                                            class={isActive((a) => a ? "active" : "")}
                                            onClicked={() => onRowClicked(ap)}
                                        >
                                            <box spacing={12}>
                                                <Gtk.Image iconName={createBinding(ap, "iconName")} pixelSize={16} />
                                                <label
                                                    cssName="wifi-ssid"
                                                    label={ap.ssid}
                                                    halign={Gtk.Align.START}
                                                    ellipsize={Pango.EllipsizeMode.END}
                                                    hexpand
                                                />
                                                <Gtk.Spinner spinning visible={isConnecting} />
                                                <Gtk.Image
                                                    iconName="network-wireless-encrypted-symbolic"
                                                    pixelSize={12}
                                                    cssName="wifi-lock"
                                                    visible={ap.requiresPassword}
                                                />
                                                <Gtk.Image
                                                    iconName="object-select-symbolic"
                                                    pixelSize={14}
                                                    visible={isActive}
                                                />
                                            </box>
                                        </button>
                                        <Gtk.Revealer
                                            revealChild={rowPrompt((p) => p !== null)}
                                            transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN}
                                        >
                                            <box cssName="wifi-password-box" orientation={Gtk.Orientation.VERTICAL} spacing={6}>
                                                <label
                                                    cssName="wifi-error"
                                                    label={rowPrompt((p) => p?.error ?? "")}
                                                    visible={rowPrompt((p) => !!p?.error)}
                                                    halign={Gtk.Align.START}
                                                />
                                                <box spacing={6}>
                                                    <Gtk.PasswordEntry
                                                        hexpand
                                                        showPeekIcon
                                                        placeholderText="Password"
                                                        $={(self: Gtk.PasswordEntry) => {
                                                            self.connect("activate", () => {
                                                                if (self.text) connect(ap, self.text)
                                                            })
                                                            // Focus and clear whenever the prompt (re)opens
                                                            rowPrompt.subscribe(() => {
                                                                if (rowPrompt.get() !== null) {
                                                                    self.text = ""
                                                                    self.grab_focus()
                                                                }
                                                            })
                                                        }}
                                                    />
                                                    <button
                                                        cssName="wifi-connect-button"
                                                        label="Connect"
                                                        $={(self: Gtk.Button) => {
                                                            self.connect("clicked", () => {
                                                                const entry = self.get_prev_sibling() as Gtk.PasswordEntry
                                                                if (entry?.text) connect(ap, entry.text)
                                                            })
                                                        }}
                                                    />
                                                </box>
                                            </box>
                                        </Gtk.Revealer>
                                    </box>
                                )
                            }}
                        </For>
                    </box>
                </Gtk.ScrolledWindow>

                <label
                    cssName="wifi-disabled-label"
                    label="Wi-Fi is turned off"
                    visible={enabled((e: boolean) => !e)}
                />
            </box>
        </Adw.NavigationPage>
    )
}

// Proxy page: enable switch + host/port entries for each protocol + save
function ProxyPage({ nav }: { nav: () => Adw.NavigationView }) {
    const protocols: ProxyProtocol[] = ["http", "https", "ftp", "socks"]
    const entries: Partial<Record<ProxyProtocol, { host: Gtk.Entry, port: Gtk.Entry }>> = {}
    const [saved, setSaved] = createState(false)

    const loadConfig = () => {
        const config = getProxyConfig()
        for (const proto of protocols) {
            const e = entries[proto]
            if (!e) continue
            e.host.text = config[proto].host
            e.port.text = config[proto].port > 0 ? String(config[proto].port) : ""
        }
    }

    const save = () => {
        const config = {} as ProxyConfig
        for (const proto of protocols) {
            const e = entries[proto]!
            config[proto] = {
                host: e.host.text.trim(),
                port: parseInt(e.port.text, 10) || 0,
            }
        }
        setProxyConfig(config)
        refreshProxyState()
        setSaved(true)
        setTimeout(() => setSaved(false), 2000)
    }

    // Reload entry contents every time the popup opens
    controlCenterVisible.subscribe(() => {
        if (controlCenterVisible.get()) loadConfig()
    })

    return (
        <Adw.NavigationPage tag="proxy" title="Proxy">
            <box cssName="subpage" orientation={Gtk.Orientation.VERTICAL} spacing={12}>
                <PageHeader title="Proxy" onBack={() => nav().pop()}>
                    <Gtk.Switch
                        valign={Gtk.Align.CENTER}
                        active={proxyEnabled}
                        $={(self: Gtk.Switch) => {
                            self.connect("notify::active", () => {
                                const mode = self.active ? "manual" : "none"
                                if (getProxyMode() !== mode) {
                                    setProxyMode(mode)
                                    refreshProxyState()
                                }
                            })
                        }}
                    />
                </PageHeader>

                <box cssName="proxy-form" orientation={Gtk.Orientation.VERTICAL} spacing={8}>
                    {protocols.map((proto) => (
                        <box cssName="proxy-row" spacing={8}>
                            <label
                                cssName="proxy-protocol"
                                label={proto.toUpperCase()}
                                halign={Gtk.Align.START}
                                widthChars={6}
                                xalign={0}
                            />
                            <Gtk.Entry
                                cssName="proxy-entry"
                                hexpand
                                widthChars={8}
                                placeholderText="Address"
                                $={(self: Gtk.Entry) => {
                                    entries[proto] = { ...(entries[proto] ?? {}), host: self } as any
                                }}
                            />
                            <Gtk.Entry
                                cssName="proxy-entry"
                                class="proxy-port"
                                placeholderText="Port"
                                maxLength={5}
                                widthChars={5}
                                maxWidthChars={5}
                                inputPurpose={Gtk.InputPurpose.DIGITS}
                                $={(self: Gtk.Entry) => {
                                    entries[proto] = { ...(entries[proto] ?? {}), port: self } as any
                                }}
                            />
                        </box>
                    ))}
                </box>

                <button
                    cssName="proxy-save-button"
                    onClicked={save}
                    halign={Gtk.Align.END}
                >
                    <label label={saved((s) => s ? "Saved ✓" : "Save")} />
                </button>
            </box>
        </Adw.NavigationPage>
    )
}

// Power profiles page: same three modes as GNOME
const POWER_PROFILES: { id: PowerProfile, name: string, description: string, icon: string }[] = [
    {
        id: "performance",
        name: "Performance",
        description: "High performance and power usage",
        icon: "power-profile-performance-symbolic",
    },
    {
        id: "balanced",
        name: "Balanced",
        description: "Standard performance and power usage",
        icon: "power-profile-balanced-symbolic",
    },
    {
        id: "power-saver",
        name: "Power Saver",
        description: "Reduced performance and power usage",
        icon: "power-profile-power-saver-symbolic",
    },
]

export function powerProfileName(profile: PowerProfile): string {
    return POWER_PROFILES.find((p) => p.id === profile)?.name ?? profile
}

function PowerProfilePage({ nav }: { nav: () => Adw.NavigationView }) {
    return (
        <Adw.NavigationPage tag="power" title="Power Mode">
            <box cssName="subpage" orientation={Gtk.Orientation.VERTICAL} spacing={12}>
                <PageHeader title="Power Mode" onBack={() => nav().pop()} />
                <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
                    {POWER_PROFILES.map((profile) => {
                        const isActive = activePowerProfile((p) => p === profile.id)
                        return (
                            <button
                                cssName="wifi-row"
                                class={isActive((a) => a ? "active" : "")}
                                onClicked={() => setPowerProfile(profile.id)}
                            >
                                <box spacing={12}>
                                    <Gtk.Image iconName={profile.icon} pixelSize={18} />
                                    <box orientation={Gtk.Orientation.VERTICAL} spacing={2} valign={Gtk.Align.CENTER} halign={Gtk.Align.START} hexpand>
                                        <label cssName="toggle-name" label={profile.name} halign={Gtk.Align.START} />
                                        <label cssName="toggle-description" label={profile.description} halign={Gtk.Align.START} />
                                    </box>
                                    <Gtk.Image
                                        iconName="object-select-symbolic"
                                        pixelSize={14}
                                        visible={isActive}
                                    />
                                </box>
                            </button>
                        )
                    })}
                </box>
            </box>
        </Adw.NavigationPage>
    )
}

// Main page tiles for wifi/proxy
function MainPage({ nav }: { nav: () => Adw.NavigationView }) {
    const network = Network.get_default()
    const wifi = network?.wifi

    const wifiActive = wifi
        ? createBinding(wifi, "state")((s: Network.DeviceState) => s === Network.DeviceState.ACTIVATED)
        : createState(false)[0]
    const wifiDescription = wifi
        ? createBinding(wifi, "activeAccessPoint")((ap) => ap?.ssid || "Disconnected")
        : createState("Unavailable")[0]

    return (
        <Adw.NavigationPage tag="main" title="Control Center">
            <box
                cssName="control-center-content"
                orientation={Gtk.Orientation.VERTICAL}
                spacing={16}
            >
                <box cssName="profile-row" spacing={12}>
                    <UserProfile />
                    <PowerControls />
                </box>
                <box cssName="sliders-section" orientation={Gtk.Orientation.VERTICAL} spacing={8}>
                    <AudioSlider />
                    <BrightnessSlider />
                </box>
                <box cssName="toggle-buttons" orientation={Gtk.Orientation.VERTICAL} spacing={8}>
                    <box spacing={8}>
                        <NavTile
                            icon="network-wireless-symbolic"
                            name="Wi-Fi"
                            description={wifiDescription}
                            active={wifiActive}
                            onClicked={() => {
                                nav().push_by_tag("wifi")
                                wifi?.scan()
                            }}
                        />
                        <NavTile
                            icon="network-vpn-symbolic"
                            name="Proxy"
                            description={proxyAddress}
                            active={proxyEnabled}
                            onClicked={() => nav().push_by_tag("proxy")}
                        />
                    </box>
                    <box spacing={8}>
                        {powerProfilesAvailable ? (
                            <NavTile
                                icon={activePowerProfile((p) => POWER_PROFILES.find((x) => x.id === p)?.icon ?? "power-profile-balanced-symbolic")}
                                name="Power Mode"
                                description={activePowerProfile((p: PowerProfile) => powerProfileName(p))}
                                active={activePowerProfile((p) => p !== "balanced")}
                                onClicked={() => nav().push_by_tag("power")}
                            />
                        ) : (
                            <box hexpand />
                        )}
                        <MicTile nav={nav} />
                    </box>
                </box>
            </box>
        </Adw.NavigationPage>
    )
}

// Main control center popup
export default function ControlCenterPopup() {
    let navView: Adw.NavigationView
    const nav = () => navView

    // Reset to the main page and refresh proxy info whenever the popup opens
    controlCenterVisible.subscribe(() => {
        if (controlCenterVisible.get()) {
            refreshProxyState()
        } else {
            navView?.pop_to_tag("main")
        }
    })

    return (
        <window
            name="control-center"
            cssName="control-center"
            visible={controlCenterVisible}
            anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT | Astal.WindowAnchor.BOTTOM | Astal.WindowAnchor.LEFT}
            layer={Astal.Layer.OVERLAY}
            exclusivity={Astal.Exclusivity.NORMAL}
            keymode={Astal.Keymode.ON_DEMAND}
            application={app}
        >
            <Gtk.Overlay>
                {/* Full-screen backdrop: clicking anywhere outside the panel closes it */}
                <box
                    cssName="popup-backdrop"
                    hexpand
                    vexpand
                    $={(self: Gtk.Box) => {
                        const gesture = new Gtk.GestureClick()
                        gesture.connect("released", () => setControlCenterVisible(false))
                        self.add_controller(gesture)
                    }}
                />
                <box
                    $type="overlay"
                    cssName="control-center-overlay"
                    orientation={Gtk.Orientation.VERTICAL}
                    halign={Gtk.Align.END}
                    valign={Gtk.Align.START}
                >
                    <box cssName="control-center-frame" orientation={Gtk.Orientation.VERTICAL}>
                        <Adw.NavigationView
                            $={(self: Adw.NavigationView) => { navView = self }}
                        >
                            <MainPage nav={nav} />
                            <WifiPage nav={nav} />
                            <ProxyPage nav={nav} />
                            <PowerProfilePage nav={nav} />
                            <MicPage nav={nav} />
                        </Adw.NavigationView>
                    </box>
                </box>
            </Gtk.Overlay>
        </window>
    )
}
