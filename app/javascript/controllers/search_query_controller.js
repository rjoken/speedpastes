import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["input"]
    static values = { delay: { type: Number, default: 300 } }

    submit() {
        clearTimeout(this.timeout)
        this.timeout = setTimeout(() => {
            this.element.requestSubmit()
        }, this.delayValue)
    }
}