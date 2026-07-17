import { Gtk } from "ags/gtk4"
import { marked, Token, Tokens } from "marked"
import GLib from "gi://GLib"
import { Accessor } from "ags"

// Helper to escape Pango markup
function escape(text: string): string {
    return GLib.markup_escape_text(text, -1)
}

export function ReactiveMarkdown({ content }: { content: Accessor<string> }) {
    return (
        <box
            orientation={Gtk.Orientation.VERTICAL}
            spacing={12}
            halign={Gtk.Align.FILL}
            $={(self: Gtk.Box) => {
                content.subscribe(() => {
                    const c = content.get()
                    // Clear existing children
                    let child = self.get_first_child()
                    while (child) {
                        const next = child.get_next_sibling()
                        self.remove(child)
                        child = next
                    }

                    // Add new markdown widgets
                    if (c) {
                        const tokens = marked.lexer(c)
                        tokens.forEach((token) => {
                            const widget = RenderToken({ token })
                            if (widget) {
                                self.append(widget)
                            }
                        })
                    }
                })
            }}
        />
    )
}

function RenderToken({ token }: { token: Token }): Gtk.Widget | null {
    switch (token.type) {
        case "heading":
            const headingToken = token as Tokens.Heading
            const sizes = ["xx-large", "x-large", "large", "medium", "small", "small"]
            const fontSize = sizes[headingToken.depth - 1] || "medium"
            return (
                <label
                    cssName="heading"
                    class={`md-heading md-h${headingToken.depth}`}
                    label={`<span weight="bold" size="${fontSize}">${escape(headingToken.text)}</span>`}
                    useMarkup={true}
                    xalign={0}
                    wrap={true}
                    marginTop={headingToken.depth === 1 ? 0 : 12}
                    marginBottom={8}
                />
            ) as unknown as Gtk.Widget

        case "paragraph":
            const pToken = token as Tokens.Paragraph
            return (
                <label
                    cssName="md-paragraph"
                    label={parseInline(pToken.tokens).trim()}
                    useMarkup={true}
                    xalign={0}
                    wrap={true}
                    selectable={true}
                />
            ) as unknown as Gtk.Widget

        case "code":
            const codeToken = token as Tokens.Code
            return (
                <box cssName="md-code-block" orientation={Gtk.Orientation.VERTICAL} css="margin: 8px;">
                    <label
                        cssName="md-code-lang"
                        label={codeToken.lang || "text"}
                        halign={Gtk.Align.END}
                        opacity={0.6}
                        css="font-size: 10px; margin-bottom: 4px;"
                    />
                    <box cssName="md-code-content" css="background-color: rgba(30, 30, 30, 0.5); border-radius: 8px; padding: 12px;">
                        <label
                            label={`<span font_family="monospace">${escape(codeToken.text)}</span>`}
                            useMarkup={true}
                            xalign={0}
                            wrap={true}
                            selectable={true}
                        />
                    </box>
                </box>
            ) as unknown as Gtk.Widget

        case "list":
            const listToken = token as Tokens.List
            return (
                <box orientation={Gtk.Orientation.VERTICAL} spacing={4} css="margin-left: 16px;">
                    {listToken.items.map((item) => (
                        <box orientation={Gtk.Orientation.HORIZONTAL} spacing={8}>
                            <label label="•" valign={Gtk.Align.START} />
                            <box orientation={Gtk.Orientation.VERTICAL}>
                                {item.tokens.map((t) => RenderToken({ token: t })).filter((w): w is Gtk.Widget => w !== null)}
                            </box>
                        </box>
                    ))}
                </box>
            ) as unknown as Gtk.Widget

        case "table":
            const tableToken = token as Tokens.Table
            return (
                <box orientation={Gtk.Orientation.VERTICAL} cssName="md-table" css="border: 1px solid rgba(128,128,128,0.2); border-radius: 8px;">
                    {/* Header */}
                    <box orientation={Gtk.Orientation.HORIZONTAL} spacing={8} css="background-color: rgba(128,128,128,0.1); padding: 8px;">
                        {tableToken.header.map((cell) => (
                            <label
                                label={`<b>${parseInline(cell.tokens)}</b>`}
                                useMarkup={true}
                                hexpand
                                xalign={0}
                            />
                        ))}
                    </box>
                    {/* Rows */}
                    {tableToken.rows.map((row) => (
                        <box orientation={Gtk.Orientation.HORIZONTAL} spacing={8} css="padding: 8px; border-top: 1px solid rgba(128,128,128,0.1);">
                            {row.map((cell) => (
                                <label
                                    label={parseInline(cell.tokens)}
                                    useMarkup={true}
                                    hexpand
                                    xalign={0}
                                />
                            ))}
                        </box>
                    ))}
                </box>
            ) as unknown as Gtk.Widget

        case "space":
            return null

        case "hr":
            return <box heightRequest={1} css="background-color: rgba(128,128,128,0.5); margin: 12px 0;" /> as unknown as Gtk.Widget

        case "blockquote":
            const quoteToken = token as Tokens.Blockquote
            return (
                <box cssName="md-blockquote" css="border-left: 4px solid rgba(128,128,128,0.5); padding-left: 12px; margin: 8px 0;">
                    <box orientation={Gtk.Orientation.VERTICAL}>
                        {quoteToken.tokens.map((t) => RenderToken({ token: t })).filter((w): w is Gtk.Widget => w !== null)}
                    </box>
                </box>
            ) as unknown as Gtk.Widget

        case "text":
            const textToken = token as Tokens.Text
            return (
                <label
                    cssName="md-text"
                    label={parseInline(textToken.tokens).trim() || escape(textToken.text)}
                    useMarkup={true}
                    xalign={0}
                    wrap={true}
                    selectable={true}
                />
            ) as unknown as Gtk.Widget

        default:
            return <box /> as unknown as Gtk.Widget
    }
}

function parseInline(tokens: Token[] | undefined): string {
    if (!tokens) return ""
    return tokens.map(token => {
        switch (token.type) {
            case "text":
            case "escape":
                return escape((token as Tokens.Text).text)
            case "strong":
                return `<b>${parseInline((token as Tokens.Strong).tokens)}</b>`
            case "em":
                return `<i>${parseInline((token as Tokens.Em).tokens)}</i>`
            case "codespan":
                return `<tt>${escape((token as Tokens.Codespan).text)}</tt>`
            case "link":
                const linkToken = token as Tokens.Link
                return `<a href="${linkToken.href}">${parseInline(linkToken.tokens)}</a>`
            case "image":
                return `[Image: ${(token as Tokens.Image).text}]`
            default:
                return escape(token.raw)
        }
    }).join("")
}
