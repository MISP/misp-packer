#! /usr/bin/env bash

cp /tmp/issue /etc/issue

# package
echo "--- autoremove for apt ---"
apt-get -y autoremove > /dev/null 2>&1

echo "--- Cleaning packages"
apt-get -y clean > /dev/null 2>&1

# End Cleaning
echo "VM cleaned"

