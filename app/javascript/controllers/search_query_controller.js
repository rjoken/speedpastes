import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["input"]

    submit() {
        this.element.requestSubmit()
    }
}