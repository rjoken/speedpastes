import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    connect() {
        this.keydownHandler = (event) => {
            if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === "a") {
                event.preventDefault();
                const contentLines = this.element.querySelectorAll(".paste-content-line");
                if (contentLines.length === 0) return;
                const selection = window.getSelection();
                selection.removeAllRanges();
                contentLines.forEach(line => {
                    const range = document.createRange();
                    range.selectNodeContents(line);
                    selection.addRange(range);
                });
            }
        }
        this.element.addEventListener("keydown", this.keydownHandler);
    }

    disconnect() {
        this.element.removeEventListener("keydown", this.keydownHandler);
    }
}