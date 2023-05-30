#!/usr/bin/env bash

GOT_PACKER=$(which packer > /dev/null 2>&1; echo $?)
if [[ "$GOT_PACKER" == "0" ]]; then
  echo "Packer detected, version: $(packer -v)"
  PACKER_RUN=$(which packer)
else
  echo "No packer binary detected, please make sure you installed it from: https://www.packer.io/downloads.html"
  exit 1
fi

# SHAsums to be computed
SHA_SUMS="1 256 384 512"

checkInstaller () {
  for sum in $(echo ${SHA_SUMS}); do
    /usr/bin/wget -q -O scripts/INSTALL.sh.sha${sum} https://raw.githubusercontent.com/MISP/MISP/2.4/INSTALL/INSTALL.sh.sha${sum}
    INSTsum=$(shasum -a ${sum} scripts/INSTALL.sh | cut -f1 -d\ )
    chsum=$(cat scripts/INSTALL.sh.sha${sum} | cut -f1 -d\ )

    if [[ "$chsum" == "$INSTsum" ]]; then
      echo "sha${sum} matches"
    else
      echo "sha${sum}: ${chsum} does not match the installer sum of: ${INSTsum}"
      echo "Deleting installer, please run again."
      rm scripts/INSTALL.sh
      exit 1
    fi
  done
}

# Fetch and check installer
if [[ -f "scripts/INSTALL.sh" ]]; then
  echo "Checking checksums"
  checkInstaller
else
  /usr/bin/wget -q -O scripts/INSTALL.sh https://raw.githubusercontent.com/MISP/MISP/2.4/INSTALL/INSTALL.sh
  checkInstaller
fi
# Fetching latest MISP LICENSE
[[ ! -f /tmp/LICENSE-misp ]] && wget -q -O /tmp/LICENSE-misp https://raw.githubusercontent.com/MISP/MISP/2.4/LICENSE
packer build -only=virtualbox-iso misp.json
