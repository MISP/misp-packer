#! /usr/bin/env bash

mv /tmp/issue /etc/issue
mv /tmp/crontab /etc/cron.d/misp

# package
echo "--- autoremove for apt ---"
apt-get -y autoremove > /dev/null 2>&1

echo "--- Cleaning packages"
apt-get -y clean > /dev/null 2>&1

echo "--- Testing Instance ---"
AUTH_KEY=$(cat /tmp/AUTH_KEY.txt)
cd /var/www/MISP/PyMISP
sudo -H -u www-data sed -i "s/LBelWqKY9SQyG0huZzAMqiEBl6FODxpgRRXMsZFu/${AUTH_KEY}/g" tests/testlive_comprehensive.py
sudo -H -u www-data sed -i 's/http:\/\/localhost:8080/https:\/\/localhost/g' tests/testlive_comprehensive.py
sudo -H -u www-data git clone https://github.com/viper-framework/viper-test-files tests/viper-test-files
/var/www/MISP/venv/bin/python tests/testlive_comprehensive.py 2> /root/tests-output.txt

if [ "$?" != "0" ]; then
##  set smtp=smtp://149.13.33.5 ; cat /tmp/output.txt |mail -s "tests/testlive_comprehensive.py failed on autogen-VM" steve.clement@circl.lu
echo "Damage, terrible terrible damage!!!!" >> /root/tests-output.txt
fi

rm -rf tests/viper-test-files
##rm /tmp/output.txt /tmp/AUTH_KEY.txt

# End Cleaning
echo "VM cleaned and rebooting for automagic reas0ns."
reboot

