import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["input"]

    connect() {
        if (!this.hasInputTarget) return

        try {
            const code = localStorage.getItem("invite_code")
            if (!code) return

            if (!this.inputTarget.value) {
                this.inputTarget.value = code
            }

            localStorage.removeItem("invite_code")
        } catch (_) {

        }
    }
}