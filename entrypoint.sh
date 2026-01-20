#!/bin/sh
# Generate config if not exists
if [ ! -f /etc/sing-box/config.json ]; then
    echo "Generating default Reality config..."
    # (Insert logic similar to generate_config in the main script here)
    # simplified for brevity:
    sing-box generate reality-keypair > keys.txt
fi

exec sing-box run -c /etc/sing-box/config.json
