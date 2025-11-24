import { Gtk } from "ags/gtk4"
import Gdk from "gi://Gdk"
import AstalApps from "gi://AstalApps";
import { fuzzyScore } from "./core"

const astalApps: AstalApps.Apps = new AstalApps.Apps();
let appsList: Array<AstalApps.Application> = astalApps.get_list();

/**
 * Returns the list of installed applications from the AstalApps list.
 * 
 * @returns The list of installed applications
 */
export function getApps(): Array<AstalApps.Application> {
    return appsList;
}

/**
 * Returns apps matching a given name (case-insensitive) from the installed AstalApps list.
 * 
 * @param appName The name of the application to look up (e.g., "firefox", "folder")
 * @returns The icon name for the application, or undefined if not found
 */
export function getAppsByName(appName: string): (Array<AstalApps.Application> | undefined) {
    let found: Array<AstalApps.Application> = [];

    getApps().map((app: AstalApps.Application) => {
        if (app.get_name().trim().toLowerCase() === appName.trim().toLowerCase()
            || (app?.wmClass && app.wmClass.trim().toLowerCase() === appName.trim().toLowerCase()))
            found.push(app);
    });

    return (found.length > 0 ? found : undefined);
}

/**
 * Returns apps fuzzy matching a given query (case-insensitive) from the installed AstalApps list.
 * 
 * @param query The query to look up (e.g., "firefox", "folder")
 * @returns The list of installed applications matching the query
 */
export function getAppsByQuery(query: string): (Array<AstalApps.Application>) {
    let allApps = getApps();
    const q = query.trim().toLowerCase()
    if (!q) return allApps

    return allApps
        .map((app) => {
            const name = app.get_name()?.toLowerCase?.() ?? ""
            const description = app.get_description?.()?.toLowerCase?.() ?? ""
            const entry = app.get_entry?.()?.toLowerCase?.() ?? ""
            const keywords = app.keywords ?? []

            const score = Math.max(
                fuzzyScore(name, q) * 3,
                fuzzyScore(description, q),
                fuzzyScore(entry, q),
                ...keywords.map((keyword) => fuzzyScore(keyword, q) * 0.7)
            )

            return { app, score }
        })
        .filter(({ score }) => score > 0)
        .sort((a, b) => b.score - a.score)
        .map(({ app }) => app)
}

/**
 * Checks for the existence of a named icon in the current display's icon theme.
 *
 * @param name The name of the icon to look up (e.g., "firefox", "folder")
 * @returns True if the icon exists, false otherwise
 */
export function lookupIcon(name: string): boolean {
    return Gtk.IconTheme.get_for_display(Gdk.Display.get_default()!)?.has_icon(name);
}

/**
 * Retrieves the icon name for a given application name.s
 *
 * @param appName The name of the application to look up (e.g., "firefox", "folder")
 * @returns The icon name for the application, or undefined if not found
 */
export function getIconByAppName(appName: string): (string | undefined) {
    if (!appName) return undefined;

    if (lookupIcon(appName))
        return appName;

    if (lookupIcon(appName.toLowerCase()))
        return appName.toLowerCase();

    const nameReverseDNS = appName.split('.');
    const lastItem = nameReverseDNS[nameReverseDNS.length - 1];
    const lastPretty = `${lastItem.charAt(0).toUpperCase()}${lastItem.substring(1, lastItem.length)}`; // Capitalizes the last segment

    const uppercaseRDNS = nameReverseDNS.slice(0, nameReverseDNS.length - 1)
        .concat(lastPretty).join('.');

    if (lookupIcon(uppercaseRDNS))
        return uppercaseRDNS;

    if (lookupIcon(nameReverseDNS[nameReverseDNS.length - 1]))
        return nameReverseDNS[nameReverseDNS.length - 1];

    const found: (AstalApps.Application | undefined) = getAppsByName(appName)?.[0];
    if (Boolean(found))
        return found?.iconName;

    return undefined;
}


/**
 * Retrieves the icon name for a given application.
 *
 * @param app The application to look up (e.g., "firefox", "folder")
 * @returns The icon name for the application, or undefined if not found
 */
export function getAppIcon(app: (string | AstalApps.Application)): (string | undefined) {
    if (!app) return undefined;

    if (typeof app === "string")
        return getIconByAppName(app);

    if (app.iconName && lookupIcon(app.iconName))
        return app.iconName;

    if (app.wmClass)
        return getIconByAppName(app.wmClass);

    return getIconByAppName(app.name);
}

/**
 * Retrieves the symbolic icon name for a given application.
 *
 * @param app The application to look up (e.g., "firefox", "folder")
 * @returns The symbolic icon name for the application, or undefined if not found
 */
export function getSymbolicIcon(app: (string | AstalApps.Application)): (string | undefined) {
    const icon = getAppIcon(app);

    return (icon && lookupIcon(`${icon}-symbolic`)) ?
        `${icon}-symbolic`
        : undefined;
}
