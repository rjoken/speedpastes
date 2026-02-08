import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["numbers", "input"];

    connect() {
        this.update();
    }

    update() {
        const text = this.inputTarget.value || "";

        const lineCount = Math.max(1, text.split("\n").length);

        // Build numbers text
        let out = "";
        for (let i = 1; i <= lineCount; i++) {
            out += i + "\n";
        }

        this.numbersTarget.textContent = out;
        this.syncScroll();
    }

    syncScroll() {
        this.numbersTarget.scrollTop = this.inputTarget.scrollTop;
    }

    keydown(event) {
        // Tab inserts a literal tab character
        if (event.key === "Tab") {
            event.preventDefault();
            this.insertAtSelection("\t");
            this.update();
            return;
        }

        // Ctrl+Enter or Cmd+Enter submits the form
        if ((event.ctrlKey || event.metaKey) && event.key === "Enter") {
            event.preventDefault();
            const form = this.inputTarget.form.closest("form");
            if (form?.requestSubmit) form.requestSubmit();
            else form?.submit();
        }
    }

    // Fallback
    insertAtSelection(text) {
        const el = this.inputTarget;
        const start = el.selectionStart ?? 0;
        const end = el.selectionEnd ?? start;

        // Modern browsers
        if (typeof el.setRangeText === "function") {
            el.setRangeText(text, start, end, "end");
            return;
        }

        // Fallback
        const value = el.value;
        el.value = value.slice(0, start) + text + value.slice(end);
        const pos = start + text.length;
        el.selectionStart = el.selectionEnd = pos;
    }
}
