import { createBinding } from "ags"
import { Gtk } from "ags/gtk4"
import Network from "gi://AstalNetwork"

export default function NetworkWidget() {
    const network = Network.get_default()
    const wifi = network?.wifi
    const wired = network?.wired

    if (!wifi && !wired) {
        return (
            <box cssName="network">
                <Gtk.Image pixelSize={14} iconName="network-wireless-disabled-symbolic" />
            </box>
        )
    }

    const wifiState = wifi ? createBinding(wifi, "state") : null
    const wiredState = wired ? createBinding(wired, "state") : null
    const wifiStrength = wifi ? createBinding(wifi, "strength") : null

    if (wiredState) {
        const iconName = wiredState((state) =>
            state === Network.DeviceState.ACTIVATED
                ? "network-wired-symbolic"
                : "network-wired-disconnected-symbolic"
        )

        return (
            <box cssName="network">
                <Gtk.Image pixelSize={14} iconName={iconName} />
            </box>
        )
    }

    if (wifiState) {
        const iconName = wifiState((state) => {
            if (state === Network.DeviceState.ACTIVATED) {
                const strength = wifiStrength?.get() || 100
                return strength > 75
                    ? "network-wireless-signal-excellent-symbolic"
                    : strength > 50
                        ? "network-wireless-signal-good-symbolic"
                        : strength > 25
                            ? "network-wireless-signal-ok-symbolic"
                            : "network-wireless-signal-weak-symbolic"
            }
            return "network-wireless-offline-symbolic"
        })

        return (
            <box cssName="network">
                <Gtk.Image pixelSize={14} iconName={iconName} />
            </box>
        )
    }

    return (
        <box cssName="network">
            <Gtk.Image pixelSize={14} iconName="network-wireless-disabled-symbolic" />
        </box>
    )
}
