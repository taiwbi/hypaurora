import { createPoll } from "ags/time"

export default function ClockWidget() {
    const time = createPoll("", 1000, () => {
        const date = new Date()
        return date.toLocaleTimeString("en-US", {
            hour: "2-digit",
            minute: "2-digit",
            hour12: false,
        })
    })

    return (
        <box cssName="clock">
            <label label={time} />
        </box>
    )
}