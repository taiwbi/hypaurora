import { exec } from "ags/process"

function normalizeExpression(raw: string): string {
    if (!raw) {
        return ""
    }

    let expr = raw.trim()
    if (!expr) {
        return ""
    }

    expr = expr.replace(/,/g, ".")
    expr = expr.replace(/×|x/gi, "*")
    expr = expr.replace(/÷/g, "/")
    expr = expr.replace(/√/gi, "sqrt")

    const allowed = /^[0-9+\-*/%^().,!\sA-Za-z]*$/
    if (!allowed.test(expr)) {
        return ""
    }

    return expr
}

export function evaluateMathExpression(input: string): number | null {
    const expr = normalizeExpression(input)
    if (!expr) {
        return null
    }

    const hasDigit = /[0-9]/.test(expr)
    const hasOperation = /[+\-*/%^]/.test(expr) || /[A-Za-z]/.test(expr)
    if (!hasDigit || !hasOperation) {
        return null
    }

    try {
        const output = exec(["gnome-calculator", `--solve=${expr}`]).trim()
        if (!output) {
            return null
        }
        const normalized = output.replace(/,/g, ".")
        const result = Number(normalized)
        if (!Number.isFinite(result)) {
            return null
        }
        return result
    } catch (_err) {
        return null
    }
}