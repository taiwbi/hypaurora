import scss from "../style.scss";
import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import Workspaces from "./WorkspacesWidget"
import ClockWidget from "./ClockWidget";
import MediaWidget from "./MediaWidget";
import VolumeWidget from "./VolumeWidget";
import BatteryWidget from "./BatteryWidget";
import NetworkWidget from "./NetworkWidget";
import { toggleControlCenter } from "../lib/controlcenter";
import { toggleTimePopup } from "../window/TimePopup";


function SystemTray() {
  return (
    <button
      cssName="system-tray"
      onClicked={toggleControlCenter}
    >
      <box spacing={8}>
        <VolumeWidget />
        <BatteryWidget />
        <NetworkWidget />
      </box>
    </button>
  )
}

export default function Bar(gdkmonitor: Gdk.Monitor) {
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible
      name="bar"
      cssName="Bar"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={TOP | LEFT | RIGHT}
      application={app}
    >
      <centerbox cssName="bar-content">
        <box $type="start" cssName="bar-section-left" halign={Gtk.Align.START}>
          <Workspaces />
        </box>
        <box $type="center" cssName="bar-section-center" halign={Gtk.Align.CENTER} spacing={16}>
          <button cssName="clock-button" onClicked={toggleTimePopup}>
            <ClockWidget />
          </button>
          <MediaWidget />
        </box>
        <box $type="end" cssName="bar-section-right" halign={Gtk.Align.END}>
          <SystemTray />
        </box>
      </centerbox>
    </window>
  )
}
