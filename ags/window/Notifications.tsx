import { With } from "ags"
import app from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"
import {
    notifications,
    dismissNotification,
    invokeNotificationAction,
    type NotificationItem,
} from "../lib/notifications"

const animatedNotificationIds = new Set<number>()

function NotificationToast({ item, entering, closing }: {
    item: NotificationItem,
    entering: boolean,
    closing: boolean,
}) {
    const classes = [entering ? "entering" : "", closing ? "closing" : ""]
        .filter(Boolean)
        .join(" ")

    return (
        <box
            cssName="notification"
            class={classes}
            orientation={Gtk.Orientation.VERTICAL}
            spacing={6}
            hexpand
        >
            <box cssName="notification-main" spacing={12} hexpand>
                <Gtk.Image cssName="notification-icon" iconName={item.iconName} pixelSize={30} />
                <box cssName="notification-text" orientation={Gtk.Orientation.VERTICAL} spacing={2} hexpand>
                    <label cssName="notification-title" label={item.summary || "Notification"} xalign={0} />
                    {item.body && (
                        <label
                            cssName="notification-body"
                            label={item.body}
                            xalign={0}
                            wrap
                            ellipsize={3}
                            maxWidthChars={50}
                        />
                    )}
                    {item.appName && (
                        <label cssName="notification-app" label={item.appName} xalign={0} />
                    )}
                </box>
                <button
                    cssName="notification-close"
                    onClicked={() => dismissNotification(item.id)}
                    halign={Gtk.Align.END}
                    valign={Gtk.Align.START}
                >
                    <Gtk.Image iconName="window-close-symbolic" pixelSize={12} />
                </button>
            </box>
            {item.actions.length > 0 && (
                <box cssName="notification-actions" spacing={6} hexpand>
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

export default function Notifications() {
    const hasNotifications = notifications((list) => list.length > 0)

    return (
        <window
            name="notifications"
            cssName="notifications"
            visible={hasNotifications}
            anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT}
            layer={Astal.Layer.OVERLAY}
            exclusivity={Astal.Exclusivity.NORMAL}
            application={app}
            namespace="hypaurora-notifications"
        >
            <With value={notifications}>
                {(items) => {
                    const currentIds = new Set(items.map((item) => item.id))
                    for (const id of Array.from(animatedNotificationIds)) {
                        if (!currentIds.has(id)) {
                            animatedNotificationIds.delete(id)
                        }
                    }

                    return (
                        <box
                            cssName="notifications-container"
                            orientation={Gtk.Orientation.VERTICAL}
                            spacing={10}
                            halign={Gtk.Align.END}
                            valign={Gtk.Align.START}
                            hexpand
                            vexpand
                        >
                            {items.map((item) => {
                                const entering = !animatedNotificationIds.has(item.id)
                                if (entering) {
                                    animatedNotificationIds.add(item.id)
                                }
                                return (
                                    <NotificationToast
                                        item={item}
                                        entering={entering}
                                        closing={Boolean(item.closing)}
                                    />
                                )
                            })}
                        </box>
                    )
                }}
            </With>
        </window>
    )
}
