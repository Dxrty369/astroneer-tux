#!/bin/bash

# Replaces the stock steamcmd:proton entrypoint. The original one runs its own
# steamcmd pass whenever AUTO_UPDATE is unset, which collides with the
# launcher's DepotDownloader updater, so we skip it entirely and hand off to
# the AstroTuxLauncher wrapper.

TZ=${TZ:-UTC}
export TZ

cd /home/container || exit 1

MODIFIED_STARTUP=$(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo -e ":/home/container$ ${MODIFIED_STARTUP}"

eval ${MODIFIED_STARTUP}