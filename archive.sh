#!/usr/bin/env bash

##set -x

cd /home/misp-release/export

# (－‸ლ)
VERSIONS="2.4.80 2.4.81 2.4.82 2.4.83 2.4.84 2.4.85 2.4.86 2.4.87 2.4.88 2.4.89 2.4.90 2.4.91 2.4.92 2.4.93 2.4.95 2.4.96 2.4.97 2.4.98 2.4.99 2.4.100 2.4.101 2.4.102 2.4.103 2.4.104 2.4.105 2.4.106 2.4.107 2.4.108 2.4.109 2.4.110 2.4.111 2.4.113 2.4.114 2.4.115 2.4.116 2.4.117 2.4.118 2.4.119 2.4.120 2.4.121 2.4.122 2.4.123"
for VERSION in `echo ${VERSIONS}`; do
    LATEST_MISP=`find . -maxdepth 1 -type d -name MISP_v${VERSION}\* | TZ=utc xargs ls -ld --full-time | sort -k 6 |tail -1 |awk '{print $9}'`
    mkdir -p archive/${VERSION}
    if [[ ! ${LATEST_MISP} == "." ]]; then
      mv ${LATEST_MISP} archive/${VERSION} && \
      echo "Deleting all the others"
    fi
    find . -maxdepth 1 -type d -name MISP_v${VERSION}\* -exec rm -rv {} \;
done

