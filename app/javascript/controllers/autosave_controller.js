import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["input"];
    static values = { debounce: Number };

    connect() {
        this.saveHandler = this.debounce(this.save.bind(this), this.debounceValue || 1000);
        if (this.inputTarget) {
            this.inputTarget.addEventListener("input", this.saveHandler);
        }
    }

    disconnect() {
        if (this.inputTarget) {
            this.inputTarget.removeEventListener("input", this.saveHandler);
        }
    }

    save() {
        const form = this.element;
        const url = form.action;
        const formData = new FormData(form);

        fetch(url, {
            method: "PATCH",
            headers: { "Accept": "application/json" },
            body: formData
        });
    }

    debounce(func, wait) {
        let timeout;
        return function (...args) {
            clearTimeout(timeout);
            timeout = setTimeout(() => func.apply(this, args), wait);
        }
    }
}