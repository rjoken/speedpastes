import { Controller } from "@hotwired/stimulus"

const ACCEPTED = ["image/png", "image/jpeg", "image/gif", "image/webp"]

export default class extends Controller {
    static targets = ["input", "status"]
    static values = {
        url: String,
        maxSize: { type: Number, default: 10 * 1024 * 1024 },
        markdownSelector: { type: String, default: 'input[type="checkbox"][name="paste[render_type]"]' }
    }

    connect() {
        this.seq = 0
    }

    onPaste(event) {
        const files = this.imageFilesFrom(event.clipboardData)
        if (!files.length || !this.markdownEnabled) return

        event.preventDefault()
        files.forEach((file) => this.upload(file))
    }

    onDragover(event) {
        if (this.markdownEnabled) event.preventDefault()
    }

    onDrop(event) {
        const files = this.imageFilesFrom(event.dataTransfer)
        if (!files.length || !this.markdownEnabled) return

        event.preventDefault()
        this.inputTarget.focus()
        files.forEach((file) => this.upload(file))
    }

    imageFilesFrom(transfer) {
        return Array.from(transfer?.items || [])
            .filter((item) => item.kind === "file" && ACCEPTED.includes(item.type))
            .map((item) => item.getAsFile())
            .filter(Boolean)
    }

    get markdownEnabled() {
        return !!this.inputTarget.form?.querySelector(this.markdownSelectorValue)?.checked
    }

    async upload(file) {
        const name = this.displayName(file)
        // The token keeps two same-named images from one paste distinguishable
        const placeholder = `![Uploading ${name}… #${Date.now().toString(36)}${this.seq++}]()`

        this.insertAtCursor(placeholder + "\n")

        if (file.size > this.maxSizeValue) {
            this.replacePlaceholder(placeholder, "")
            this.showError(`${name} is too large (max ${Math.round(this.maxSizeValue / 1048576)}MB).`)
            return
        }

        try {
            const body = new FormData()
            body.append("file", file, name)

            const response = await fetch(this.urlValue, {
                method: "POST",
                credentials: "same-origin",
                headers: {
                    "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content,
                    "Accept": "application/json"
                },
                body
            })

            const data = await response.json().catch(() => ({}))
            if (!response.ok) throw new Error(data.error || `Upload failed (${response.status})`)

            this.replacePlaceholder(placeholder, this.markdownFor(name, data.url))
            this.clearError()
        } catch (error) {
            this.replacePlaceholder(placeholder, "")
            this.showError(error.message || "Upload failed.")
        }
    }

    markdownFor(name, url) {
        const alt = name.replace(/[\[\]\\]/g, "\\$&")
        const href = /[()\s<>]/.test(url) ? `<${url}>` : url
        return `![${alt}](${href})`
    }

    displayName(file) {
        const raw = (file.name || "pasted-image").split(/[\\/]/).pop()
        return raw.slice(0, 120).replace(/[\r\n]/g, " ")
    }

    insertAtCursor(text) {
        const el = this.inputTarget
        const start = el.selectionStart ?? el.value.length
        const end = el.selectionEnd ?? start

        // "end" leaves the caret after the placeholder, so a second concurrent
        // upload inserts after this one rather than inside it
        el.setRangeText(text, start, end, "end")
        this.notifyInput()
    }

    // Always search for the placeholder. Any index captured before the upload
    // is stale by the time it resolves, since the user keeps typing.
    replacePlaceholder(placeholder, replacement) {
        const el = this.inputTarget
        const index = el.value.indexOf(placeholder)
        if (index === -1) return

        el.setRangeText(replacement, index, index + placeholder.length, "preserve")
        this.notifyInput()
    }

    // One event drives the line numbers, the markdown preview and the dirty check
    notifyInput() {
        this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
    }

    showError(message) {
        if (!this.hasStatusTarget) return
        this.statusTarget.textContent = message
        this.statusTarget.classList.remove("hidden")
    }

    clearError() {
        if (!this.hasStatusTarget) return
        this.statusTarget.textContent = ""
        this.statusTarget.classList.add("hidden")
    }
}
