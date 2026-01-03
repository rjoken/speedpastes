import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["numbers", "input", "content"]

    connect() {
        this.update()
    }

    update() {
        const text = this.contentTarget.textContent || ""

        const lineCount = Math.max(1, text.split("\n").length)

        // Build numbers text
        let out = ""
        for (let i = 1; i <= lineCount; i++) {
            out += i + "\n"
        }

        this.numbersTarget.textContent = out
        this.syncScroll()
    }

    syncScroll() {
        this.numbersTarget.scrollTop = this.contentTarget.scrollTop
    }
}