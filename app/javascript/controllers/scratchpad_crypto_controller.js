import { Controller } from "@hotwired/stimulus"
import { getE2EEKey } from "lib/e2ee_key"
import { encryptBodyV1, decryptBodyV1 } from "lib/e2ee_crypto"

export default class extends Controller {
    static targets = ["notice", "blocked", "encryptedField", "encryptionMeta"];

    static values = {
        userId: Number,
        scratchpadId: Number,
        encrypted: Boolean,
        meta: String
    }

    connect() {
        this.key = getE2EEKey();
        this.metaObj = this.safeParse(this.metaValue);

        this.textarea = this.element.querySelector("textarea[name='scratchpad[body]']");
        if (!this.textarea) return;

        window.addEventListener("speedpastes:e2ee_key_changed", this.onKeyChanged);

        this.element.addEventListener("autosave:will-submit", this.onAutosaveWillSubmit);

        this.boot();
    }

    disconnect() {
        window.removeEventListener("speedpastes:e2ee_key_changed", this.onKeyChanged);
        this.element.removeEventListener("autosave:will-submit", this.onAutosaveWillSubmit);
    }

    onKeyChanged = () => {
        this.key = getE2EEKey();
        this.boot();
    }

    onAutosaveWillSubmit = async (event) => {
        if (!this.textarea) return;

        const encrypted = this.encryptedValue;
        const keyPresent = !!this.key;

        if (encrypted && !keyPresent) {
            event.preventDefault?.();
            return;
        }

        if (!encrypted) {
            // Plaintext case, ok
            this.setHiddenFields(false, this.metaObj);
            return;
        }

        this.encryptedValue = true
        // encrypted + key - encrypt current textarea plaintext before autosave submit
        const { body, meta } = await encryptBodyV1({ plaintext: this.textarea.value, passphrase: this.key, meta: this.metaObj, userId: this.userIdValue });
        this.setHiddenFields(true, meta);

        if (event.detail?.formData instanceof FormData) {
            event.detail.formData.set("scratchpad[body]", body);
            event.detail.formData.set("scratchpad[encrypted]", "true");
            event.detail.formData.set("scratchpad[encryption_meta]", JSON.stringify(meta));
        } else if (event.detail) {
            event.detail.bodyOverride = body;
            event.detail.encryptedOverride = true;
            event.detail.metaOverride = meta;
        }
    }

    setHiddenFields(encrypted, metaObj) {
        if (this.hasEncryptedFieldTarget) this.encryptedFieldTarget.value = encrypted ? "true" : "false";
        if (this.hasEncryptionMetaTarget) this.encryptionMetaTarget.value = JSON.stringify(metaObj || {});
    }

    dismissKey() {
        return `speedpastes:scratchpad_unencrypted_notice_dismissed:u:${this.userIdValue}:v1`;
    }

    boot() {
        // Clear UI
        if (this.hasNoticeTarget) this.noticeTarget.replaceChildren();
        if (this.hasBlockedTarget) {
            this.blockedTarget.classList.add("hidden");
            this.blockedTarget.textContent = "";
        }

        const encrypted = !!this.encryptedValue;
        const keyPresent = !!this.key;

        if (!encrypted && !keyPresent) {
            this.showUnencryptedNotice();
            this.setHiddenFields(false, this.metaObj);
            return;
        }

        if (encrypted && !keyPresent) {
            this.textarea.value = "";
            this.textarea.disabled = true;
            this.showMissingKeyBlock();
            return;
        }

        if (encrypted && keyPresent) {
            this.textarea.disabled = false;
            this.decryptIntoTextarea();
            return;
        }

        if (!encrypted && keyPresent) {
            this.autoEncryptNow()
            this.encryptedValue = true;
            this.setHiddenFields(true, this.metaObj);
            this.element.dispatchEvent(new CustomEvent("autosave:request-save"));
            return;
        }
    }

    showUnencryptedNotice() {
        if (localStorage.getItem(this.dismissKey()) === "1") return;

        const wrap = document.createElement("div");
        wrap.className = "border border-[var(--border)] bg-[var(--surface)] px-4 py-3 text-sm shadow-sm flex items-start justify-between gap-4";

        const msg = document.createElement("div")
        msg.textContent = "This scratchpad is stored unencrypted, which means that administrators can see it. Add an encryption key in your account settings to encrypt it on this device.";
        wrap.appendChild(msg);

        const btn = document.createElement("button");
        btn.type = "button";
        btn.className = "opacity-70 hover:opacity-100";
        btn.textContent = "x";
        btn.addEventListener("click", () => {
            localStorage.setItem(this.dismissKey(), "1");
            wrap.remove();
        })
        wrap.appendChild(btn);

        this.noticeTarget.appendChild(wrap);
    }

    showMissingKeyBlock() {
        this.blockedTarget.classList.remove("hidden");
        this.blockedTarget.className = "mb-4 border border-[var(--border)] bg-[var(--surface)] px-4 py-3 text-sm shadow-sm flex items-start justify-between gap-4";
        this.blockedTarget.textContent = "This scratchpad is encrypted, but your encryption key is missing on this device. Go to Settings to add your key.";
    }

    async decryptIntoTextarea() {
        try {
            const plaintext = await decryptBodyV1({ body: this.textarea.value, passphrase: this.key, meta: this.metaObj, userId: this.userIdValue });
            this.textarea.value = plaintext;
            this.setHiddenFields(true, this.metaObj);
        } catch {
            this.textarea.value = "";
            this.textarea.disabled = true;
            this.showMissingKeyBlock();
        }
    }

    async autoEncryptNow() {
        // silently encrypt and persist once
        const plaintext = this.textarea.value;
        const { body, meta } = await encryptBodyV1({ plaintext, passphrase: this.key, meta: this.metaObj, userId: this.userIdValue });

        this.encryptedValue = true;
        this.metaObj = meta;
        this.metaValue = JSON.stringify(meta);

        this.setHiddenFields(true, meta);

        // Trigger an autosave immediately if autosave controller exposes a method,
        // otherwise the next keystroke will save
        this.element.dispatchEvent(new CustomEvent("autosave:request-save"));
    }

    safeParse(str) {
        try { return str ? JSON.parse(str) : {} } catch { return {} }
    }
}
