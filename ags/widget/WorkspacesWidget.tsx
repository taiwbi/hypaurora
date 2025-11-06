import Hyprland from "gi://AstalHyprland"
import { createBinding } from "ags"
import { Gtk } from "ags/gtk4"

export default function WorkspacesWidget() {
    const hyprland = Hyprland.get_default()
    const focusedWorkspace = createBinding(hyprland, "focusedWorkspace")
    const clients = createBinding(hyprland, "clients")

    return (
        <box cssName="workspaces" spacing={8}>
            {Array.from({ length: 10 }, (_, i) => i + 1).map((id) => (
                <button
                    cssName="workspace"
                    $={(self: Gtk.Button) => {
                        focusedWorkspace.subscribe(() => {
                            const focused = focusedWorkspace.get()
                            if (focused?.id === id) {
                                self.add_css_class("focused")
                            } else {
                                self.remove_css_class("focused")
                            }
                        })
                        clients.subscribe(() => {
                            const allWorkspaces = Hyprland.get_default().get_workspaces()

                            for (const workspace of allWorkspaces) {
                                if (workspace.id === id) {
                                    if (workspace.clients.length > 0) {
                                        self.add_css_class("occupied")
                                    } else {
                                        self.remove_css_class("occupied")
                                    }
                                }
                            }
                        })
                    }}
                    onClicked={() => hyprland.dispatch("workspace", id.toString())}
                >
                    <box cssName="workspace-dot" />
                </button>
            ))}
        </box>
    )
}