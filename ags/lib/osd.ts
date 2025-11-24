import { createState } from "ags"
import GLib from "gi://GLib?version=2.0"

export type OsdKind = "volume" | "brightness" | "keyboard-layout" | "keyboard-brightness" | "touchpad"

export const [osdVisible, setOsdVisible] = createState(false)
export const [osdKind, setOsdKind] = createState<OsdKind | null>(null)
export const [osdTitle, setOsdTitle] = createState("")
export const [osdLabel, setOsdLabel] = createState("")
export const [osdIcon, setOsdIcon] = createState("")
export const [osdValue, setOsdValue] = createState(0)
export const [osdShowSlider, setOsdShowSlider] = createState(true)

let hideTimeout: GLib.Source | null = null

function show(kind: OsdKind, title: string, label: string, iconName: string, value: number = 0, showSlider: boolean = true) {
    setOsdKind(kind)
    setOsdTitle(title)
    setOsdLabel(label)
    setOsdIcon(iconName)
    setOsdValue(value)
    setOsdShowSlider(showSlider)
    setOsdVisible(true)

    if (hideTimeout) {
        clearTimeout(hideTimeout)
    }

    hideTimeout = setTimeout(() => {
        setOsdVisible(false)
    }, 3000)
}

export function showVolume(level: number, muted: boolean) {
    const value = Math.max(0, Math.min(1, level ?? 0))
    const percentage = Math.round(value * 100)

    let iconName: string
    if (muted || value <= 0) iconName = "audio-volume-muted-symbolic"
    else if (value > 1.0) iconName = "audio-volume-overamplified-symbolic"
    else if (value > 0.66) iconName = "audio-volume-high-symbolic"
    else if (value > 0.33) iconName = "audio-volume-medium-symbolic"
    else if (value > 0) iconName = "audio-volume-low-symbolic"
    else iconName = "audio-volume-muted-symbolic"

    const label = muted || value <= 0 ? "Muted" : `${percentage}%`
    show("volume", "Volume", label, iconName, percentage, !muted && value > 0)
}

export function showBrightness(level: number) {
    const value = Math.max(0, Math.min(1, level ?? 0))
    const percentage = Math.round(value * 100)
    const label = `${percentage}%`
    show("brightness", "Brightness", label, "display-brightness-symbolic", percentage, true)
}

export function showKeyboardLayout(layout: string) {
    const label = layout.toUpperCase()
    show("keyboard-layout", "Keyboard Layout", label, "preferences-desktop-keyboard-shortcuts-symbolic", 0, false)
}

export function showKeyboardBrightness(level: number) {
    const value = Math.max(0, Math.min(1, level ?? 0))
    const percentage = Math.round(value * 100)
    const label = `${percentage}%`
    show("keyboard-brightness", "Keyboard Brightness", label, "keyboard-brightness-symbolic", percentage, true)
}

export function showTouchpad(enabled: boolean) {
    const label = enabled ? "On" : "Off"
    const icon = enabled ? "input-touchpad-symbolic" : "touchpad-disabled-symbolic"
    show("touchpad", "Touchpad", label, icon, 0, false)
}

; (globalThis as any).Osd = {
    showVolume,
    showBrightness,
    showKeyboardLayout,
    showKeyboardBrightness,
    showTouchpad,
}