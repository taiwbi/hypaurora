import scss from "../style.scss";
import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import Workspaces from "./WorkspacesWidget"
import ClockWidget from "./ClockWidget";
import MediaWidget from "./MediaWidget";
import VolumeWidget from "./VolumeWidget";
import BatteryWidget from "./BatteryWidget";
import NetworkWidget from "./NetworkWidget";


function SystemTray() {
  return (
    <box cssName="system-tray" spacing={8}>
      <VolumeWidget />
      <BatteryWidget />
      <NetworkWidget />
    </box>
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
        <box $type="start" halign={Gtk.Align.START}>
          <Workspaces />
        </box>
        <box $type="center" halign={Gtk.Align.CENTER} spacing={16}>
          <ClockWidget />
          <MediaWidget />
        </box>
        <box $type="end" halign={Gtk.Align.END}>
          <SystemTray />
        </box>
      </centerbox>
    </window>
  )
}
