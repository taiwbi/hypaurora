import { createBinding, createState } from "ags"
import app from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"
import Wp from "gi://AstalWp"
import Network from "gi://AstalNetwork"
import { controlCenterVisible, lockScreen, suspend, powerOff, getProxyMode, setProxyMode, getProxyAddress } from "../lib/controlcenter"

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
                icon="system-suspend"
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

// WiFi toggle button
function WiFiToggle() {
    const network = Network.get_default()
    const wifi = network?.wifi

    if (!wifi) {
        return <box />
    }

    const wifiState = createBinding(wifi, "state")
    const activeAP = createBinding(wifi, "activeAccessPoint")
    const [isLoading, setIsLoading] = createState(false)

    const isConnected = wifiState((state: Network.DeviceState) => state === Network.DeviceState.ACTIVATED)
    const ssid = activeAP((ap) => ap?.ssid || "Disconnected")

    const toggleWifi = async () => {
        if (isLoading.get()) return

        setIsLoading(true)
        try {
            wifi.set_enabled(!wifi.get_enabled())
        } catch (e) {
            console.error("Failed to toggle WiFi:", e)
        } finally {
            setIsLoading(false)
        }
    }

    return (
        <button
            cssName="toggle-button"
            class={isConnected((connected) => connected ? "active" : "")}
            sensitive={isLoading((loading) => !loading)}
            onClicked={toggleWifi}
            hexpand
        >
            <box spacing={12}>
                <Gtk.Image iconName="network-wireless-symbolic" pixelSize={20} />
                <box orientation={Gtk.Orientation.VERTICAL} spacing={2} valign={Gtk.Align.CENTER} halign={Gtk.Align.START}>
                    <label cssName="toggle-name" label="Wi-Fi" halign={Gtk.Align.START} />
                    <label
                        cssName="toggle-description"
                        label={ssid((s) => s.slice(0, 15) + (s.length > 15 ? "..." : ""))}
                        halign={Gtk.Align.START}
                    />
                </box>
                <box hexpand />
            </box>
        </button>
    )
}

// Proxy toggle button
function ProxyToggle() {
    const [proxyEnabled, setProxyEnabled] = createState(false)
    const [proxyAddress, setProxyAddress] = createState("Not configured")
    const [isLoading, setIsLoading] = createState(false)

    // Initialize proxy state
    const updateProxyState = async () => {
        const mode = await getProxyMode()
        setProxyEnabled(mode === "manual")

        if (mode === "manual") {
            const address = await getProxyAddress()
            setProxyAddress(address)
        } else {
            setProxyAddress("Not configured")
        }
    }

    updateProxyState()

    const toggleProxy = async () => {
        if (isLoading.get()) return

        setIsLoading(true)
        try {
            const currentMode = await getProxyMode()
            const newMode = currentMode === "manual" ? "none" : "manual"
            await setProxyMode(newMode)
            await updateProxyState()
        } catch (e) {
            console.error("Failed to toggle proxy:", e)
        } finally {
            setIsLoading(false)
        }
    }

    return (
        <button
            cssName="toggle-button"
            class={proxyEnabled((enabled) => enabled ? "active" : "")}
            sensitive={isLoading((loading) => !loading)}
            onClicked={toggleProxy}
            hexpand
        >
            <box spacing={12}>
                <Gtk.Image iconName="network-vpn-symbolic" pixelSize={20} />
                <box orientation={Gtk.Orientation.VERTICAL} spacing={2} valign={Gtk.Align.CENTER} halign={Gtk.Align.START}>
                    <label cssName="toggle-name" label="Proxy" halign={Gtk.Align.START} />
                    <label
                        cssName="toggle-description"
                        label={proxyAddress((address) => address.slice(0, 15) + (address.length > 15 ? "..." : ""))}
                        halign={Gtk.Align.START}
                    />
                </box>
                <box hexpand />
            </box>
        </button>
    )
}

// Main control center popup
export default function ControlCenterPopup() {
    return (
        <window
            name="control-center"
            cssName="control-center"
            visible={controlCenterVisible}
            anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT}
            layer={Astal.Layer.OVERLAY}
            exclusivity={Astal.Exclusivity.NORMAL}
            keymode={Astal.Keymode.NONE}
            application={app}
        >
            <box cssName="control-center-overlay" orientation={Gtk.Orientation.VERTICAL}>
                <box
                    cssName="control-center-content"
                    orientation={Gtk.Orientation.VERTICAL}
                    spacing={16}
                >
                    <PowerControls />
                    <box cssName="sliders-section" orientation={Gtk.Orientation.VERTICAL} spacing={8}>
                        <AudioSlider />
                    </box>
                    <box cssName="toggle-buttons" orientation={Gtk.Orientation.VERTICAL} spacing={8}>
                        <box spacing={8}>
                            <WiFiToggle />
                            <ProxyToggle />
                        </box>
                    </box>
                </box>
            </box>
        </window>
    )
}
