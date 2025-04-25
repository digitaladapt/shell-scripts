#!/usr/bin/env bash

echo "----- APT Update ------------------------------------"
sudo apt update -y

echo ""
echo "----- APT Upgrade -----------------------------------"
sudo apt upgrade -y

echo ""
echo "----- APT DistUpgrade -------------------------------"
sudo apt dist-upgrade -y

echo ""
echo "----- APT AutoRemove --------------------------------"
sudo apt autoremove -y

echo ""
echo "----- APT AutoClean ---------------------------------"
sudo apt autoclean -y

