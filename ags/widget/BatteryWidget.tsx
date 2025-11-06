import { createBinding } from "ags"
import { Gtk } from "ags/gtk4"
import Battery from "gi://AstalBattery"

export default function BatteryWidget() {
    const battery = Battery.get_default()
    const percentage = createBinding(battery, "percentage")
    const charging = createBinding(battery, "charging")
    const isPresent = createBinding(battery, "isPresent")

    const iconName = charging((ch) => {
        const p = percentage.get()
        if (ch) {
            if (p > 0.99) return "battery-full-charging-symbolic"
            if (p > 0.9) return "battery-level-100-charging-symbolic"
            if (p > 0.8) return "battery-level-80-charging-symbolic"
            if (p > 0.7) return "battery-level-70-charging-symbolic"
            if (p > 0.6) return "battery-level-60-charging-symbolic"
            if (p > 0.5) return "battery-level-50-charging-symbolic"
            if (p > 0.4) return "battery-level-40-charging-symbolic"
            if (p > 0.3) return "battery-level-30-charging-symbolic"
            if (p > 0.2) return "battery-level-20-charging-symbolic"
            if (p > 0.1) return "battery-level-10-charging-symbolic"
            return "battery-empty-charging-symbolic"
        }
        if (p > 0.99) return "battery-full-symbolic"
        if (p > 0.9) return "battery-level-100-symbolic"
        if (p > 0.8) return "battery-level-80-symbolic"
        if (p > 0.7) return "battery-level-70-symbolic"
        if (p > 0.6) return "battery-level-60-symbolic"
        if (p > 0.5) return "battery-level-50-symbolic"
        if (p > 0.4) return "battery-level-40-symbolic"
        if (p > 0.3) return "battery-level-30-symbolic"
        if (p > 0.2) return "battery-level-20-symbolic"
        if (p > 0.1) return "battery-level-10-symbolic"
        return "battery-caution-symbolic"
    })

    return (
        <box
            cssName="battery"
            visible={isPresent((v) => v)}
            spacing={4}
        >
            <Gtk.Image iconName={iconName} />
        </box>
    )
}