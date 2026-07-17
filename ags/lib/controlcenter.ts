import { createState } from "ags"
import { execAsync } from "ags/process"
import Gio from "gi://Gio"
import GLib from "gi://GLib"
import Network from "gi://AstalNetwork"

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

// Power profiles via power-profiles-daemon (net.hadess.PowerProfiles)
export type PowerProfile = "power-saver" | "balanced" | "performance"

export const [activePowerProfile, setActivePowerProfileState] = createState<PowerProfile>("balanced")

const PPD_NAME = "net.hadess.PowerProfiles"
const PPD_PATH = "/net/hadess/PowerProfiles"

let ppdProxy: Gio.DBusProxy | null = null
try {
    ppdProxy = Gio.DBusProxy.new_for_bus_sync(
        Gio.BusType.SYSTEM,
        Gio.DBusProxyFlags.NONE,
        null,
        PPD_NAME,
        PPD_PATH,
        PPD_NAME,
        null,
    )

    const active = ppdProxy.get_cached_property("ActiveProfile")
    if (active) setActivePowerProfileState(active.unpack() as PowerProfile)

    ppdProxy.connect("g-properties-changed", (_proxy: Gio.DBusProxy, changed: GLib.Variant) => {
        const value = changed.lookup_value("ActiveProfile", null)
        if (value) setActivePowerProfileState(value.unpack() as PowerProfile)
    })
} catch (e) {
    console.error("power-profiles-daemon not available:", e)
}

export const powerProfilesAvailable = ppdProxy !== null

export function setPowerProfile(profile: PowerProfile) {
    if (!ppdProxy) return
    try {
        ppdProxy.get_connection().call(
            PPD_NAME,
            PPD_PATH,
            "org.freedesktop.DBus.Properties",
            "Set",
            new GLib.Variant("(ssv)", [PPD_NAME, "ActiveProfile", GLib.Variant.new_string(profile)]),
            null,
            Gio.DBusCallFlags.NONE,
            -1,
            null,
            (conn: Gio.DBusConnection, res: Gio.AsyncResult) => {
                try {
                    conn.call_finish(res)
                } catch (e) {
                    console.error("Failed to set power profile:", e)
                }
            },
        )
    } catch (e) {
        console.error("Failed to set power profile:", e)
    }
}

// Screen brightness via brightnessctl (returns null when no backlight is available)
export async function getBrightness(): Promise<number | null> {
    try {
        const out = await execAsync(["brightnessctl", "-m", "info"])
        const parts = out.trim().split(",")
        const current = parseInt(parts[2], 10)
        const max = parseInt(parts[4], 10)
        if (!max || isNaN(current)) return null
        return current / max
    } catch (e) {
        return null
    }
}

export function setBrightness(percent: number) {
    const value = Math.max(0, Math.min(100, Math.round(percent * 100)))
    execAsync(["brightnessctl", "set", `${value}%`]).catch(console.error)
}

// WiFi: connect to an access point, optionally with a password.
// Rejects (e.g. wrong password / auth failure) so callers can re-prompt.
export function connectToAccessPoint(ap: Network.AccessPoint, password: string | null): Promise<void> {
    return new Promise((resolve, reject) => {
        ap.activate(password, (_source: unknown, res: Gio.AsyncResult) => {
            try {
                ap.activate_finish(res)
                resolve()
            } catch (e) {
                reject(e)
            }
        })
    })
}

// GSettings instances for proxy management
const proxySettings = new Gio.Settings({ schema: "org.gnome.system.proxy" })
const proxyHttpSettings = new Gio.Settings({ schema: "org.gnome.system.proxy.http" })
const proxyHttpsSettings = new Gio.Settings({ schema: "org.gnome.system.proxy.https" })
const proxyFtpSettings = new Gio.Settings({ schema: "org.gnome.system.proxy.ftp" })
const proxySocksSettings = new Gio.Settings({ schema: "org.gnome.system.proxy.socks" })

export type ProxyProtocol = "http" | "https" | "ftp" | "socks"

const proxyProtocolSettings: Record<ProxyProtocol, Gio.Settings> = {
    http: proxyHttpSettings,
    https: proxyHttpsSettings,
    ftp: proxyFtpSettings,
    socks: proxySocksSettings,
}

export type ProxyConfig = Record<ProxyProtocol, { host: string, port: number }>

export function getProxyConfig(): ProxyConfig {
    const config = {} as ProxyConfig
    for (const proto of Object.keys(proxyProtocolSettings) as ProxyProtocol[]) {
        try {
            const settings = proxyProtocolSettings[proto]
            config[proto] = {
                host: settings.get_string("host"),
                port: settings.get_int("port"),
            }
        } catch (e) {
            console.error(`Failed to get ${proto} proxy config:`, e)
            config[proto] = { host: "", port: 0 }
        }
    }
    return config
}

export function setProxyConfig(config: ProxyConfig) {
    for (const proto of Object.keys(proxyProtocolSettings) as ProxyProtocol[]) {
        try {
            const settings = proxyProtocolSettings[proto]
            settings.set_string("host", config[proto].host)
            settings.set_int("port", config[proto].port)
        } catch (e) {
            console.error(`Failed to set ${proto} proxy config:`, e)
        }
    }
    Gio.Settings.sync()
}

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
