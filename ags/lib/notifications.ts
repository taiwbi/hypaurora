import { createState } from "ags"
import Notifd from "gi://AstalNotifd"

type AstalNotification = Exclude<Notifd.Notification, null | undefined>

export interface NotificationAction {
    id: string
    label: string
}

export interface NotificationItem {
    id: number
    summary: string
    body: string
    iconName: string
    appName: string
    actions: NotificationAction[]
    time: number
    notification: AstalNotification
    closing?: boolean
}

const notifd = Notifd.get_default()

export const [notifications, setNotifications] = createState<NotificationItem[]>([])

// Notifications that timed out on screen without any user interaction.
// Manually closed or action-handled notifications never end up here.
export const [notificationHistory, setNotificationHistory] = createState<NotificationItem[]>([])

const autoDismissTimers = new Map<number, ReturnType<typeof setTimeout>>()
const closeAnimationTimers = new Map<number, ReturnType<typeof setTimeout>>()

function parseActions(actions: Notifd.Action[] | null | undefined): NotificationAction[] {
    if (!actions || actions.length === 0) return []

    const parsed: NotificationAction[] = []
    let action: Notifd.Action
    for (let i = 0; i < actions.length; i += 2) {
        action = actions[i]
        parsed.push({ id: action.id, label: action.label })
    }
    return parsed
}

function getIconName(appName: string, iconName: string | null): string {
    if (iconName) return iconName

    switch (appName) {
        case "Telegram Desktop":
            return "org.telegram.desktop"
        default:
            return "dialog-information-symbolic"
    }
}

function buildNotificationItem(notification: Notifd.Notification): NotificationItem | null {
    if (!notification) return null

    const id = Number(notification.get_id?.() ?? -1)
    if (id < 0) return null

    const summary = notification.get_summary?.() ?? "Notification"
    const body = notification.get_body?.() ?? ""
    const appName = notification.get_app_name?.() ?? ""
    const iconName = getIconName(appName, notification.get_app_icon?.())
    const actions = parseActions(notification.get_actions?.())
    const timeValue = notification.get_time?.()
    const time = typeof timeValue === "number" ? timeValue : Date.now()

    return {
        id,
        summary,
        body,
        iconName,
        appName,
        actions,
        time,
        notification,
    }
}

function clearAutoDismiss(id: number) {
    const timer = autoDismissTimers.get(id)
    if (timer) {
        clearTimeout(timer)
        autoDismissTimers.delete(id)
    }
}

const AUTO_HIDE_TIMEOUT = 20000

// After 20s without user interaction the toast is hidden and moved to history
// (the notification is NOT dismissed on the daemon, so actions keep working).
function scheduleAutoHide(id: number) {
    if (id < 0) return

    clearAutoDismiss(id)

    const timer = setTimeout(() => {
        autoDismissTimers.delete(id)
        archiveNotification(id)
    }, AUTO_HIDE_TIMEOUT)

    autoDismissTimers.set(id, timer)
}

function archiveNotification(id: number) {
    const entry = notifications.get().find((n) => n.id === id)
    if (!entry) return

    setNotificationHistory((existing) => [
        { ...entry, closing: false },
        ...existing.filter((e) => e.id !== id),
    ])
    removeNotification(id)
}

function upsertNotification(notification: Notifd.Notification) {
    const item = buildNotificationItem(notification)
    if (!item) return

    clearCloseAnimationTimer(item.id)

    setNotifications((existing) => {
        const rest = existing.filter((entry) => entry.id !== item.id)
        return [item, ...rest].sort((a, b) => b.time - a.time)
    })

    scheduleAutoHide(item.id)
}

function clearCloseAnimationTimer(id: number) {
    const timer = closeAnimationTimers.get(id)
    if (!timer) return
    clearTimeout(timer)
    closeAnimationTimers.delete(id)
}

function removeNotification(id: number) {
    clearAutoDismiss(id)
    clearCloseAnimationTimer(id)

    const exists = notifications.get().some((entry) => entry.id === id && !entry.closing)
    if (!exists) {
        setNotifications((existing) => existing.filter((entry) => entry.id !== id))
        return
    }

    setNotifications((existing) => existing.map((entry) => entry.id === id
        ? { ...entry, closing: true }
        : entry,
    ))

    const timer = setTimeout(() => {
        setNotifications((existing) => existing.filter((entry) => entry.id !== id))
        closeAnimationTimers.delete(id)
    }, 850)

    closeAnimationTimers.set(id, timer)
}

export function dismissNotification(id: number) {
    const entry = notifications.get().find((n) => n.id === id)
    entry?.notification?.dismiss?.()
}

export function invokeNotificationAction(id: number, actionId: string) {
    const entry = notifications.get().find((n) => n.id === id)
        ?? notificationHistory.get().find((n) => n.id === id)
    if (!entry) return

    try {
        entry.notification.invoke?.(actionId)
    } catch (_) {
        // noop
    }

    // The notification has been dealt with: drop it everywhere
    setNotificationHistory((existing) => existing.filter((e) => e.id !== id))
    try {
        entry.notification.dismiss?.()
    } catch (_) {
        // noop
    }
}

export function removeFromHistory(id: number) {
    const entry = notificationHistory.get().find((n) => n.id === id)
    setNotificationHistory((existing) => existing.filter((e) => e.id !== id))
    try {
        entry?.notification?.dismiss?.()
    } catch (_) {
        // noop
    }
}

export function clearHistory() {
    const entries = notificationHistory.get()
    setNotificationHistory([])
    for (const entry of entries) {
        try {
            entry.notification.dismiss?.()
        } catch (_) {
            // noop
        }
    }
}

notifd.connect("notified", (_: unknown, id: number) => {
    const notification = notifd.get_notification(id)
    if (!notification) return
    upsertNotification(notification)
})

notifd.connect("resolved", (_: unknown, id: number) => {
    removeNotification(id)
    setNotificationHistory((existing) => existing.filter((e) => e.id !== id))
})

const unresolved = notifd.get_notifications?.()
if (Array.isArray(unresolved)) {
    unresolved.forEach((notification: AstalNotification) => upsertNotification(notification))
}
