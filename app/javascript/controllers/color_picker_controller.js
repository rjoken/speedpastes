import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["picker", "input"];
  static classes = ["empty"];

  pick() {
    this.inputTarget.value = this.pickerTarget.value;
    this.sync();
  }

  type() {
    const value = this.inputTarget.value.trim();
    this.sync();
  }

  clear() {
    this.inputTarget.value = "";
    this.sync();
  }

  sync() {
    const value = this.inputTarget.value.trim();

    this.pickerTarget.value = value;
  }
}
