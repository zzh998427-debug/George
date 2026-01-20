# ProxySBX: The Modern, Stealthy Proxy Suite

**ProxySBX** is an open-source, simplified, and highly secure script for deploying next-generation proxy nodes. Designed for privacy engineers and network administrators, it prioritizes stealth, stability, and speed.

Unlike legacy scripts, ProxySBX uses a single unified core (**Sing-box**) to reduce overhead and attack surface. It is designed to be deployed on VPS, Docker, or Container-as-a-Service (CaaS) environments with minimal configuration.

## Key Features
* **Unified Core**: Powered entirely by Sing-box (Go) for maximum efficiency.
* **Stealth Protocols**: Out-of-the-box support for **VLESS-Reality**, **Hysteria2**, **TUIC v5**, and **Shadowsocks-2022**.
* **Security First**: No hardcoded secrets, logs, or external callbacks. Enforces strong crypto (X25519, AES-256-GCM/Chacha20).
* **Anti-Detection**: Mimics standard HTTPS (HTTP/3) traffic to evade active probing and DPI.
* **Cloud Ready**: Optimized for low-resource environments (Free Tier VPS, Docker).
* **Zero Bloat**: Removed legacy protocols (VMess, unsecured HTTP) and complex menu navigations.

## License
MIT License - Free and Open Source.

