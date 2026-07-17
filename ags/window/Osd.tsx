import app from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"
import { osdVisible, osdTitle, osdLabel, osdIcon, osdValue, osdShowSlider } from "../lib/osd"
import { With } from "gnim"

export default function Osd() {
    const adjustment = Gtk.Adjustment.new(0, 0, 100, 1, 10, 0)
    adjustment.set_value(osdValue.get())
    osdValue.subscribe(() => {
        adjustment.value = osdValue.get()
    })

    return (
        <window
            name="osd"
            cssName="osd"
            visible={osdVisible}
            anchor={Astal.WindowAnchor.BOTTOM}
            layer={Astal.Layer.OVERLAY}
            exclusivity={Astal.Exclusivity.NORMAL}
            keymode={Astal.Keymode.NONE}
            application={app}
        >
            <box
                cssName="osd-container"
            >
                <box cssName="osd-box" spacing={12}>
                    <Gtk.Image cssName="osd-icon" iconName={osdIcon} />
                    <box orientation={Gtk.Orientation.VERTICAL} halign={Gtk.Align.START} valign={Gtk.Align.CENTER} spacing={4}>
                        <label cssName="osd-title" label={osdTitle} halign={Gtk.Align.START} />
                        <With value={osdShowSlider}>
                            {(showSlider) => (
                                <Gtk.Scale
                                    cssName="osd-slider"
                                    orientation={Gtk.Orientation.HORIZONTAL}
                                    drawValue={false}
                                    hexpand={true}
                                    adjustment={adjustment}
                                    sensitive={false}
                                    visible={showSlider}
                                />
                            )}
                        </With>
                        <With value={osdShowSlider}>
                            {(showSlider) => (
                                <label cssName="osd-value" label={osdLabel} visible={!showSlider} halign={Gtk.Align.START} />
                            )}
                        </With>
                    </box>
                </box>
            </box>
        </window>
    )
}