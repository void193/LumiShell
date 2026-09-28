pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Lumi.Config
import qs.utils

// Launcher power tools: ">run <cmd>", ">ssh <host>", ">enc <text>".
// Results are plain objects shaped like launcher actions (name, desc, icon, onClicked).
Singleton {
    id: root

    property list<string> sshHosts: []

    function argFor(search: string, mode: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}${mode} `.length);
    }

    function inTerminal(args: list<string>): void {
        Quickshell.execDetached([...GlobalConfig.general.apps.terminal, `${Quickshell.shellDir}/assets/wrap_term_launch.sh`, ...args]);
    }

    function copy(text: string): void {
        Quickshell.execDetached(["wl-copy", "--", text]);
    }

    // >run: in a terminal that stays open, or silently in the background
    function run(search: string): var {
        const cmd = argFor(search, "run").trim();
        if (!cmd)
            return [item("terminal", qsTr("Type a command"), qsTr("Runs in %1").arg(GlobalConfig.general.apps.terminal[0] ?? "terminal"), null)];

        return [item("terminal", cmd, qsTr("Run in terminal"), list => {
                list.screenState.launcher = false;
                root.inTerminal(["sh", "-c", `${cmd}; exec "\${SHELL:-sh}"`]);
            }), item("bolt", cmd, qsTr("Run in background"), list => {
                list.screenState.launcher = false;
                Quickshell.execDetached(["sh", "-c", cmd]);
            })];
    }

    // >ssh: hosts from ~/.ssh/config and known_hosts, or whatever was typed
    function ssh(search: string): var {
        sshReader.reload();
        const q = argFor(search, "ssh").trim();
        const hosts = sshHosts.filter(h => h.toLowerCase().includes(q.toLowerCase()));
        if (q && !hosts.includes(q))
            hosts.unshift(q);
        if (hosts.length === 0)
            return [item("lan", qsTr("No known hosts"), qsTr("Type user@host to connect"), null)];

        return hosts.slice(0, 20).map(h => item("lan", h, `ssh ${h}`, list => {
                list.screenState.launcher = false;
                root.inTerminal(["ssh", h]);
            }));
    }

    // >enc: encodings and hashes of the text; Enter copies the value
    function enc(search: string): var {
        const text = argFor(search, "enc");
        if (!text)
            return [item("key", qsTr("Type some text"), qsTr("base64, hex, url, sha256, sha1, md5"), null)];

        const utf8 = unescape(encodeURIComponent(text));
        const out = [];
        const add = (label, value) => out.push(item("content_copy", value, label, list => {
                list.screenState.launcher = false;
                root.copy(value);
            }));

        add("base64", b64encode(utf8));
        try {
            const decoded = decodeURIComponent(escape(b64decode(text.trim())));
            if (decoded && /^[\x09\x0a\x0d\x20-\x7e -￿]*$/.test(decoded))
                add("base64 → text", decoded);
        } catch (e) {}
        add("hex", Array.from(utf8, c => c.charCodeAt(0).toString(16).padStart(2, "0")).join(""));
        add("url", encodeURIComponent(text));
        add("sha256", sha256(utf8));
        add("sha1", sha1(utf8));
        add("md5", Qt.md5(text));
        return out;
    }

    function item(icon: string, name: string, desc: string, action: var): var {
        return {
            icon: icon,
            name: name,
            desc: desc,
            onClicked: action ?? (() => {})
        };
    }

    // Hashes over a byte string (one char per byte)
    function sha256(bytes) {
        const k = [0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da, 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070, 0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2];
        const h = [0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19];
        const words = pad(bytes);
        const rotr = (x, n) => (x >>> n) | (x << (32 - n));
        for (let i = 0; i < words.length; i += 16) {
            const w = words.slice(i, i + 16);
            for (let t = 16; t < 64; t++) {
                const s0 = rotr(w[t - 15], 7) ^ rotr(w[t - 15], 18) ^ (w[t - 15] >>> 3);
                const s1 = rotr(w[t - 2], 17) ^ rotr(w[t - 2], 19) ^ (w[t - 2] >>> 10);
                w[t] = (w[t - 16] + s0 + w[t - 7] + s1) | 0;
            }
            let [a, b, c, d, e, f, g, hh] = h;
            for (let t = 0; t < 64; t++) {
                const t1 = (hh + (rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25)) + ((e & f) ^ (~e & g)) + k[t] + w[t]) | 0;
                const t2 = ((rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22)) + ((a & b) ^ (a & c) ^ (b & c))) | 0;
                hh = g;
                g = f;
                f = e;
                e = (d + t1) | 0;
                d = c;
                c = b;
                b = a;
                a = (t1 + t2) | 0;
            }
            [a, b, c, d, e, f, g, hh].forEach((v, j) => h[j] = (h[j] + v) | 0);
        }
        return h.map(toHex).join("");
    }

    function sha1(bytes) {
        const h = [0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476, 0xc3d2e1f0];
        const words = pad(bytes);
        const rotl = (x, n) => (x << n) | (x >>> (32 - n));
        for (let i = 0; i < words.length; i += 16) {
            const w = words.slice(i, i + 16);
            for (let t = 16; t < 80; t++)
                w[t] = rotl(w[t - 3] ^ w[t - 8] ^ w[t - 14] ^ w[t - 16], 1);
            let [a, b, c, d, e] = h;
            for (let t = 0; t < 80; t++) {
                const f = t < 20 ? (b & c) | (~b & d) : t < 40 ? b ^ c ^ d : t < 60 ? (b & c) | (b & d) | (c & d) : b ^ c ^ d;
                const kk = t < 20 ? 0x5a827999 : t < 40 ? 0x6ed9eba1 : t < 60 ? 0x8f1bbcdc : 0xca62c1d6;
                const tmp = (rotl(a, 5) + f + e + kk + w[t]) | 0;
                e = d;
                d = c;
                c = rotl(b, 30);
                b = a;
                a = tmp;
            }
            [a, b, c, d, e].forEach((v, j) => h[j] = (h[j] + v) | 0);
        }
        return h.map(toHex).join("");
    }

    // Big-endian 32-bit words with Merkle–Damgård padding
    function pad(bytes) {
        const len = bytes.length;
        const words = [];
        for (let i = 0; i < len; i++)
            words[i >> 2] |= (bytes.charCodeAt(i) & 0xff) << (24 - (i % 4) * 8);
        words[len >> 2] |= 0x80 << (24 - (len % 4) * 8);
        const total = (((len + 8) >> 6) + 1) * 16;
        for (let i = 0; i < total; i++)
            words[i] = words[i] | 0;
        words[total - 1] = (len * 8) | 0;
        words[total - 2] = Math.floor(len * 8 / 0x100000000) | 0;
        return words;
    }

    readonly property string b64chars: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

    function b64encode(bytes) {
        let out = "";
        for (let i = 0; i < bytes.length; i += 3) {
            const n = (bytes.charCodeAt(i) << 16) | ((bytes.charCodeAt(i + 1) || 0) << 8) | (bytes.charCodeAt(i + 2) || 0);
            out += b64chars[n >> 18 & 63] + b64chars[n >> 12 & 63];
            out += i + 1 < bytes.length ? b64chars[n >> 6 & 63] : "=";
            out += i + 2 < bytes.length ? b64chars[n & 63] : "=";
        }
        return out;
    }

    // Throws on anything that isn't valid base64
    function b64decode(text) {
        const clean = text.replace(/=+$/, "");
        if (!clean || clean.length % 4 === 1 || /[^A-Za-z0-9+/]/.test(clean))
            throw new Error("not base64");
        let out = "";
        let buf = 0;
        let bits = 0;
        for (const c of clean) {
            buf = (buf << 6) | b64chars.indexOf(c);
            bits += 6;
            if (bits >= 8) {
                bits -= 8;
                out += String.fromCharCode((buf >> bits) & 0xff);
            }
        }
        return out;
    }

    function toHex(n) {
        return (n >>> 0).toString(16).padStart(8, "0");
    }

    Process {
        id: sshReader

        function reload(): void {
            if (!running)
                running = true;
        }

        command: ["sh", "-c", `
            cfg="$HOME/.ssh/config"
            [ -f "$cfg" ] && awk 'tolower($1)=="host"{for(i=2;i<=NF;i++) if ($i !~ /[*?!]/) print $i}' "$cfg"
            kh="$HOME/.ssh/known_hosts"
            [ -f "$kh" ] && awk '$1 !~ /^\\|/ && $1 !~ /^#/ {split($1,a,","); h=a[1]; gsub(/^\\[|\\]:[0-9]+$/,"",h); print h}' "$kh"
        `]
        stdout: StdioCollector {
            onStreamFinished: root.sshHosts = [...new Set(text.split("\n").map(l => l.trim()).filter(l => l))]
        }
    }

    Component.onCompleted: sshReader.reload()
}
