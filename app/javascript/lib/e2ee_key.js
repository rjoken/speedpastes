export const E2EE_KEY_STORAGE = "speedpastes:e2ee_key:v1"

export function saveE2EEKey(passphrase) {
    if (!passphrase || !(typeof passphrase === "string") || !passphrase.trim()) {
        throw new Error("Invalid passphrase")
    }
    localStorage.setItem(E2EE_KEY_STORAGE, passphrase.trim())
}

export function getE2EEKey() {
    return localStorage.getItem(E2EE_KEY_STORAGE)
}

export function forgetE2EEKey() {
    localStorage.removeItem(E2EE_KEY_STORAGE)
}
