#!/usr/bin/env bash
# Fetching latest MISP LICENSE
[[ ! -f /script/INSTALL.sh ]] && wget -q -O scripts/INSTALL.sh https://raw.githubusercontent.com/MISP/MISP/2.4/INSTALL/INSTALL.sh
[[ ! -f /tmp/LICENSE-misp ]] && wget -q -O /tmp/LICENSE-misp https://raw.githubusercontent.com/MISP/MISP/2.4/LICENSE
packer build -only=virtualbox-iso misp.json
