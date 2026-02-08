import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["button", "code"];

    copy() {
        const codes = [];
        this.codeTargets.forEach(el => {
            const uses = parseInt(el.dataset.usesCount, 10);
            const maxUses = parseInt(el.dataset.maxUses, 10);
            if (uses < maxUses) {
                codes.push(el.dataset.code);
            }
        })
        if (codes.length > 0) {
            navigator.clipboard.writeText(codes.join("\n"));
            this.buttonTarget.textContent = "Copied!";
            setTimeout(() => {
                this.buttonTarget.textContent = "Copy valid invites";
            }, 1500);
        }
    }
}
