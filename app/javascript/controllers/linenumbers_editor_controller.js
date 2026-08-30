import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["numbers", "input", "mirror"];

  connect() {
    this.resizeObserver = new ResizeObserver(() => this.update());
    this.resizeObserver.observe(this.inputTarget);
    this.update();
  }

  disconnect() {
    this.resizeObserver?.disconnect();
  }

  update() {
    const text = this.inputTarget.value || "";
    const lines = text.split("\n");

    const wrapCounts = this.measureWrappedRows(lines);

    // Build numbers text: a real line number, followed by blank
    // lines for each extra visual row it wraps onto.
    let out = "";
    for (let i = 0; i < lines.length; i++) {
      out += i + 1 + "\n";
      out += "\n".repeat(Math.max(0, wrapCounts[i] - 1));
    }

    this.numbersTarget.textContent = out;
    this.syncScroll();
  }

  // Renders each line into a hidden mirror element (styled identically
  // to the textarea) so we can measure how many visual rows it wraps
  // onto.
  measureWrappedRows(lines) {
    const mirror = this.mirrorTarget;
    mirror.style.width = this.inputTarget.clientWidth + "px";

    const fragment = document.createDocumentFragment();
    const rowEls = lines.map((line) => {
      const div = document.createElement("div");
      if (line === "") {
        div.appendChild(document.createElement("br"));
      } else {
        div.textContent = line;
      }
      fragment.appendChild(div);
      return div;
    });

    mirror.replaceChildren(fragment);

    const style = getComputedStyle(this.inputTarget);
    const lineHeight = parseFloat(style.lineHeight) || 1;

    return rowEls.map((el) =>
      Math.max(1, Math.round(el.offsetHeight / lineHeight)),
    );
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
