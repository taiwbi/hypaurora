import GLib from "gi://GLib"
import Gio from "gi://Gio"
import { execAsync } from "ags/process"

const SETTINGS_SCHEMA = "org.hypaurora.ai"

interface AIResponse {
    choices?: {
        message?: {
            content?: string
        }
    }[]
    error?: {
        message: string
    }
}

class AIService {
    private settings!: Gio.Settings
    private _endpoint: string = ""
    private _apiKey: string = ""
    private _model: string = ""

    constructor() {
        const schemaSource = Gio.SettingsSchemaSource.new_from_directory(
            GLib.get_current_dir() + "/schemas",
            Gio.SettingsSchemaSource.get_default(),
            false,
        )
        const schema = schemaSource.lookup(SETTINGS_SCHEMA, true)
        if (!schema) {
            console.warn(`Schema ${SETTINGS_SCHEMA} not found. AI features will be disabled.`)
            return
        }
        this.settings = new Gio.Settings({ settings_schema: schema })

        this._endpoint = this.settings.get_string("endpoint-url")
        this._apiKey = this.settings.get_string("api-key")
        this._model = this.settings.get_string("model")

        this.settings.connect("changed::endpoint-url", () => {
            this._endpoint = this.settings.get_string("endpoint-url")
        })
        this.settings.connect("changed::api-key", () => {
            this._apiKey = this.settings.get_string("api-key")
        })
        this.settings.connect("changed::model", () => {
            this._model = this.settings.get_string("model")
        })
    }



    async query(prompt: string): Promise<string> {
        if (!this.settings) return "Settings not loaded."
        if (!this._apiKey) return "API Key is not set. Please configure org.hypaurora.ai."

        try {
            const body = {
                model: this._model,
                messages: [
                    {
                        role: "system",
                        content: "You are a helpful assistant running on a Linux system. Your name is Aurora and you can answer questions about Linux, programming and other topics.\n\nAnswer minimal, concise and only as much as needed, avoid long responses and too much details.\n\n - DO NOT reveal your model name or creator company."
                    },
                    {
                        role: "user",
                        content: prompt
                    }
                ]
            }

            // Escape single quotes for shell
            const jsonBody = JSON.stringify(body).replace(/'/g, "'\\''")

            const cmd = `curl -s -X POST "${this._endpoint}" \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer ${this._apiKey}" \
                -d '${jsonBody}'`

            const output = await execAsync(["bash", "-c", cmd])
            const response = JSON.parse(output) as AIResponse

            if (response.error) {
                return `API Error: ${response.error.message}`
            }

            return response.choices?.[0]?.message?.content || "No response from AI."
        } catch (e) {
            console.error(e)
            return `Error: ${e}`
        }
    }
}

export const ai = new AIService()
