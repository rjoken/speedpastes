import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["select"]

    connect() {
        const current = this.currentTheme()
        this.applyTheme(current)
        if (this.hasSelectTarget) {
            this.selectTarget.value = current
        }
    }

    change() {
        const theme = this.selectTarget.value
        this.applyTheme(theme)
        localStorage.setItem("theme", theme)
    }

    currentTheme() {
        return localStorage.getItem("theme") || document.documentElement.getAttribute("data-theme") || "cyber"
    }

    applyTheme(theme) {
        document.documentElement.setAttribute("data-theme", theme)
    }
}