import { createBinding } from "ags"
import { Gtk } from "ags/gtk4"
import Wp from "gi://AstalWp"


export default function VolumeWidget() {
    const wp = Wp.get_default()
    const audio = wp?.audio
    const speaker = audio?.default_speaker

    if (!speaker) {
        return (
            <box cssName="volume">
                <Gtk.Image pixelSize={14} iconName="audio-volume-muted-symbolic" />
            </box>
        )
    }

    const volume = createBinding(speaker, "volume")
    const muted = createBinding(speaker, "mute")

    const iconName = muted((m) => {
        if (m) return "audio-volume-muted-symbolic"
        const v = volume.get()
        return v > 1.0
            ? "audio-volume-overamplified-symbolic"
            : v > 0.75
                ? "audio-volume-high-symbolic"
                : v > 0.50
                    ? "audio-volume-medium-symbolic"
                    : v > 0.25
                        ? "audio-volume-low-symbolic"
                        : "audio-volume-muted-symbolic"
    })

    return (
        <button
            cssName="volume"
            onClicked={() => {
                if (speaker) speaker.mute = !speaker.mute
            }}
        >
            <Gtk.Image pixelSize={14} iconName={iconName} />
        </button>
    )
}
