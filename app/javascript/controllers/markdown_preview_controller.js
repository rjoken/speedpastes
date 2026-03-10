import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["output", "details"]
    static values = { url: String, debounce: { type: Number, default: 200 } }

    connect() {
        this.timeout = null
        this.requestPreview()
    }

    queue() {
        clearTimeout(this.timeout)
        this.timeout = setTimeout(() => this.requestPreview(), this.debounceValue)
    }

    requestPreview() {
        const form = this.element.querySelector("form")
        if (!form || !this.hasOutputTarget) return

        const bodyInput = form.querySelector('textarea[name="paste[body]"]')
        const renderTypeCheckbox = form.querySelector('input[type="checkbox"][name="paste[render_type]"]')

        const body = bodyInput ? bodyInput.value : ""
        const useMarkdown = !!renderTypeCheckbox?.checked
        const renderType = useMarkdown ? "markdown" : "plain"

        if (this.hasDetailsTarget) {
            this.detailsTarget.classList.toggle("hidden", !useMarkdown)
            if (!useMarkdown) this.detailsTarget.open = false
        }

        if (!useMarkdown) {
            return
        }

        const token = document.querySelector('meta[name="csrf-token"]')?.content

        fetch(this.urlValue, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-CSRF-Token": token,
                "Accept": "text/html"
            },
            body: JSON.stringify({ body, render_type: renderType })
        })
            .then((r) => r.text())
            .then((html) => {
                this.outputTarget.innerHTML = html
            })
    }
}