#!/usr/bin/env bash

# Bash 5.0 new variables:
## EPOCHSECONDS (epoch time)
## EPOCHREALTIME (epoch float)
## BASH_ARGV0 (investigate)
## build-in wait (bash -f investigate)

# Timing creation
TIME_START=$(date +%s)

# Please adjust config.sh accordingly
source config.sh

### ---- NO TOUCHY BEYOND THIS POINT, PLEASE --- ###

source checkDeps.sh

# Latest version of misp
VER=$(curl -s https://api.github.com/repos/${REPO}/tags  |jq -r '.[0] | .name')
# Latest commit hash of misp
LATEST_COMMIT=$(curl -s https://api.github.com/repos/${REPO}/commits  |jq -r '.[0] | .sha')
LATEST_COMMIT_SHORT=$(echo ${LATEST_COMMIT} |cut -c1-7)

if [[ "${VER}" == "" ]] || [[ "${LATEST_COMMIT}" == "" ]] ; then
  echo "Somehow, could not 'curl' either a version or a commit tag, exiting -1..."
  exit -1
fi

# Update time-stamp and make sure file exists
touch /tmp/${PACKER_NAME}-latest.sha

# Make sure we have a current work directory
PWD=`pwd`

# Make sure log dir exists (-p quiets if exists)
mkdir -p ${PWD}/log


# Place holder
checkBin ()
{
  echo "NOOP"
}

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
  # 9LJurJ603fet.

