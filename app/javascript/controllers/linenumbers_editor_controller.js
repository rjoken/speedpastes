import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["numbers", "input"]

    connect() {
        this.update()
    }

    update() {
        const text = this.inputTarget.value || ""

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
        const y = this.inputTarget.scrollTop
        this.numbersTarget.style.transform = `translateY(-${y}px)`
    }
}