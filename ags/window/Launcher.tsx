import { createState, For } from "ags"
import app from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"
import Gdk from "gi://Gdk"
import { launcherVisible, hideLauncher } from "../lib/launcher"
import { getAppsByQuery, getAppIcon } from "../lib/apps"
import { evaluateMathExpression } from "../lib/math"
import { execAsync } from "ags/process"


export default function Launcher() {
    const [query, setQuery] = createState("")
    const [selectedIndex, setSelectedIndex] = createState(0)

    let entry: Gtk.Entry | null = null

    const filteredApps = query((text) => {
        const apps = getAppsByQuery(text)
        const result = evaluateMathExpression(text)
        if (result === null) {
            return apps
        }
        const expression = text.trim()
        const resultApp = {
            isCalculatorResult: true,
            name: String(result),
            description: "Enter to open in calculator",
            iconName: "org.gnome.Calculator",
            launch: () => {
                execAsync(["gnome-calculator", "--equation=" + expression])
            },
        }
        return [resultApp, ...apps]
    })

    launcherVisible.subscribe(() => {
        if (launcherVisible.get()) {
            setQuery("")
            setSelectedIndex(0)
            if (entry) {
                entry.grab_focus()
                entry.set_position(-1)
            }
        }
    })

    function launchSelected() {
        const apps = filteredApps.get()
        if (!apps.length) return
        const index = Math.max(0, Math.min(selectedIndex.get(), apps.length - 1))
        const app = apps[index]
        if (app && app.launch) {
            app.launch()
        }
        hideLauncher()
    }

    function onKeyPress(keyval: number) {

        if (keyval === Gdk.KEY_Escape) {
            hideLauncher()
            return true
        }

        if (keyval === Gdk.KEY_Return || keyval === Gdk.KEY_KP_Enter) {
            launchSelected()
            return true
        }

        if (keyval === Gdk.KEY_Down) {
            const apps = filteredApps.get()
            if (!apps.length) return false
            setSelectedIndex((i) => (i + 1) % apps.length)
            return false
        }

        if (keyval === Gdk.KEY_Up) {
            const apps = filteredApps.get()
            if (!apps.length) return false
            setSelectedIndex((i) => (i - 1 + apps.length) % apps.length)
            return false
        }

        return false
    }

    function onRowActivate(app: any) {
        if (app && app.launch) {
            app.launch()
        }
        hideLauncher()
    }

    function AppRow({ app, index }: { app: any; index: number }) {
        const isSelected = selectedIndex((i) => i === index)

        const iconName = getAppIcon(app) ?? app.get_icon_name?.() ?? "application-x-executable-symbolic"
        const name = app.get_name?.() ?? app.name ?? "Unknown"
        const description = app.get_description?.() ?? ""

        return (
            <button
                cssName="launcher-row"
                class={isSelected((sel) => (sel ? "selected" : ""))}
                hexpand
                onClicked={() => onRowActivate(app)}
            >
                <box spacing={12} hexpand>
                    <Gtk.Image
                        cssName="launcher-icon"
                        iconName={iconName}
                        pixelSize={32}
                    />
                    <box orientation={Gtk.Orientation.VERTICAL} spacing={2} hexpand>
                        <label
                            cssName="launcher-title"
                            label={name}
                            xalign={0}
                            ellipsize={3}
                        />
                        {description && (
                            <label
                                cssName="launcher-description"
                                label={description}
                                xalign={0}
                                ellipsize={3}
                                maxWidthChars={50}
                            />
                        )}
                    </box>
                </box>
            </button>
        )
    }

    return (
        <window
            name="launcher"
            cssName="launcher"
            visible={launcherVisible}
            anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.BOTTOM | Astal.WindowAnchor.LEFT | Astal.WindowAnchor.RIGHT}
            layer={Astal.Layer.OVERLAY}
            exclusivity={Astal.Exclusivity.NORMAL}
            keymode={Astal.Keymode.EXCLUSIVE}
            application={app}
        >
            <box
                cssName="launcher-overlay"
                halign={Gtk.Align.CENTER}
                valign={Gtk.Align.CENTER}
                hexpand
                vexpand
            >
                <Gtk.EventControllerKey
                    propagationPhase={Gtk.PropagationPhase.CAPTURE}
                    $={(ctrl: Gtk.EventControllerKey) => {
                        ctrl.connect("key-pressed", (_ctrl, keyval) => onKeyPress(keyval))
                    }}
                />
                <box
                    cssName="launcher-container"
                    orientation={Gtk.Orientation.VERTICAL}
                    spacing={8}
                    widthRequest={600}
                >
                    <Gtk.Entry
                        cssName="launcher-entry"
                        placeholderText="Search applications..."
                        text={query}
                        hexpand
                        focusOnClick
                        hasFrame={false}
                        $={(self: Gtk.Entry) => {
                            entry = self
                            self.connect("changed", () => {
                                setQuery(self.text ?? "")
                            })
                        }}
                    />
                    {/* <Gtk.Separator orientation={Gtk.Orientation.HORIZONTAL} /> */}
                    <Gtk.ScrolledWindow
                        cssName="launcher-scroller"
                        hexpand
                        vexpand
                        heightRequest={460}
                    >
                        <box orientation={Gtk.Orientation.VERTICAL} cssName="launcher-list" spacing={4}>
                            <For each={filteredApps}>
                                {(app, index) => (
                                    <AppRow app={app} index={index.get()} />
                                )}
                            </For>
                        </box>
                    </Gtk.ScrolledWindow>
                </box>
            </box>
        </window>
    )
}
