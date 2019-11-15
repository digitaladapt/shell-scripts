#!/bin/bash

echo "----- APT Update ------------------------------------"
sudo apt update

echo ""
echo "----- APT Upgrade -----------------------------------"
sudo apt upgrade

echo ""
echo "----- APT DistUpgrade -------------------------------"
sudo apt dist-upgrade

echo ""
echo "----- APT AutoRemove --------------------------------"
sudo apt autoremove

echo ""
echo "----- APT AutoClean ---------------------------------"
sudo apt autoclean

