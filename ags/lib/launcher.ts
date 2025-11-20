// State and helpers for the application launcher window
import { createState } from "ags"

export const [launcherVisible, setLauncherVisible] = createState(false)

export function toggleLauncher() {
    setLauncherVisible((v) => !v)
}

export function showLauncher() {
    setLauncherVisible(true)
}

export function hideLauncher() {
    setLauncherVisible(false)
}

;(globalThis as any).Launcher = {
    toggleLauncher,
    showLauncher,
    hideLauncher,
}
