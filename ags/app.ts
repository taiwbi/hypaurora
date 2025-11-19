import app from "ags/gtk4/app"
import style from "./style.scss"
import Bar from "./widget/Bar"
import MediaPopup from "./window/MediaPopup"
import Osd from "./window/Osd"
import { showBrightness, showKeyboardBrightness, showKeyboardLayout, showTouchpad, showVolume } from "./lib/osd"

app.start({
  css: style,
  requestHandler(argv, response) {
    const [cmd, ...rest] = argv

    if (cmd === "osd") {
      const [kind, ...args] = rest

      if (kind === "brightness") {
        const level = parseFloat(args[0] ?? "0")
        showBrightness(isNaN(level) ? 0 : level)
        response("ok")
        return
      }

      if (kind === "keyboard-brightness") {
        const level = parseFloat(args[0] ?? "0")
        showKeyboardBrightness(isNaN(level) ? 0 : level)
        response("ok")
        return
      }

      if (kind === "layout") {
        const layout = args[0] ?? ""
        showKeyboardLayout(layout)
        response("ok")
        return
      }

      if (kind === "volume") {
        const level = parseFloat(args[0] ?? "0")
        const mutedArg = (args[1] ?? "").toLowerCase()
        const muted = mutedArg === "1" || mutedArg === "true" || mutedArg === "yes"
        showVolume(isNaN(level) ? 0 : level, muted)
        response("ok")
        return
      }

      if (kind === "touchpad") {
        const state = (args[0] ?? "").toLowerCase()
        const enabled = state === "1" || state === "true" || state === "yes" || state === "on"
        showTouchpad(enabled)
        response("ok")
        return
      }
    }

    response("unknown command")
  },
  main() {
    app.get_monitors().map(Bar)
    MediaPopup()
    Osd()
  },
})
