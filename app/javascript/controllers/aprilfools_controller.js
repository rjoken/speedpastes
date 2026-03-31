import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect() {
        const date = new Date();
        if (date.getMonth() !== 3 || date.getDate() !== 1) return;

        document.getElementById("april-fools-container").classList.remove("hidden");
        this.element.textContent = localStorage.getItem("hatesFun") ? "I love fun" : "I hate fun"
    }
    disable() {
        if (localStorage.getItem("hatesFun")) {
            localStorage.removeItem("hatesFun")
            document.documentElement.setAttribute("data-april-fools", "true")
            return
        } else {
            localStorage.setItem("hatesFun", "true")
            document.documentElement.removeAttribute("data-april-fools")
        }

    }
}