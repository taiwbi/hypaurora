import { createState, For } from "ags"
import app from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"
import { createPoll } from "ags/time"
import Pango from "gi://Pango"
import {
    notificationHistory,
    invokeNotificationAction,
    removeFromHistory,
    clearHistory,
    type NotificationItem,
} from "../lib/notifications"

export const [timePopupVisible, setTimePopupVisible] = createState(false)

export function toggleTimePopup() {
    setTimePopupVisible(!timePopupVisible.get())
}

function HistoryItem({ item }: { item: NotificationItem }) {
    return (
        <box
            cssName="history-item"
            orientation={Gtk.Orientation.VERTICAL}
            spacing={6}
            hexpand
        >
            <box spacing={12} hexpand>
                <Gtk.Image cssName="notification-icon" iconName={item.iconName} pixelSize={26} valign={Gtk.Align.START} />
                <box orientation={Gtk.Orientation.VERTICAL} spacing={2} hexpand>
                    <label cssName="notification-title" label={item.summary || "Notification"} xalign={0} ellipsize={Pango.EllipsizeMode.END} maxWidthChars={36} />
                    {item.body && (
                        <label
                            cssName="notification-body"
                            label={item.body}
                            xalign={0}
                            wrap
                            ellipsize={Pango.EllipsizeMode.END}
                            maxWidthChars={40}
                        />
                    )}
                    {item.appName && (
                        <label cssName="notification-app" label={item.appName} xalign={0} />
                    )}
                </box>
                <button
                    cssName="notification-close"
                    onClicked={() => removeFromHistory(item.id)}
                    halign={Gtk.Align.END}
                    valign={Gtk.Align.START}
                >
                    <Gtk.Image iconName="window-close-symbolic" pixelSize={12} />
                </button>
            </box>
            {item.actions.length > 0 && (
                <box spacing={6} hexpand>
                    {item.actions.map((action) => (
                        <button
                            class="notification-action"
                            hexpand
                            onClicked={() => invokeNotificationAction(item.id, action.id)}
                        >
                            <label label={action.label.toString() ?? ""} xalign={0.5} />
                        </button>
                    ))}
                </box>
            )}
        </box>
    )
}

export default function TimePopup() {
    const time = createPoll("", 1000, () => {
        return new Date().toLocaleTimeString("en-US", {
            hour: "2-digit",
            minute: "2-digit",
            second: "2-digit",
            hour12: false,
        })
    })

    const date = createPoll("", 1000, () => {
        return new Date().toLocaleDateString("en-US", {
            weekday: "long",
            month: "long",
            day: "numeric",
            year: "numeric",
        })
    })

    const hasHistory = notificationHistory((list) => list.length > 0)

    return (
        <window
            name="time-popup"
            cssName="time-popup"
            visible={timePopupVisible}
            anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT | Astal.WindowAnchor.BOTTOM | Astal.WindowAnchor.LEFT}
            layer={Astal.Layer.OVERLAY}
            exclusivity={Astal.Exclusivity.NORMAL}
            keymode={Astal.Keymode.NONE}
            application={app}
        >
            <Gtk.Overlay>
                {/* Full-screen backdrop: clicking anywhere outside the popup closes it */}
                <box
                    cssName="popup-backdrop"
                    hexpand
                    vexpand
                    $={(self: Gtk.Box) => {
                        const gesture = new Gtk.GestureClick()
                        gesture.connect("released", () => setTimePopupVisible(false))
                        self.add_controller(gesture)
                    }}
                />
                <box
                    $type="overlay"
                    cssName="time-popup-content"
                    orientation={Gtk.Orientation.VERTICAL}
                    spacing={16}
                    halign={Gtk.Align.CENTER}
                    valign={Gtk.Align.START}
                >
                    <box cssName="time-section" orientation={Gtk.Orientation.VERTICAL} spacing={4}>
                        <label cssName="time-big" label={time} halign={Gtk.Align.CENTER} />
                        <label cssName="date-line" label={date} halign={Gtk.Align.CENTER} />
                    </box>

                    <box cssName="history-header" spacing={8}>
                        <label cssName="section-title" label="Notifications" halign={Gtk.Align.START} hexpand />
                        <button
                            cssName="clear-button"
                            visible={hasHistory}
                            onClicked={clearHistory}
                        >
                            <box spacing={6}>
                                <Gtk.Image iconName="edit-clear-all-symbolic" pixelSize={14} />
                                <label label="Clear" />
                            </box>
                        </button>
                    </box>

                    <Gtk.ScrolledWindow
                        cssName="history-scroll"
                        hscrollbarPolicy={Gtk.PolicyType.NEVER}
                        vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
                        propagateNaturalHeight
                        maxContentHeight={420}
                        visible={hasHistory}
                    >
                        <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
                            <For each={notificationHistory}>
                                {(item: NotificationItem) => <HistoryItem item={item} />}
                            </For>
                        </box>
                    </Gtk.ScrolledWindow>

                    <label
                        cssName="history-empty"
                        label="No notifications"
                        visible={hasHistory((h) => !h)}
                    />
                </box>
            </Gtk.Overlay>
        </window>
    )
}
