#! /usr/bin/env bash


echo "--- Creating thehive user"
useradd -U -G sudo -m -s /bin/bash thehive
echo -e "thehive1234\nthehive1234" | chpasswd

echo "--- Configuring sudo"
echo "thehive ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/thehive
echo "misp ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/misp
chmod 0440 /etc/sudoers.d/thehive
chmod 0440 /etc/sudoers.d/misp

echo 'APT::ProgressBar::Fancy "0";' > /etc/apt/apt.conf.d/99progressbar
echo 'APT::Use-Pty "0";' >> /etc/apt/apt.conf.d/99progressbar

#préambule on dirait
sudo apt update
sudo apt upgrade -y



# Upgrade to Ubuntu 20.04
echo "--- Upgrading to Ubuntu 20.04"
do-release-upgrade -f DistUpgradeViewNonInteractive

