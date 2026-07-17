import { createBinding, createState, With } from "ags"
import app from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"
import Mpris from "gi://AstalMpris"

export const [mediaPopupVisible, setMediaPopupVisible] = createState(false)

function MediaControls({ player }: { player: Mpris.Player }) {
    const playbackStatus = createBinding(player, "playbackStatus")
    const loopStatus = createBinding(player, "loopStatus")
    const shuffleStatus = createBinding(player, "shuffleStatus")
    const canGoNext = createBinding(player, "canGoNext")
    const canGoPrevious = createBinding(player, "canGoPrevious")
    const canPlay = createBinding(player, "canPlay")
    const canPause = createBinding(player, "canPause")

    const playPauseIcon = playbackStatus((status) =>
        status === Mpris.PlaybackStatus.PLAYING
            ? "media-playback-pause-symbolic"
            : "media-playback-start-symbolic"
    )

    const loopIcon = loopStatus((status) => {
        switch (status) {
            case Mpris.Loop.TRACK:
                return "media-playlist-repeat-song-symbolic"
            case Mpris.Loop.PLAYLIST:
                return "media-playlist-repeat-symbolic"
            default:
                return "media-playlist-consecutive-symbolic"
        }
    })
    const shuffleIcon = "media-playlist-shuffle-symbolic"

    const shuffleActive = shuffleStatus((status) => status === Mpris.Shuffle.ON)
    const loopActive = loopStatus((status) => status !== Mpris.Loop.NONE && status !== Mpris.Loop.UNSUPPORTED)
    const shuffleSupported = shuffleStatus((status) => status !== Mpris.Shuffle.UNSUPPORTED)
    const loopSupported = loopStatus((status) => status !== Mpris.Loop.UNSUPPORTED)

    return (
        <box cssName="media-controls" spacing={8} halign={Gtk.Align.CENTER}>
            <button
                cssName="control-button"
                class={shuffleActive((active) => active ? "active" : "")}
                sensitive={shuffleSupported}
                onClicked={() => player.shuffle()}
            >
                <Gtk.Image iconName={shuffleIcon} />
            </button>
            <button
                cssName="control-button"
                sensitive={canGoPrevious}
                onClicked={() => player.previous()}
            >
                <Gtk.Image iconName="media-skip-backward-symbolic" />
            </button>
            <button
                cssName="control-button"
                class="play-pause"
                sensitive={playbackStatus((status) =>
                    status === Mpris.PlaybackStatus.PLAYING ? canPause.get() : canPlay.get()
                )}
                onClicked={() => player.play_pause()}
            >
                <Gtk.Image iconName={playPauseIcon} />
            </button>
            <button
                cssName="control-button"
                sensitive={canGoNext}
                onClicked={() => player.next()}
            >
                <Gtk.Image iconName="media-skip-forward-symbolic" />
            </button>
            <button
                cssName="control-button"
                class={loopActive((active) => active ? "active" : "")}
                sensitive={loopSupported}
                onClicked={() => player.loop()}
            >
                <Gtk.Image iconName={loopIcon} />
            </button>
        </box>
    )
}

function MediaInfo({ player }: { player: Mpris.Player }) {
    const title = createBinding(player, "title")
    const artist = createBinding(player, "artist")
    const artUrl = createBinding(player, "artUrl")
    const identity = createBinding(player, "identity")

    const displayTitle = title((t) => t || "Unknown Title")
    const displayArtist = artist((a) => a || identity.get() || "Unknown Artist")

    return (
        <box cssName="media-info" spacing={16} orientation={Gtk.Orientation.VERTICAL}>
            <box cssName="media-art-container" halign={Gtk.Align.CENTER}>
                <box cssName="media-art-square">
                    <Gtk.Frame cssName="media-art-frame" valign={Gtk.Align.CENTER} halign={Gtk.Align.CENTER}>
                        <Gtk.Image
                            cssName="media-art"
                            file={artUrl((url) => url.replace("file://", ""))}
                            pixelSize={300}
                        />
                    </Gtk.Frame>
                </box>
            </box>
            <box cssName="media-text" orientation={Gtk.Orientation.VERTICAL} spacing={4}>
                <label
                    cssName="media-title-large"
                    label={displayTitle}
                    halign={Gtk.Align.CENTER}
                    ellipsize={3}
                    maxWidthChars={30}
                />
                <label
                    cssName="media-artist"
                    label={displayArtist}
                    halign={Gtk.Align.CENTER}
                    ellipsize={3}
                    maxWidthChars={30}
                />
            </box>
        </box>
    )
}

export default function MediaPopup() {
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
            setMediaPopupVisible(false)
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

        if (sorted.length === 0) {
            setMediaPopupVisible(false)
        }
        setCurrentPlayer(sorted[0] || null)
    }

    function onPlayerAdded(_: any, player: Mpris.Player) {
        if (playerConns.has(player)) return

        const conn = player.connect("notify::playback-status", updateCurrent)
        playerConns.set(player, conn)
        updateCurrent()
    }

    mpris.connect("player-added", onPlayerAdded)
    mpris.connect("player-closed", updateCurrent)

    mpris.players.forEach((p) => onPlayerAdded(null, p))
    updateCurrent()

    return (
        <window
            name="media-popup"
            cssName="media-popup"
            visible={mediaPopupVisible}
            anchor={Astal.WindowAnchor.TOP}
            layer={Astal.Layer.OVERLAY}
            exclusivity={Astal.Exclusivity.NORMAL}
            keymode={Astal.Keymode.NONE}
            application={app}
        >
            <With value={currentPlayer}>
                {(player) => (
                    <box cssName="media-popup-content" orientation={Gtk.Orientation.VERTICAL} spacing={16}>
                        {player ? (
                            <>
                                <MediaInfo player={player} />
                                <MediaControls player={player} />
                            </>
                        ) : (
                            <label label="No media playing" cssName="no-media" />
                        )}
                    </box>
                )}
            </With>
        </window>
    )
}
