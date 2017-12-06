#!/usr/bin/env bash

# Latest version of misp
VER=$(curl -s https://api.github.com/repos/MISP/MISP/tags  |jq -r '.[0] | .name')
# Latest commit hash of misp
LATEST_COMMIT=$(curl -s https://api.github.com/repos/MISP/MISP/commits  |jq -r '.[0] | .sha')
# Update time-stamp and make sure file exists
touch /tmp/misp-latest.sha
# SHAsums to be computed
SHA_SUMS="1 256 384 512"

# Configure your user and remote server
REL_USER="misp-release"
REL_SERVER="cpab"

# Place holder, this fn() should be used to anything signing related
function signify()
{
if [ -z "$1" ]; then
  echo "This function needs an arguments"
  exit 1
fi

}

# Check if latest build is still up to date, if not, roll and deploy new
if [ "${LATEST_COMMIT}" != "$(cat /tmp/misp-latest.sha)" ]; then

  echo "Current MISP version is: ${VER}@${LATEST_COMMIT}"

  # Search and replace for vm_name and make sure we can easily identify the generated VMs
  cat misp.json| sed "s|\"vm_name\": \"MISP_demo\",|\"vm_name\": \"MISP_${VER}@${LATEST_COMMIT}\",|" > misp-deploy.json

  # Build vmware VM set
  /usr/local/bin/packer build -only=vmware-iso misp-deploy.json

  # Build virtualbox VM set
  /usr/local/bin/packer build -only=virtualbox-iso misp-deploy.json

  # ZIPup all the vmware stuff
  zip -r MISP_${VER}@${LATEST_COMMIT}-vmware.zip  packer_vmware-iso_vmware-iso_sha1.checksum packer_vmware-iso_vmware-iso_sha512.checksum output-vmware-iso

  # Create a hashfile for the zip
  for SUMsize in `echo ${SHA_SUMS}`; do
    shasum -a ${SUMsize} *.zip > MISP_${VER}@${LATEST_COMMIT}-vmware.zip.sha${SUMsize}
  done


  # Current file list of everything to gpg sign and transfer
  FILE_LIST="MISP_${VER}@${LATEST_COMMIT}-vmware.zip output-virtualbox-iso/MISP_${VER}@${LATEST_COMMIT}.ova packer_virtualbox-iso_virtualbox-iso_sha1.checksum packer_virtualbox-iso_virtualbox-iso_sha256.checksum packer_virtualbox-iso_virtualbox-iso_sha384.checksum packer_virtualbox-iso_virtualbox-iso_sha512.checksum MISP_${VER}@${LATEST_COMMIT}-vmware.zip.sha1 MISP_${VER}@${LATEST_COMMIT}-vmware.zip.sha256 MISP_${VER}@${LATEST_COMMIT}-vmware.zip.sha384 MISP_${VER}@${LATEST_COMMIT}-vmware.zip.sha512"

  # Create the latest MISP export directory
  ssh ${REL_USER}@${REL_SERVER} mkdir -p export/MISP_${VER}@${LATEST_COMMIT}

  # Sign and transfer files
  for FILE in ${FILE_LIST}; do
    gpg --armor --output ${FILE}.asc --detach-sig ${FILE}
    rsync -azv --progress ${FILE} ${REL_USER}@${REL_SERVER}:export/MISP_${VER}@${LATEST_COMMIT}
    rsync -azv --progress ${FILE}.asc ${REL_USER}@${REL_SERVER}:export/MISP_${VER}@${LATEST_COMMIT}
    ssh ${REL_USER}@${REL_SERVER} rm export/latest
    ssh ${REL_USER}@${REL_SERVER} ln -s MISP_${VER}@${LATEST_COMMIT} export/latest
    ssh ${REL_USER}@${REL_SERVER} chmod -R +r export
  done

  # Remove files for next run
  rm -r output-virtualbox-iso
  rm -r output-vmware-iso
  rm *.checksum *.zip *.sha*
  rm misp-deploy.json
  rm packer_virtualbox-iso_virtualbox-iso_sha1.checksum.asc
  rm packer_virtualbox-iso_virtualbox-iso_sha256.checksum.asc
  rm packer_virtualbox-iso_virtualbox-iso_sha384.checksum.asc
  rm packer_virtualbox-iso_virtualbox-iso_sha512.checksum.asc
  rm MISP_${VER}@${LATEST_COMMIT}-vmware.zip.asc
  echo ${LATEST_COMMIT} > /tmp/misp-latest.sha
else
  echo "Current MISP version ${VER}@${LATEST_COMMIT} is up to date."
fi
