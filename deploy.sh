#!/usr/bin/env bash

# Timing creation
TIME_START=$(date +%s)

# Latest version of misp
VER=$(curl -s https://api.github.com/repos/MISP/MISP/tags  |jq -r '.[0] | .name')
# Latest commit hash of misp
LATEST_COMMIT=$(curl -s https://api.github.com/repos/MISP/MISP/commits  |jq -r '.[0] | .sha')
LATEST_COMMIT_SHORT=$(echo $LATEST_COMMIT|cut -c1-7)

if [ "${VER}" == "" ] || [ "${LATEST_COMMIT}" == "" ] ; then
  echo "Somehow, could not 'curl' either a version or a commit tag, exiting -1..."
  exit -1
fi

# SHAsums to be computed
SHA_SUMS="1 256 384 512"

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
GPG_ENABLED=0
GPG_KEY="0x9BE4AEE9"

# Enable debug for packer, omit -debug to disable
##PACKER_DEBUG="-debug"

# Enable logging for packer
export PACKER_LOG=0

# Make sure we have a current work directory
PWD=`pwd`

# Make sure log dir exists (-p quiets if exists)
mkdir -p ${PWD}/log

vm_description='MISP, is an open source software solution for collecting, storing, distributing and sharing cyber security indicators and threat about cyber security incidents analysis and malware analysis. MISP is designed by and for incident analysts, security and ICT professionals or malware reverser to support their day-to-day operations to share structured informations efficiently.'
vm_version='2.4'

# Place holder, this fn() should be used to anything signing related
function signify()
{
if [ -z "$1" ]; then
  echo "This function needs an argument"
  exit 1
fi

}

# Check if ponysay is installed. (https://github.com/erkin/ponysay)
say () {
  if [[ $(command -v ponysay) ]]; then
    printf "\n\n\n\n\n"
    ponysay -c $1
  else
    echo $1
  fi
}

think () {
  if [[ $(command -v ponythink) ]]; then
    printf "\n\n\n\n\n"
    ponythink -c $1
  else
    echo $1
  fi
}

function removeAll()
{
  # Remove files for next run
  rm -r output-virtualbox-iso
  rm -r output-vmware-iso
  rm *.checksum *.zip *.sha*
  rm ${PACKER_NAME}-deploy.json
  rm packer_virtualbox-iso_virtualbox-iso_sha1.checksum.asc
  rm packer_virtualbox-iso_virtualbox-iso_sha256.checksum.asc
  rm packer_virtualbox-iso_virtualbox-iso_sha384.checksum.asc
  rm packer_virtualbox-iso_virtualbox-iso_sha512.checksum.asc
  rm ${PACKER_VM}_${VER}@${LATEST_COMMIT}-vmware.zip.asc
  rm /tmp/LICENSE-${PACKER_NAME}
}

# TODO: Make it more graceful if files do not exist
removeAll 2> /dev/null

# Fetching latest MISP LICENSE
/usr/bin/wget -q -O /tmp/LICENSE-${PACKER_NAME} https://raw.githubusercontent.com/MISP/MISP/2.4/LICENSE

# Check if latest build is still up to date, if not, roll and deploy new
if [ "${LATEST_COMMIT}" != "$(cat /tmp/misp-latest.sha)" ]; then

  echo "Current ${PACKER_VM} version is: ${VER}@${LATEST_COMMIT}"

  # Search and replace for vm_name and make sure we can easily identify the generated VMs
  cat misp.json| sed "s|\"vm_name\": \"MISP_demo\",|\"vm_name\": \"${PACKER_VM}_${VER}@${LATEST_COMMIT}\",|" > misp-deploy.json

  # Build vmware VM set
  PACKER_LOG_PATH="${PWD}/packerlog-vmware.txt"
  /usr/local/bin/packer build --on-error=ask -only=vmware-iso misp-deploy.json && VMWARE_BUILD="0" &

  sleep 300

  # Build virtualbox VM set
  PACKER_LOG_PATH="${PWD}/packerlog-vbox.txt"
  /usr/local/bin/packer build  --on-error=ask -only=virtualbox-iso misp-deploy.json && VIRTUALBOX_BUILD="0"

  # Prevent uploading only half a build
  if [[ "$VMWARE_BUILD" == "0" ]] && [[ "VIRTUALBOX_BUILD" == "0" ]]; then
    # ZIPup all the vmware stuff
    zip -r ${PACKER_VM}_${VER}@${LATEST_COMMIT}-vmware.zip  packer_vmware-iso_vmware-iso_sha1.checksum packer_vmware-iso_vmware-iso_sha512.checksum output-vmware-iso

    # Create a hashfile for the zip
    for SUMsize in `echo ${SHA_SUMS}`; do
      shasum -a ${SUMsize} *.zip > ${PACKER_VM}_${VER}@${LATEST_COMMIT}-vmware.zip.sha${SUMsize}
    done


    # Current file list of everything to gpg sign and transfer
    FILE_LIST="${PACKER_VM}_${VER}@${LATEST_COMMIT}-vmware.zip output-virtualbox-iso/${PACKER_VM}_${VER}@${LATEST_COMMIT}.ova packer_virtualbox-iso_virtualbox-iso_sha1.checksum packer_virtualbox-iso_virtualbox-iso_sha256.checksum packer_virtualbox-iso_virtualbox-iso_sha384.checksum packer_virtualbox-iso_virtualbox-iso_sha512.checksum ${PACKER_VM}_${VER}@${LATEST_COMMIT}-vmware.zip.sha1 ${PACKER_VM}_${VER}@${LATEST_COMMIT}-vmware.zip.sha256 ${PACKER_VM}_${VER}@${LATEST_COMMIT}-vmware.zip.sha384 ${PACKER_VM}_${VER}@${LATEST_COMMIT}-vmware.zip.sha512"

    # Create the latest MISP export directory
    ssh ${REL_USER}@${REL_SERVER} mkdir -p export/${PACKER_VM}_${VER}@${LATEST_COMMIT}
    ssh ${REL_USER}@${REL_SERVER} mkdir -p export/${PACKER_VM}_${VER}@${LATEST_COMMIT}/checksums

    # Sign and transfer files
    for FILE in ${FILE_LIST}; do
      gpg --armor --output ${FILE}.asc --detach-sig ${FILE}
      rsync -azvq --progress ${FILE} ${REL_USER}@${REL_SERVER}:export/${PACKER_VM}_${VER}@${LATEST_COMMIT}
      rsync -azvq --progress ${FILE}.asc ${REL_USER}@${REL_SERVER}:export/${PACKER_VM}_${VER}@${LATEST_COMMIT}
      ssh ${REL_USER}@${REL_SERVER} rm export/latest
      ssh ${REL_USER}@${REL_SERVER} ln -s ${PACKER_VM}_${VER}@${LATEST_COMMIT} export/latest
    done
    ssh ${REL_USER}@${REL_SERVER} chmod -R +r export
    ssh ${REL_USER}@${REL_SERVER} mv export/${PACKER_VM}_${VER}@${LATEST_COMMIT}/*.checksum* export/${PACKER_VM}_${VER}@${LATEST_COMMIT}/checksums
    ssh ${REL_USER}@${REL_SERVER} mv export/${PACKER_VM}_${VER}@${LATEST_COMMIT}/*-vmware.zip.sha* export/${PACKER_VM}_${VER}@${LATEST_COMMIT}/checksums

    ssh ${REL_USER}@${REL_SERVER} cd export ; tree -T "${PACKER_VM} VM Images" -H https://www.circl.lu/misp-images/ -o index.html
  else
    echo "The build status of VMware was: ${VMWARE_BUILD}"
    echo "The build status of VBox   was: ${VIRTUALBOX_BUILD}"
  fi

  # Remove files for next run
  removeAll 2> /dev/null
  echo ${LATEST_COMMIT} > /tmp/misp-latest.sha
  TIME_END=$(date +%s)
  TIME_DELTA=$(expr ${TIME_END} - ${TIME_START})

  say "The generation took ${TIME_DELTA} seconds"
else
  clear
  think "Current ${PACKER_VM} version ${VER}@${LATEST_COMMIT_SHORT} is up to date."
fi
