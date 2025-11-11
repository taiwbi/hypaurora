import app from "ags/gtk4/app"
import style from "./style.scss"
import Bar from "./widget/Bar"
import MediaPopup from "./window/MediaPopup"

app.start({
  css: style,
  main() {
    app.get_monitors().map(Bar)
    MediaPopup()
  },
})
