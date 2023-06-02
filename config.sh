#!/bin/bash

# Laissez vide pour désactiver les messages de débogage. S'il est exécuté avec set -x ou bash -x, il activera le mode DEBUG par défaut.
DEBUG=

case "$-" in
  *x*)  NO_PROGRESS=1; DEBUG=1 ;;
  *)    NO_PROGRESS=0 ;;
esac

# Nom du packer
PACKER_NAME="misp"
PACKER_VM="MISP"
NAME="${PACKER_NAME}-packer"

# Configurez votre utilisateur et serveur distant
REMOTE=1
REL_USER="${PACKER_NAME}-release"
REL_SERVER="cpab"

# GPG Sign
GPG_ENABLED=1
GPG_KEY="0x34F20B13"

# Activer le débogage pour packer, omettre -debug pour le désactiver
##PACKER_DEBUG="-debug"

# Activer l'enregistrement et le débogage pour packer
export PACKER_LOG=1

REPO="MISP/MISP"
BRANCH="2.4"

# SOMmes de contrôle à calculer, notez la notation -- pour faciliter l'utilisation avec rhash
SHA_SUMS="--sha1 --sha256 --sha384 --sha512"

NAME_OF_INSTALLER="INSTALL.sh"
PATH_TO_INSTALLER="scripts/${NAME_OF_INSTALLER}"
URL_TO_INSTALLER="https://raw.githubusercontent.com/${REPO}/${BRANCH}/INSTALL/${NAME_OF_INSTALLER}"
URL_TO_LICENSE="https://raw.githubusercontent.com/${REPO}/${BRANCH}/LICENSE"

UBUNTU_VERSION="20.04"  # Mettez à jour vers Ubuntu 20.04

if [[ ! -z $DEBUG ]]; then
  echo "Mode de débogage activé."
  echo "-------------------"
  echo ""
  echo "Informations de configuration :"
  echo "Utilisation de : $NAME"
  [[ ! -z $GPG_ENABLED ]] && echo "GnuPG activé avec la clé $GPG_KEY"
  [[ ! -z $PACKER_LOG ]] && echo "Enregistrement Packer activé."
  [[ ! -z $REMOTE ]] && echo "Déploiement distant activé avec la chaîne de connexion : $REL_USER@$REL_SERVER"
fi
