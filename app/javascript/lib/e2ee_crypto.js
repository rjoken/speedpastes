const KDF_ITER = 100000;
const SALT_BYTES = 16;
const IV_BYTES = 12;

export function makeScratchpadAad({ userId }) {
    return new TextEncoder().encode(`speedpastes:scratchpad:${userId}`);
}

export function ensureV1Meta(metaObj) {
    if (metaObj && metaObj.v === 1 && metaObj.kdf?.salt && metaObj.kdf?.iter) return metaObj;

    const salt = crypto.getRandomValues(new Uint8Array(SALT_BYTES));
    return {
        v: 1,
        kdf: {
            name: "PBKDF2", hash: "SHA-256", iter: KDF_ITER, salt: b64urlEncode(salt)
        },
        alg: { name: "AES-GCM", key_bits: 256 },
    };
}

export function assertV1Meta(metaObj) {
    if (!metaObj || metaObj.v !== 1 || !metaObj.kdf?.salt || !metaObj.kdf?.iter) {
        throw new Error("Missing encryption metadata");
    }

    return metaObj;
}

export async function encryptBodyV1({ plaintext, passphrase, meta, userId }) {
    const metaOut = ensureV1Meta(meta);

    const key = await deriveAesGcmKey(passphrase, metaOut);

    const iv = crypto.getRandomValues(new Uint8Array(IV_BYTES));
    const aad = makeScratchpadAad({ userId });

    const ctBuf = await crypto.subtle.encrypt(
        { name: "AES-GCM", iv, additionalData: aad },
        key,
        new TextEncoder().encode(plaintext)
    );

    const body = `v1:${b64urlEncode(iv)}:${b64urlEncode(new Uint8Array(ctBuf))}`;
    return { body, meta: metaOut };
}

export async function decryptBodyV1({ body, passphrase, meta, userId }) {
    if (!body) return "";

    const metaOk = assertV1Meta(meta);

    const parts = body.split(":");
    if (parts.length !== 3 || parts[0] !== "v1") {
        throw new Error("Invalid ciphertext format");
    }

    const iv = b64urlDecode(parts[1]);
    const ct = b64urlDecode(parts[2]);

    const key = await deriveAesGcmKey(passphrase, metaOk);
    const aad = makeScratchpadAad({ userId });

    const ptBuf = await crypto.subtle.decrypt(
        { name: "AES-GCM", iv, additionalData: aad },
        key,
        ct
    );

    return new TextDecoder().decode(ptBuf);
}

async function deriveAesGcmKey(passphrase, meta) {
    const salt = b64urlDecode(meta.kdf.salt);
    const iter = meta.kdf.iter;

    const keyMaterial = await crypto.subtle.importKey(
        "raw",
        new TextEncoder().encode(passphrase),
        { name: "PBKDF2" },
        false,
        ["deriveKey"]
    );

    return crypto.subtle.deriveKey(
        { name: "PBKDF2", salt, iterations, hash: metaObj.kdf.hash },
        keyMaterial,
        { name: "AES-GCM", length: meta.alg.key_bits },
        false,
        ["encrypt", "decrypt"]
    );
}

function b64urlEncode(buf) {
    let binary = "";
    const chunk = 0x8000;
    for (let i = 0; i < buf.length; i += chunk) {
        binary += String.fromCharCode.apply(...buf.subarray(i, i + chunk));
    }
    return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

function b64urlDecode(str) {
    const b64 = str.replace(/-/g, "+").replace(/_/g, "/") + "===".slice((str.length + 3) % 4);
    const binary = atob(b64);
    const buf = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) {
        buf[i] = binary.charCodeAt(i);
    }
    return buf;
}
