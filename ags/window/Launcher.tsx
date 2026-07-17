import { createState, For } from "ags"
import app from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"
import Gdk from "gi://Gdk"
import { launcherVisible, hideLauncher } from "../lib/launcher"
import { getAppsByQuery, getAppIcon } from "../lib/apps"
import { evaluateMathExpression } from "../lib/math"
import { execAsync } from "ags/process"
import { ai } from "../lib/ai"
import { ReactiveMarkdown } from "../lib/markdown"
import GLib from "gi://GLib"


export default function Launcher() {
    const [query, setQuery] = createState("")
    const [selectedIndex, setSelectedIndex] = createState(0)

    let entry: Gtk.Entry | null = null

    const [aiResponse, setAiResponse] = createState("")
    const [isThinking, setIsThinking] = createState(false)
    const [filteredApps, setFilteredApps] = createState<any[]>(getAppsByQuery(""))

    const [showThinking, setShowThinking] = createState(false)
    const [showResponse, setShowResponse] = createState(false)
    const [showList, setShowList] = createState(true)

    let searchTimeout: number | null = null

    function updateState() {
        const text = query.get()
        const thinking = isThinking.get()
        const response = aiResponse.get()

        // Update visibility
        setShowThinking(thinking)
        setShowResponse(!thinking && !!response)
        setShowList(!thinking && !response)

        // Update apps if list is shown
        if (!thinking && !response) {
            const apps = getAppsByQuery(text)
            const result = evaluateMathExpression(text)

            let list = apps
            if (result !== null) {
                const expression = text.trim()
                const resultApp: any = {
                    name: expression,
                    iconName: "org.gnome.Calculator",
                    launch: () => {
                        execAsync(["gnome-calculator", "--equation=" + expression])
                    },
                    get_description: () => {
                        return `= ${String(result)}`
                    }
                }
                list = [resultApp, ...apps]
            }
            setFilteredApps(list)
        }
    }

    query.subscribe(() => {
        const text = query.get()
        if (searchTimeout) {
            GLib.source_remove(searchTimeout)
            searchTimeout = null
        }

        if (text.length < 10) {
            setAiResponse("")
            setIsThinking(false)
        }

        updateState()

        if (text.length > 10 && text.includes(" ")) {
            searchTimeout = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1500, () => {
                searchTimeout = null
                setIsThinking(true)
                updateState()
                ai.query(text).then(resp => {
                    setAiResponse(resp)
                    setIsThinking(false)
                    updateState()
                })
                return GLib.SOURCE_REMOVE
            })
        }
    })

    aiResponse.subscribe(updateState)
    isThinking.subscribe(updateState)

    launcherVisible.subscribe(() => {
        if (launcherVisible.get()) {
            setQuery("")
            setSelectedIndex(0)
            setAiResponse("")
            setIsThinking(false)
            updateState()
            if (entry) {
                entry.grab_focus()
                entry.set_position(-1)
            }
        }
    })

    function launchSelected() {
        if (showResponse.get()) {
            execAsync(["wl-copy", aiResponse.get()])
            hideLauncher()
            return
        }

        if (showThinking.get()) return

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
            if (showList.get()) {
                const apps = filteredApps.get()
                if (!apps.length) return false
                setSelectedIndex((i) => (i + 1) % apps.length)
                return false
            }
        }

        if (keyval === Gdk.KEY_Up) {
            if (showList.get()) {
                const apps = filteredApps.get()
                if (!apps.length) return false
                setSelectedIndex((i) => (i - 1 + apps.length) % apps.length)
                return false
            }
        }

        return false
    }

    function onRowActivate(app: any) {
        if (app && app.launch) {
            app.launch()
        }
        hideLauncher()
    }

    function AppRow({ app, index }: { app: any; index: any }) {
        const iconName = getAppIcon(app) ?? app.get_icon_name?.() ?? "application-x-executable-symbolic"
        const name = app.get_name?.() ?? app.name ?? "Unknown"
        const description = app.get_description?.() ?? ""

        return (
            <button
                cssName="launcher-row"
                $={(self) => {
                    const updateSelected = () => {
                        const selected = selectedIndex.get() === index.get()
                        if (selected) {
                            self.add_css_class("selected")
                        } else {
                            self.remove_css_class("selected")
                        }
                    }
                    selectedIndex.subscribe(updateSelected)
                    index.subscribe(updateSelected)
                    updateSelected()
                }}
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
            namespace="hypaurora-launcher"
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
                                setSelectedIndex(0)
                            })
                        }}
                    />

                    <box orientation={Gtk.Orientation.VERTICAL} hexpand vexpand>
                        <box
                            cssName="ai-thinking-container"
                            halign={Gtk.Align.CENTER}
                            valign={Gtk.Align.CENTER}
                            orientation={Gtk.Orientation.VERTICAL}
                            spacing={16}
                            heightRequest={460}
                            visible={showThinking}
                        >
                            <Gtk.Spinner spinning={true} widthRequest={32} heightRequest={32} vexpand />
                        </box>

                        <Gtk.ScrolledWindow
                            cssName="ai-response-scroller"
                            hexpand
                            vexpand
                            heightRequest={460}
                            visible={showResponse}
                        >
                            <box
                                cssName="ai-response-container"
                                orientation={Gtk.Orientation.VERTICAL}
                                spacing={12}
                                css="margin: 16px;"
                            >
                                <label
                                    label="AI Response"
                                    cssName="ai-response-header"
                                    xalign={0}
                                />
                                <ReactiveMarkdown content={aiResponse} />
                                <label
                                    label="Press Enter to copy"
                                    cssName="ai-response-hint"
                                    xalign={1}
                                    opacity={0.6}
                                />
                            </box>
                        </Gtk.ScrolledWindow>

                        <Gtk.ScrolledWindow
                            cssName="launcher-scroller"
                            hexpand
                            vexpand
                            heightRequest={460}
                            visible={showList}
                        >
                            <box orientation={Gtk.Orientation.VERTICAL} cssName="launcher-list" spacing={4}>
                                <For each={filteredApps}>
                                    {(app, index) => (
                                        <AppRow app={app} index={index} />
                                    )}
                                </For>
                            </box>
                        </Gtk.ScrolledWindow>
                    </box>
                </box>
            </box>
        </window>
    )
}
