import { createState } from "ags"
import { execAsync } from "ags/process"
import Gio from "gi://Gio"

export const [controlCenterVisible, setControlCenterVisible] = createState(false)

export function toggleControlCenter() {
    setControlCenterVisible(!controlCenterVisible.get())
}

// Power control functions
export function lockScreen() {
    // TODO: Make this relative
    execAsync(["/home/mahdi/Documents/hypaurora/code/lock.sh"]).catch(console.error)
}

export function suspend() {
    // TODO: Make this relative
    execAsync(["/home/mahdi/Documents/hypaurora/code/suspend.sh"]).catch(console.error)
}

export function powerOff() {
    execAsync(["systemctl", "poweroff"]).catch(console.error)
}

// GSettings instances for proxy management
const proxySettings = new Gio.Settings({ schema: "org.gnome.system.proxy" })
const proxyHttpSettings = new Gio.Settings({ schema: "org.gnome.system.proxy.http" })
const proxySocksSettings = new Gio.Settings({ schema: "org.gnome.system.proxy.socks" })

// Proxy management using GLib GSettings API
export function getProxyMode(): string {
    try {
        return proxySettings.get_string("mode")
    } catch (e) {
        console.error("Failed to get proxy mode:", e)
        return "none"
    }
}

export function setProxyMode(mode: "manual" | "none") {
    try {
        proxySettings.set_string("mode", mode)
    } catch (e) {
        console.error("Failed to set proxy mode:", e)
    }
}

export function getProxyAddress(): string {
    try {
        // Try to get HTTP proxy first
        const host = proxyHttpSettings.get_string("host")
        const port = proxyHttpSettings.get_int("port")

        if (host && host !== "") {
            return `${host}:${port}`
        }

        // Fallback to SOCKS
        const socksHost = proxySocksSettings.get_string("host")
        const socksPort = proxySocksSettings.get_int("port")

        if (socksHost && socksHost !== "") {
            return `${socksHost}:${socksPort}`
        }

        return "Not configured"
    } catch (e) {
        console.error("Failed to get proxy address:", e)
        return "Not configured"
    }
}
