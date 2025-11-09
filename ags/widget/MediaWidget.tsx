import { createBinding } from "ags"
import { Gtk } from "ags/gtk4"
import Mpris from "gi://AstalMpris"
import { With } from "ags"

function PlayerWidget({ player }: { player: any }) {
    const title = createBinding(player, "title")
    const playbackStatus = createBinding(player, "playbackStatus")

    const iconName = playbackStatus((status) =>
        status === Mpris.PlaybackStatus.PLAYING
            ? "folder-music-symbolic"
            : "media-playback-pause-symbolic",
    )

    return (
        <box spacing={8}>
            <Gtk.Image cssName="media-icon" iconName={iconName} />
            {title.get() && (
                <label cssName="media-title" label={title.get() ?? player.identity ?? ""} />
            )}
        </box>
    )
}

export default function MediaWidget() {
    const mpris = Mpris.get_default()
    const players = createBinding(mpris, "players")

    return (
        <With value={players}>
            {(playerList) => {
                const player = playerList?.[0]
                return (
                    <box cssName="media" visible={Boolean(player)} spacing={8}>
                        {player ? <PlayerWidget player={player} /> : null}
                    </box>
                )
            }}
        </With>
    )
}