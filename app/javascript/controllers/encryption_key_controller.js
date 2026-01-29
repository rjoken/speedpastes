import { Controller } from "@hotwired/stimulus"
import { getE2EEKey, saveE2EEKey, E2EE_KEY_STORAGE, forgetE2EEKey } from "lib/e2ee_key"

export default class extends Controller {
    static targets = ["input", "status"]

    connect() {
        this.refreshStatus()
    }

    save() {
        saveE2EEKey(this.inputTarget.value)

        this.refreshStatus()
        this.dispatchKeyChanged()
        this.inputTarget.value = ""
        this.flashNotice("Encryption key saved to this device.")
    }

    forget() {
        if (!confirm("Forget the encryption key on this device? You may lose access to your encrypted content!")) {
            return
        }

        forgetE2EEKey()

        this.refreshStatus()
        this.dispatchKeyChanged()
        this.flashNotice("Encryption key forgotten from this device.")
    }

    refreshStatus() {
        const key = getE2EEKey()
        if (key) {
            this.statusTarget.textContent = "An encryption key is set."
        } else {
            this.statusTarget.textContent = "No encryption key is set."
        }
    }

    dispatchKeyChanged() {
        window.dispatchEvent(new CustomEvent("speedpastes:e2ee_key_changed"))
    }

    flashNotice(message) {
        const flashEl = document.querySelector('[data-controller="notice"]')
        if (!flashEl) return

        const flash = this.application.getControllerForElementAndIdentifier(flashEl, "notice")
        flash?.show(message)
    }

}
