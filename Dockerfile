FROM ghcr.io/ptero-eggs/steamcmd:proton

ARG LAUNCHER_VERSION=1.1.13
ARG LAUNCHER_SHA256=1bdcf19c5970c2d759e798d13a93c83b1b3b387b16a34c067a6e69b18d1ad803

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends wine \
    && rm -rf /var/lib/apt/lists/*

# The Debian "wine" package is Architecture: all and registers itself through
# update-alternatives, so /usr/bin/wine and /usr/bin/wineserver must both exist
# now or AstroTuxLauncher aborts before it ever touches the server.
RUN command -v wine && command -v wineserver

RUN curl -fsSL -o /usr/local/bin/astrotux-launcher \
        "https://github.com/JoeJoeTV/AstroTuxLauncher/releases/download/${LAUNCHER_VERSION}/AstroTuxLauncher" \
    && echo "${LAUNCHER_SHA256}  /usr/local/bin/astrotux-launcher" | sha256sum -c - \
    && chmod +x /usr/local/bin/astrotux-launcher

COPY src/docker-entrypoint.sh /entrypoint.sh
COPY src/entrypoint.sh /usr/local/bin/astrotux-entrypoint.sh
RUN chmod +x /entrypoint.sh /usr/local/bin/astrotux-entrypoint.sh

USER container
WORKDIR /home/container