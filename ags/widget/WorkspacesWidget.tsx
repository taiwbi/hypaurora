import Hyprland from "gi://AstalHyprland"
import { createBinding } from "ags"
import { Gtk } from "ags/gtk4"
import { getSymbolicIcon, getAppIcon } from "../lib/apps"
import GLib from "gi://GLib"

export default function WorkspacesWidget() {
    const hyprland = Hyprland.get_default()
    const focusedWorkspace = createBinding(hyprland, "focusedWorkspace")
    const clients = createBinding(hyprland, "clients")
    const focusedClient = createBinding(hyprland, "focusedClient")

    return (
        <box cssName="workspaces" spacing={4}>
            {Array.from({ length: 10 }, (_, i) => i + 1).map((id) => (
                <button
                    cssName="workspace" valign={Gtk.Align.CENTER} heightRequest={15}
                    $={(self: Gtk.Button) => {
                        const updateFocused = () => {
                            const focused = focusedWorkspace.get()
                            if (focused?.id === id) {
                                self.add_css_class("focused")
                            } else {
                                self.remove_css_class("focused")
                            }
                        }
                        updateFocused()
                        focusedWorkspace.subscribe(updateFocused)

                        const updateOccupied = () => {
                            const allWorkspaces = Hyprland.get_default().get_workspaces()
                            const workspace = allWorkspaces.find(ws => ws.id === id)

                            if (workspace && workspace.clients.length > 0) {
                                self.add_css_class("occupied")
                            } else {
                                self.remove_css_class("occupied")
                            }
                        }
                        updateOccupied()
                        clients.subscribe(updateOccupied)
                        focusedWorkspace.subscribe(updateOccupied)

                        const updateVisibility = () => {
                            const allWorkspaces = Hyprland.get_default().get_workspaces()
                            const focused = focusedWorkspace.get()

                            // Find the highest workspace ID that is either occupied or focused
                            let maxVisibleId = 0

                            // Check focused workspace
                            if (focused) {
                                maxVisibleId = Math.max(maxVisibleId, focused.id)
                            }

                            // Check occupied workspaces
                            for (const ws of allWorkspaces) {
                                if (ws.clients.length > 0) {
                                    maxVisibleId = Math.max(maxVisibleId, ws.id)
                                }
                            }

                            // Show workspace if it's at or before the last occupied/focused workspace
                            if (id <= maxVisibleId) {
                                self.set_visible(true)
                            } else {
                                self.set_visible(false)
                            }
                        }
                        updateVisibility()
                        clients.subscribe(updateVisibility)
                        focusedWorkspace.subscribe(updateVisibility)
                    }}
                    onClicked={() => hyprland.dispatch("workspace", id.toString())}
                >
                    <box cssName="workspace-dot" spacing={4} valign={Gtk.Align.CENTER} halign={Gtk.Align.CENTER} widthRequest={10} heightRequest={10}
                        $={(workspaceDot: Gtk.Box) => {
                            let iconFrame: Gtk.Frame | null = null
                            let iconImage: Gtk.Image | null = null
                            let nameWidget: Gtk.Label | null = null
                            let updateTimeout: GLib.Source | null = null

                            const updateIcon = () => {
                                // Clear any pending timeout
                                if (updateTimeout) {
                                    clearTimeout(updateTimeout)
                                }

                                const focused = focusedWorkspace.get()
                                const client = focusedClient.get()

                                if (nameWidget) {
                                    workspaceDot.remove(nameWidget)
                                    nameWidget = null
                                }
                                if (iconFrame) {
                                    workspaceDot.remove(iconFrame)
                                    iconFrame = null
                                }

                                // Add new icon if this is the focused workspace and there's a focused client
                                if (focused?.id === id && client) {
                                    // Wait a bit for client to initialize if title/class is missing
                                    if (!client.initialTitle || !client.class) {
                                        updateTimeout = setTimeout(() => {
                                            updateIcon()
                                        }, 100)
                                        return
                                    }

                                    iconImage = new Gtk.Image({
                                        iconName: getSymbolicIcon(client.class) ?? getAppIcon(client.class) ??
                                            "application-x-executable-symbolic",
                                        valign: Gtk.Align.CENTER,
                                        pixelSize: 16,
                                    })
                                    iconImage.add_css_class("workspace-icon")
                                    iconFrame = new Gtk.Frame({
                                        valign: Gtk.Align.CENTER,
                                        child: iconImage
                                    })
                                    iconFrame.add_css_class("workspace-icon-frame")

                                    nameWidget = new Gtk.Label({
                                        label: ((t) =>
                                            Array.from(t).length > 10
                                                ? Array.from(t).slice(0, 10).join("") + "..."
                                                : t)(client.title || client.initialTitle || "Unknown"),
                                    })
                                    nameWidget.add_css_class("workspace-name")

                                    workspaceDot.append(iconFrame)
                                    workspaceDot.append(nameWidget)
                                }
                            }
                            // Subscribe to changes
                            focusedWorkspace.subscribe(updateIcon)
                            focusedClient.subscribe(updateIcon)
                            // Initial render
                            updateIcon()
                        }}
                    />
                </button>
            ))}
        </box>
    )
}
