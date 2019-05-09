#! /usr/bin/env bash

##echo "--- Creating thehive user"
##useradd -U -G sudo -m -s /bin/bash  thehive
##echo -e "thehive1234\nthehive1234" | passwd  thehive

echo "--- Configuring sudo "
##echo %thehive ALL=NOPASSWD:ALL > /etc/sudoers.d/thehive
echo "%misp ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/misp
##chmod 0440 /etc/sudoers.d/thehive
chmod 0440 /etc/sudoers.d/misp
