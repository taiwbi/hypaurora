import { createBinding, createState } from "ags"
import { Gtk } from "ags/gtk4"
import Mpris from "gi://AstalMpris"
import { With } from "ags"

function PlayerWidget({ player }: { player: Mpris.Player }) {
    const title = createBinding(player, "title")
    const playbackStatus = createBinding(player, "playbackStatus")
    const identity = createBinding(player, "identity")
    const busName = createBinding(player, "busName")

    const iconName = playbackStatus((status) =>
        status === Mpris.PlaybackStatus.PLAYING
            ? "folder-music-symbolic"
            : "media-playback-pause-symbolic",
    )

    const labelText = title((t) =>
        t || identity.get() || busName.get() || "No media"
    )

    return (
        <box spacing={8}>
            <Gtk.Image cssName="media-icon" iconName={iconName} />
            <label cssName="media-title" label={labelText} />
        </box>
    )
}

export default function MediaWidget() {
    const mpris = Mpris.get_default()
    const [currentPlayer, setCurrentPlayer] = createState<Mpris.Player | null>(null)
    const playerConns = new Map<Mpris.Player, number>()

    function isPlayerValid(player: Mpris.Player) {
        return player.canPause ||
            player.canGoNext ||
            player.canGoPrevious ||
            player.canPlay
    }

    function updateCurrent() {
        const playerList = mpris.players || []

        // Filter out invalid players
        const validPlayers = playerList.filter(p => isPlayerValid(p))

        // If no valid players, set current player to null
        if (validPlayers.length === 0) {
            setCurrentPlayer(null)
            return
        }

        // Keep the last playing player as current if all players stopped
        if (
            currentPlayer.get() &&
            !playerList.some((p) => p.playbackStatus === Mpris.PlaybackStatus.PLAYING) &&
            playerList.includes(currentPlayer.get() as Mpris.Player)
        ) {
            return
        }

        for (const [p, c] of playerConns.entries()) {
            if (!playerList.includes(p)) {
                try {
                    p.disconnect(c)
                } catch (e) { }
                playerConns.delete(p)
            }
        }

        const sorted = [...validPlayers].sort((a, b) => {
            const statusA = a.playbackStatus
            const statusB = b.playbackStatus

            if (statusA === Mpris.PlaybackStatus.PLAYING && statusB !== Mpris.PlaybackStatus.PLAYING) {
                return -1
            }
            if (statusB === Mpris.PlaybackStatus.PLAYING && statusA !== Mpris.PlaybackStatus.PLAYING) {
                return 1
            }
            return 0
        })

        setCurrentPlayer(sorted[0] || null)
    }

    function onPlayerAdded(_: any, player: Mpris.Player) {
        if (playerConns.has(player)) return

        const conn = player.connect("notify::playback-status", updateCurrent)
        playerConns.set(player, conn)
        updateCurrent()
    }

    // Set up listeners
    mpris.connect("player-added", onPlayerAdded)
    mpris.connect("player-closed", updateCurrent)

    // Initialize with existing players
    mpris.players.forEach((p) => onPlayerAdded(null, p))
    updateCurrent()

    return (
        <With value={currentPlayer}>
            {(player) => (
                <box cssName="media" visible={Boolean(player)} spacing={8}>
                    {player ? <PlayerWidget player={player} /> : null}
                </box>
            )}
        </With>
    )
}