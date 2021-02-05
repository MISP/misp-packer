#!/bin/bash

# Leave empty for NO debug messages, if run with set -x or bash -x it will enable DEBUG by default
DEBUG=

case "$-" in
  *x*)  NO_PROGRESS=1; DEBUG=1 ;;
  *)    NO_PROGRESS=0 ;;
esac

# Name of the packer
PACKER_NAME="misp"
PACKER_VM="MISP"
NAME="${PACKER_NAME}-packer"

# Configure your user and remote server
REMOTE=1
REL_USER="${PACKER_NAME}-release"
REL_SERVER="cpab"

# GPG Sign
GPG_ENABLED=1
GPG_KEY="0x34F20B13"

# Enable debug for packer, omit -debug to disable
##PACKER_DEBUG="-debug"

# Enable logging and debug for packer
export PACKER_LOG=1

REPO="MISP/MISP"
BRANCH="2.4"

# SHAsums to be computed, note the -- notatiation is for ease of use with rhash
SHA_SUMS="--sha1 --sha256 --sha384 --sha512"

NAME_OF_INSTALLER="INSTALL.sh"
PATH_TO_INSTALLER="scripts/${NAME_OF_INSTALLER}"
URL_TO_INSTALLER="https://raw.githubusercontent.com/${REPO}/${BRANCH}/INSTALL/${NAME_OF_INSTALLER}"
URL_TO_LICENSE="https://raw.githubusercontent.com/${REPO}/${BRANCH}/LICENSE"

if [[ ! -z $DEBUG ]]; then
  echo "Debug mode enabled."
  echo "-------------------"
  echo ""
  echo "Some config info:"
  echo "Using: $NAME"
  [[ ! -z $GPG_ENABLED ]] && echo "GnuPG enabled with key $GPG_KEY"
  [[ ! -z $PACKER_LOG ]] && echo "Packer Log enabled."
  [[ ! -z $REMOTE ]] && echo "Remote deploy enabled with connection string: $REL_USER@$REL_SERVER"
fi

