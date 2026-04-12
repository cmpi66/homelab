FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    git \
    ca-certificates \
    build-essential \
    pkg-config \
    zsh \
    iptables \
    ipset \
    iproute2 \
    dnsutils \
    curl \
    unzip \
    xz-utils \
    zip \
 && rm -rf /var/lib/apt/lists/*

COPY --from=jdxcode/mise /usr/local/bin/mise /usr/local/bin/

# System-wide ZDOTDIR (you already want this)
RUN mkdir -p /etc/zsh \
 && printf '%s\n' 'export ZDOTDIR="$HOME/.config/zsh"' > /etc/zsh/zshenv

RUN mkdir -p \
    /home/vscode/.cache \
    /home/vscode/.local/state \
    /home/vscode/.local/share \
    /home/vscode/.config \
 && chown -R vscode:vscode /home/vscode/.cache /home/vscode/.local /home/vscode/.config

COPY scripts/setup /usr/local/bin/devcontainer-setup
RUN chmod +x /usr/local/bin/devcontainer-setup

