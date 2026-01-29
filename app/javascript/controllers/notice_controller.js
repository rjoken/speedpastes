import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["container"]

    show(message) {
        this.containerTarget.replaceChildren()

        const el = document.createElement("div")
        el.className = "mb-4 border border-[var(--border)] bg-[var(--surface)] px-4 py-3 text-sm shadow-sm"
        el.textContent = message

        this.containerTarget.appendChild(el)
    }
}