/**
 * Returns a fuzzy score for a given query.
 * 
 * @param text The text to search in (e.g., "hello world")
 * @param query The query to search for (e.g., "hello")
 * @returns The fuzzy score
 */
export function fuzzyScore(text: string, query: string): number {
    let score = 0
    let textIndex = 0

    for (let i = 0; i < query.length; i++) {
        textIndex = text.indexOf(query[i], textIndex)
        if (textIndex === -1) return 0

        // Bonus for consecutive matches
        if (i > 0 && textIndex === text.indexOf(query[i - 1], 0) + 1) {
            score += 5
        }
        score += 1
        textIndex++
    }
    return score
}
