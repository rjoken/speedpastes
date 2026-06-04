import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["picker", "input"];
  static classes = ["empty"];

  pick() {
    this.inputTarget.value = this.pickerTarget.value;
  }

  type() {
    const value = this.inputTarget.value.trim();

    if (HEX_COLOR_REGEX.text(value)) {
      this.pickerTarget.value = value;
    }
  }

  clear() {
    this.inputTarget.value = "";
  }
}
