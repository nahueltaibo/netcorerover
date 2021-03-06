#!/bin/bash

#-----------------------------------------------------------------------
# CONFIGURATION
DOTNET_VERSION=2.2.207
DOTNET_INSTALLER=dotnet-sdk-2.2.207-linux-arm.tar.gz
DOTNET_INSTALLER_URL=https://download.visualstudio.microsoft.com/download/pr/fca1c415-b70c-4134-8844-ea947f410aad/901a86c12be90a67ec37cd0cc59d5070/dotnet-sdk-2.2.207-linux-arm.tar.gz
DOTNET_LOCATION=$HOME/dotnet
#-----------------------------------------------------------------------

clear

red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
reset=`tput sgr0`

# exit when any command fails
set -e
# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG

# Adds goto capabilities
function goto
{
    label=$1
    cmd=$(sed -n "/$label:/{:a;n;p;ba};" $0 | grep -v ':$')
    eval "$cmd"
    exit
}

echo "${green}**** NetCoreRover Environment Installer ****${reset}"

: update:
echo
echo "${green}Updating Raspberry Pi...${reset}"
sudo apt-get update

: upgrade:
echo
echo "${green}Upgrading Raspberry Pi...${reset}"
sudo apt-get upgrade -y

echo
echo "${green}Upgrading Raspberry Pi distro...${reset}"
sudo apt-get dist-upgrade -y

: dotnet:
echo
echo "${green}Installing required dependencies...${reset}"
sudo apt-get install curl libunwind8 gettext

# Download dotnet only if needed...
if [ -f "$DOTNET_INSTALLER" ]; then
    echo
    echo "${green}netcore installer already exist.${reset}"
else 
    echo
    echo "${green}Downloading netcore installer...${reset}"
    wget "$DOTNET_INSTALLER_URL"
fi

# if dotnet is already installed, remove it first
if [ -d "$DOTNET_LOCATION" ]; then
    echo "${yellow}netcore already installed, avoiding installation.${reset}"
else
    mkdir -p "$DOTNET_LOCATION"

    echo
    echo "${green}Extracting netcore to $DOTNET_LOCATION...${reset}"
    tar zxf "$DOTNET_INSTALLER" -C "$DOTNET_LOCATION"
fi

#echo
#echo "${green}removing dotnet installer...${reset}"
#rm "$DOTNET_INSTALLER"

echo
echo "${green}Configuring Environment variables...${reset}"
export DOTNET_ROOT=$HOME/dotnet 
export PATH=$PATH:$HOME/dotnet

if grep -q "$DOTNET_LOCATION" "$HOME/.bashrc"; then
    # bashrc already contains what we need so we dont need to add it again
    echo dotnet already in PATH environment variable
else
    # bashrc does not contain PATH configuration add it with dotnet path
    echo Adding PATH configuration...
    echo -e "\nPATH=\$PATH:$DOTNET_LOCATION" >> ~/.bashrc
fi  

# Check if dotnet was correctly installed
echo 
echo dotnet version:
if dotnet --version | grep $DOTNET_VERSION; then
    echo
    echo "${green}dotnet is correctly installed${reset}"
else
    echo
    echo "${red}there was an error installing dotnet version $DOTNET_VERSION${reset}"
    goto end
fi

: mosquitto:
echo
echo "${green}Installing mosquitto${reset}"
sudo apt install mosquitto mosquitto-clients -y
sudo systemctl enable mosquitto

if sudo systemctl status mosquitto | grep 'active (running)'; then
    echo
    echo "${green}mosquitto is now running${reset}"
else
    echo
    echo "${red}there was an error installing or starting mosquitto${reset}"
    goto end
fi

echo
echo "${yellow}Remember to enable SSH to publish!${reset}"

: end:
