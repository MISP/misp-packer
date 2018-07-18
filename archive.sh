#!/usr/bin/env bash

set -x

VERSIONS="2.4.80 2.4.81 2.4.82 2.4.83 2.4.84 2.4.85 2.4.86 2.4.87 2.4.88 2.4.89 2.4.90 2.4.91 2.4.92 2.4.93"
for VERSION in `echo ${VERSIONS}`; do
    LATEST_MISP=`find . -maxdepth 1 -type d -name MISP_v${VERSION}\* | TZ=utc xargs ls -ld --full-time | sort -k 6 |tail -1 |awk '{print $9}'`
    mkdir archive/${VERSION}
    mv ${LATEST_MISP} archive/${VERSION} && \
    echo "Deleting all the others"
    find . -maxdepth 1 -type d -name MISP_v${VERSION}\* -exec rm -rv {} \;
done
