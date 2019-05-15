#!/usr/bin/env bash

# Timing creation
TIME_START=$(date +%s)

GOT_PACKER=$(which packer > /dev/null 2>&1; echo $?)
if [[ "${GOT_PACKER}" == "0" ]]; then
  echo "Packer detected, version: $(packer -v)"
  PACKER_RUN=$(which packer)
else
  echo "No packer binary detected, please make sure you installed it from: https://www.packer.io/downloads.html"
  exit 1
fi

GOT_RHASH=$(which rhash > /dev/null 2>&1; echo $?)
if [[ "${GOT_RHASH}" == "0" ]]; then
  echo "rhash detected, version: $(rhash --version)"
  RHASH_RUN=$(which rhash)
else
  echo "No rhash binary detected, please make sure you installed it."
  exit 1
fi

# Place holder
checkBin ()
{
  echo "NOOP"
}

# Latest version of misp
VER=$(curl -s https://api.github.com/repos/MISP/MISP/tags  |jq -r '.[0] | .name')
# Latest commit hash of misp
LATEST_COMMIT=$(curl -s https://api.github.com/repos/MISP/MISP/commits  |jq -r '.[0] | .sha')
LATEST_COMMIT_SHORT=$(echo ${LATEST_COMMIT} |cut -c1-7)

if [[ "${VER}" == "" ]] || [[ "${LATEST_COMMIT}" == "" ]] ; then
  echo "Somehow, could not 'curl' either a version or a commit tag, exiting -1..."
  exit -1
fi

# SHAsums to be computed, not the -- notatiation is for ease of use with rhash
SHA_SUMS="--sha1 --sha256 --sha384 --sha512"

PACKER_NAME="misp"
PACKER_VM="MISP"
NAME="misp-packer"

# Update time-stamp and make sure file exists
touch /tmp/${PACKER_NAME}-latest.sha

# Configure your user and remote server
REMOTE=1
REL_USER="${PACKER_NAME}-release"
REL_SERVER="cpab"

# GPG Sign
GPG_ENABLED=1
GPG_KEY="0x"

# Enable debug for packer, omit -debug to disable
##PACKER_DEBUG="-debug"

# Enable logging and debug for packer
export PACKER_LOG=0

# Make sure we have a current work directory
PWD=`pwd`

# Make sure log dir exists (-p quiets if exists)
mkdir -p ${PWD}/log

vm_description='MISP, is an open source software solution for collecting, storing, distributing and sharing cyber security indicators and threat about cyber security incidents analysis and malware analysis. MISP is designed by and for incident analysts, security and ICT professionals or malware reverser to support their day-to-day operations to share structured informations efficiently.'
vm_version='2.4'


# TODO: have the checksums on a 2nd source, GitHub? compare https://circl.lu with GH

# Place holder, this fn() should be used to anything signing related
signify ()
{

  # This should create the following file:
  # MISP_v2.4.105@3a25986766623f64255136e3fa5eec3af1faad7f-CHECKSUM.asc
  # -----BEGIN PGP SIGNED MESSAGE-----
  # Hash: SHA1, SHA256, SHA384, SHA512
  #
  # # $FILE_NAME: 3177185280 bytes
  # SHA256 ($FILE_NAME) = bb0622b78449298e24a96b90b561b429edec71aae72b8f7a8c3da4d81e4df5b7
  #
  # # MISP_v2.4.105@3a25986766623f64255136e3fa5eec3af1faad7f.ova: 625999872 bytes
  # SHA256 (MISP_v2.4.105@3a25986766623f64255136e3fa5eec3af1faad7f.ova) = 5e4eac4566d8c572bfb3bcf54b7d6c82006ec3c6c882a2c9235c6d3494d7b100
  # -----BEGIN PGP SIGNATURE-----
  #
  # iQIcBAEBCAAGBQJcw139AAoJEO88ER/Pxlm557kP/2KCssWq9WF75XGSXuoALdpC
  # ptEoUNgHBwlv00YtUwRyyuPQ/VGE6Jst9dEN7m4CUJGDgeSm2X8hPkvGcJ+Ns3+C
  # 9LJurJ603fetvDFm80mqIxY3yfGSpL6Oqh3ppXVo/UC62No9a3sfg1/Fhu0G6Uk0
  # bgvRxTgjXFTS7pA5KEqB8d07jxJJF5Z6Xjkz/mHp5zoRLaBE7z2v0uYTXARf91x4
  # shSFSjUapYL2DYpJCWY8u7ROchU9sqiZmZrzZ0OHNZ3TZhvs8LIySecBY5NZO9xt
  # 5Y9WYvB1Ivw875I+DSARshJB+hLW6VIAwIZ+UMcdrv7xgS+lMkgG77H37yS/pZ+8
  # bL+pZb6uFo8OzdFmPWVodw4P/3jA/NxiZJFF81/K/pLFg/TVP8i/vfWzWS50Bx9p
  # yzm3hGUliFocAhDcAipE0rPFko4Gm+TmwMzgE8hGDgFblmEfdlOcLH6zH36YXzQp
  # ATCeavjClaJU8292/64+YWROHVRaNXcLpYIW9pD8a0XRz/prGFdzNdDF52QC/CE2
  # gmaFfo6ggn208ciXLQKvYlaKEZa6m3nmLi6neHBiOla05jL94UXdcpYjI9kuIGxj
  # 60AQaPhVKzAE4Yjh7Zxf5RKxMCHMjw8oT730GXD2TRwnv0Dmx8Ioc6IYoLMF57t3
  # zpjK0m3T8vNuHKr5deMp
  # =8sTO
  # -----END PGP SIGNATURE-----
  ## Source: https://getfedora.org/en/static/checksums/Fedora-Server-30-1.2-x86_64-CHECKSUM

if [[ -z ${1} ]]; then
  echo "This function needs an argument"
  exit 1
fi

}

convertSecs() {
  ((h=${1}/3600))
  ((m=(${1}%3600)/60))
  ((s=${1}%60))
  printf "%02d:%02d:%02d\n" ${h} ${m} ${s}
}

# Check if ponysay is installed. (https://github.com/erkin/ponysay)
say () {
  echo ${1} > /tmp/lastBuild.time
  if [[ $(command -v ponysay) ]]; then
    printf "\n\n\n\n\n"
    ponysay -c ${1}
  else
    echo ${1}
  fi
}

think () {
  if [[ $(command -v ponythink) ]]; then
    printf "\n\n\n\n\n"
    ponythink -c ${1}
  else
    echo ${1}
  fi
}
checkInstaller () {
  /usr/bin/wget -q -O scripts/INSTALL.sh.sfv https://raw.githubusercontent.com/MISP/MISP/2.4/INSTALL/INSTALL.sh.sfv
  rhash_chk=$(cd scripts ; ${RHASH_RUN} -c INSTALL.sh.sfv > /dev/null 2>&1; echo $?)
  for sum in $(echo ${SHA_SUMS} |sed 's/--sha//g'); do
    /usr/bin/wget -q -O scripts/INSTALL.sh.sha${sum} https://raw.githubusercontent.com/MISP/MISP/2.4/INSTALL/INSTALL.sh.sha${sum}
    INSTsum=$(shasum -a ${sum} scripts/INSTALL.sh | cut -f1 -d\ )
    chsum=$(cat scripts/INSTALL.sh.sha${sum} | cut -f1 -d\ )

    if [[ "${chsum}" == "${INSTsum}" ]] && [[ "${rhash_chk}" == "0" ]]; then
      echo "sha${sum} matches"
    else
      echo "sha${sum}: ${chsum} does not match the installer sum of: ${INSTsum}"
      echo "Deleting installer, please run again."
      rm scripts/INSTALL.sh
      exit 1
    fi
  done
}


removeAll () {
  # Remove files for next run
  [[ -d "output-virtualbox-iso" ]] && rm -r output-virtualbox-iso
  [[ -d "output-vmware-iso" ]] && rm -r output-vmware-iso
  [[ -d "VMware" ]] && rm -r VMware
  rm *.zip *.sfv
  rm ${PACKER_NAME}-deploy.json
  rm packer_virtualbox-iso_virtualbox-iso_sha*.sfv.asc
  rm ${PACKER_VM}_${VER}@${LATEST_COMMIT_SHORT}-vmware.zip.asc
  rm /tmp/LICENSE-${PACKER_NAME}
  rm /tmp/vbox.done /tmp/vmware.done
}

# TODO: Make it more graceful if files do not exist
removeAll 2> /dev/null

# Fetching latest MISP LICENSE
/usr/bin/wget -q -O /tmp/LICENSE-${PACKER_NAME} https://raw.githubusercontent.com/MISP/MISP/2.4/LICENSE

# Make sure the installer we run is the one that is currently on GitHub
if [[ -e "scripts/INSTALL.sh" ]]; then
  echo "Checking checksums"
  checkInstaller
else
  /usr/bin/wget -q -O scripts/INSTALL.sh https://raw.githubusercontent.com/MISP/MISP/2.4/INSTALL/INSTALL.sh
  checkInstaller
fi

# Check if latest build is still up to date, if not, roll and deploy new
if [[ "${LATEST_COMMIT}" != "$(cat /tmp/${PACKER_NAME}-latest.sha)" ]]; then
  echo "Current ${PACKER_VM} version is: ${VER}@${LATEST_COMMIT_SHORT}"

  # Search and replace for vm_name and make sure we can easily identify the generated VMs
  cat misp.json| sed "s|\"vm_name\": \"MISP_demo\",|\"vm_name\": \"${PACKER_VM}_${VER}@${LATEST_COMMIT_SHORT}\",|" > misp-deploy.json

  # Build virtualbox VM set
  PACKER_LOG_PATH="${PWD}/packerlog-vbox.txt"
  ($PACKER_RUN build --on-error=cleanup -only=virtualbox-iso misp-deploy.json ; echo $? > /tmp/vbox.done) &

  # Build vmware VM set
  PACKER_LOG_PATH="${PWD}/packerlog-vmware.txt"
  ($PACKER_RUN build --on-error=cleanup -only=vmware-iso misp-deploy.json ; echo $? > /tmp/vmware.done) &

  # The below waits for the above 2 parallel packer builds to finish
  while [[ ! -f /tmp/vmware.done ]]; do :; done
  while [[ ! -f /tmp/vbox.done   ]]; do :; done

  # Prevent uploading only half a build
  if [[ "$(cat /tmp/vbox.done)" == "0" ]] && [[ "$(cat /tmp/vmware.done)" == "0" ]]; then
    # ZIPup all the vmware stuff
    mv output-vmware-iso VMware
    cd VMware
    ${RHASH_RUN} --sfv --sha1 --sha256 --sha384 --sha512 -o ${PACKER_VM}_${VRE}@${LATEST_COMMIT_SHORT}.sfv *
    cd ../
    zip -r ${PACKER_VM}_${VER}@${LATEST_COMMIT_SHORT}-VMware.zip VMware/*

    mv output-virtualbox-iso/${PACKER_VM}_${VER}@${LATEST_COMMIT_SHORT}.ova .

    # Create a hashfile for the zip
    ${RHASH_RUN} --sfv --sha1 --sha256 --sha384 --sha512 -o ${PACKER_VM}_${VER}@${LATEST_COMMIT_SHORT}-CHECKSUM.sfv *.zip *.ova

    # Current file list of everything to gpg sign and transfer
    FILE_LIST="${PACKER_VM}_${VER}@${LATEST_COMMIT_SHORT}-VMware.zip \
               ${PACKER_VM}_${VER}@${LATEST_COMMIT_SHORT}.ova \
               ${PACKER_VM}_${VER}@${LATEST_COMMIT_SHORT}-CHECKSUM.sfv"

    # Create the latest MISP export directory
    if [[ "${REMOTE}" == "1" ]]; then
      ssh ${REL_USER}@${REL_SERVER} "mkdir -p export/${PACKER_VM}_${VER}@${LATEST_COMMIT_SHORT} ; mkdir -p export/${PACKER_VM}_${VER}@${LATEST_COMMIT_SHORT}/checksums"
    fi

    # Sign and transfer files
    for FILE in ${FILE_LIST}; do
      if [[ "$GPG_ENABLED" == "1" ]]; then
        if [[ "$GPG_KEY" == "0x" ]] || [[ -z "$GPG_KEY" ]]; then
          gpg --armor --output ${FILE}.asc --detach-sig ${FILE}
        else
          gpg --armor -u ${GPG_KEY} --output ${FILE}.asc --detach-sig ${FILE}
        fi
        [[ "${REMOTE}" == "1" ]] && rsync -azvq --progress ${FILE}.asc ${REL_USER}@${REL_SERVER}:export/${PACKER_VM}_${VER}@${LATEST_COMMIT_SHORT}
      fi

      if [[ "${REMOTE}" == "1" ]]; then
        rsync -azvq --progress ${FILE} ${REL_USER}@${REL_SERVER}:export/${PACKER_VM}_${VER}@${LATEST_COMMIT_SHORT}
        ssh ${REL_USER}@${REL_SERVER} "rm export/latest ; ln -s ${PACKER_VM}_${VER}@${LATEST_COMMIT_SHORT} export/latest"
      fi
    done

    if [[ "${REMOTE}" == "1" ]]; then
      ssh ${REL_USER}@${REL_SERVER} "chmod -R +r export \
                                     mv export/${PACKER_VM}_${VER}@${LATEST_COMMIT_SHORT}/*.CHECKSUM* export/${PACKER_VM}_${VER}@${LATEST_COMMIT_SHORT}/checksums \
                                     cd export ; tree -T "${PACKER_VM} VM Images" -H https://www.circl.lu/misp-images/ -o index.html"
    fi

  else
    echo "The packer exit code of VMware was: ${VMWARE_BUILD}"
    echo "The packer exit code of VBox   was: ${VIRTUALBOX_BUILD}"
    echo "--------------------------------------------------------------------------------"
    echo "#fail" > /tmp/${PACKER_NAME}-latest.sha
    removeAll 2> /dev/null
    TIME_END=$(date +%s)
    TIME_DELTA=$(expr ${TIME_END} - ${TIME_START})
    TIME=$(convertSecs ${TIME_DELTA})
    echo "The last generation took ${TIME}" |tee /tmp/lastBuild.time
    exit 1
  fi

  # Remove files for next run
  removeAll 2> /dev/null
  echo ${LATEST_COMMIT} > /tmp/${PACKER_NAME}-latest.sha
  TIME_END=$(date +%s)
  TIME_DELTA=$(expr ${TIME_END} - ${TIME_START})
  TIME=$(convertSecs ${TIME_DELTA})

  say "The last generation took ${TIME}"
else
  clear
  think "Current ${PACKER_VM} version ${VER}@${LATEST_COMMIT_SHORT} is up to date."
fi
