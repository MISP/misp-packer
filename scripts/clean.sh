#! /usr/bin/env bash

mv /tmp/issue /etc/issue
mv /tmp/crontab /etc/cron.d/misp

# package
echo "--- autoremove for apt ---"
apt-get -y autoremove > /dev/null 2>&1

echo "--- Cleaning packages"
apt-get -y clean > /dev/null 2>&1

echo "--- Testing Instance ---"
cd /var/www/MISP/PyMISP
/var/www/MISP/venv/bin/python tests/testlive_comprehensive.py 2> /tmp/tests-output.txt

if [ "$?" != "0" ]; then
##  set smtp=smtp://149.13.33.5 ; cat /tmp/output.txt |mail -s "tests/testlive_comprehensive.py failed on autogen-VM" steve.clement@circl.lu
echo "Damage, terrible terrible damage!!!!" >> /tmp/tests-output.txt
fi

rm -rf tests/viper-test-files
##rm /tmp/output.txt

# End Cleaning
echo "VM cleaned and rebooting for automagic reas0ns."
reboot
