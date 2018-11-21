#! /usr/bin/env bash

mv /tmp/issue /etc/issue
mv /tmp/crontab /etc/cron.d/misp

# package
echo "--- autoremove for apt ---"
apt-get -y autoremove > /dev/null 2>&1

echo "--- Cleaning packages"
apt-get -y clean > /dev/null 2>&1

# End Cleaning
echo "VM cleaned and rebooting for automagic reas0ns."
reboot

