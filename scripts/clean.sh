#!/usr/bin/env bash

mv /tmp/issue /etc/issue
mv /tmp/crontab /etc/cron.d/misp

# package
echo "--- autoremove for apt ---"
apt autoremove -qqy

echo "--- Cleaning packages"
apt clean -qqy

# Pass postfix configuration
echo "postfix postfix/mailname string localhost.localdomain" | debconf-set-selections
echo "postfix postfix/main_mailer_type string 'No configuration'" | debconf-set-selections
apt install mailutils -qqy

echo "--- Testing Instance ---"
cd /var/www/MISP/PyMISP
/var/www/MISP/venv/bin/python tests/testlive_comprehensive.py 2> /tmp/tests-output.txt

if [ "$?" != "0" ]; then
  echo "Damage, terrible terrible damage!!!!" >> /tmp/tests-output.txt
  set smtp=smtp://149.13.33.5 ; cat /tmp/tests-output.txt |mail -s "tests/testlive_comprehensive.py failed on autogen-VM" steve.clement@circl.lu
fi

rm -rf tests/viper-test-files

# End Cleaning
echo "VM cleaned and rebooting for automagic reas0ns."
reboot
