#!/usr/bin/env bash
set -euo pipefail

# systemd takes over everything so need to have this script if pihole is to be used
# its only needed once on your target server
CONF="/etc/systemd/resolved.conf"
RESOLV="/etc/resolv.conf"

sudo mkdir -p /etc/systemd/resolved.conf.d

# Disable local stub listener so Pi-hole can own port 53
sudo tee /etc/systemd/resolved.conf.d/10-disable-stub.conf >/dev/null <<'EOF'
[Resolve]
DNSStubListener=no
EOF

sudo systemctl restart systemd-resolved

# Make resolv.conf use real upstream DNS until Pi-hole is fully adopted
if [ -L "$RESOLV" ]; then
  sudo rm -f "$RESOLV"
fi

# keep host machine nameservers sane, everything upstream frm this gets pihole dns
sudo tee "$RESOLV" >/dev/null <<'EOF'
nameserver 1.1.1.1
nameserver 1.0.0.1
EOF

# Verification
echo "[*] Port 53 listeners:"
ss -lntup | grep ':53' || true

echo
echo "[*] resolv.conf:"
cat /etc/resolv.conf
