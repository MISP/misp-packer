#!/bin/bash

GOT_PACKER=$(which packer > /dev/null 2>&1; echo $?)
if [[ "${GOT_PACKER}" == 0 ]]; then
  echo "Packer detected, version: $(packer -v)"
  PACKER_RUN=$(which packer)
else
  echo "No packer binary detected, please make sure you installed it from: https://www.packer.io/downloads.html"
  exit 1
fi

GOT_RHASH=$(which rhash > /dev/null 2>&1; echo $?)
if [[ "${GOT_RHASH}" == 0 ]]; then
  echo "rhash detected, version: $(rhash --version)"
  RHASH_RUN=$(which rhash)
else
  echo "No rhash binary detected, please make sure you installed it."
  exit 1
fi
