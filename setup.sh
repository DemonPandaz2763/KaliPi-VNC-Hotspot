#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/install_log.txt"

##########################################
# --> Colors <--
##########################################
red='\e[0;31m'
green='\e[0;32m'
yellow='\e[0;33m'
reset='\e[0m'

##########################################
# --> New Configurations <--
##########################################
NEW_HOSTAPD_CONF="$SCRIPT_DIR/conf/hostapd.conf"
NEW_UDHCPD_CONF="$SCRIPT_DIR/conf/udhcpd.conf"

NEW_HOTSPOT_SERVICE="$SCRIPT_DIR/service/hotspot.service"
NEW_VNC_SERVICE="$SCRIPT_DIR/service/vncserver.service"

NEW_START_AP="$SCRIPT_DIR/bin/start_ap.sh"

##########################################
# --> Target directories <--
##########################################
TARGET_HOSTAPD_CONF="/etc/hostapd/hostapd.conf"
TARGET_UDHCPD_CONF="/etc/udhcpd.conf"

TARGET_HOTSPOT_SERVICE="/etc/systemd/system/hotspot.service"
TARGET_UDHCPD_SERVICE="/etc/systemd/system/udhcpd.service"
TARGET_VNC_SERVICE="/etc/systemd/system/vncserver.service"

TARGET_START_AP="/usr/local/bin/start_ap.sh"

##########################################
# --> Log function <--
##########################################
log_message() {
    if [[ "$1" == "[+]"*]]; then
        echo -e "$1"
        echo -e "$1" >> "$LOG_FILE"
        logger -t hotspot-install "$1"

    else
        echo -e "$1" >> "$LOG_FILE"
        logger -t hotspot-install "$1"
    fi
}

##########################################
# --> Check for root <--
##########################################
if [[ $EUID -ne 0 ]]; then
  log_message "This script must be run as root."
  echo -e "${red}[!]${reset} This script must be run as root"
  exit 1
fi

##########################################
# --> Check for Kali on the Raspberry Pi 4 <--
##########################################
echo -en "${yellow}[?]${reset} Are you using Kali on the Raspberry Pi 4? [y/n]: "
read ans1

if [[ $ans1 != "y" ]]; then
  log_message "This script is for Kali on the Raspberry Pi 4. Exiting."
  echo -e "${red}[!]${reset} This script is for Kali on the Raspberry Pi 4"
  exit 1
fi

##########################################
# --> Check for hdmi and resolution <--
##########################################
echo -en "${yellow}[?]${reset} Have you modified the /boot/config.txt file (reboot required)? [y/n]: "
read ans2

if [[ $ans2 != "y" ]]; then
  log_message "User has not modified /boot/config.txt. Exiting."
  echo -e "${red}[!]${reset} Please modify the /boot/config.txt file and reboot before running this script (hdmi and resolution)"
  exit 1
fi

##########################################
# --> Check for wlan1 <--
##########################################
echo -en "${yellow}[?]${reset} Do you have a second interface (wlan1) [y/n]: "
read ans3

if [[ $ans3 != "y" ]]; then
  log_message "Second interface wlan1 not found. Exiting."
  echo -e "${red}[!]${reset} Second interface (wlan1) required"
  exit 1
fi

##########################################
# --> Install hostapd and dnsmasq <--
##########################################
log_message "Installing updates and dependencies"
echo -e "\n  ${green}Installing updates and dependencies${reset}"
echo -e "=========================================\n"

if ! sudo apt update > /dev/null 2>&1; then
  log_message "Failed to update package list."
  echo -e "${red}[!]${reset} Failed to update package list"
  exit 1
fi

if ! sudo apt install hostapd udhcpd x11vnc -y > /dev/null 2>&1; then
  log_message "Failed to install required packages."
  echo -e "${red}[!]${reset} Failed to install required packages"
  exit 1
fi

##########################################
# --> Hotspot service <--
##########################################
log_message "Configuring start_ap.sh"
echo -e "\n  ${green}Configuring start_ap.sh${reset}"
echo -e "=========================================\n"

if ! sudo cp "$NEW_START_AP" "$TARGET_START_AP"; then
  log_message "Failed to copy start_ap.sh to target directory."
  echo -e "${red}[!]${reset} Failed to copy start_ap.sh"
  exit 1
fi

if ! sudo cp "$NEW_HOTSPOT_SERVICE" "$TARGET_HOTSPOT_SERVICE"; then
  log_message "Failed to copy hotspot.service to target directory."
  echo -e "${red}[!]${reset} Failed to copy hotspot.service"
  exit 1
fi

sudo chmod +x "$TARGET_START_AP"
sudo systemctl enable hotspot.service > /dev/null 2>&1

log_message " [+] Made ap file: $TARGET_START_AP"
log_message " [+] Made service file: $TARGET_HOTSPOT_SERVICE"
log_message " [+] Enabled service: hotspot.service"

##########################################
# --> Hostapd configuration <--
##########################################
log_message "Configuring hostapd"
echo -e "\n  ${green}Configuring hostapd"
echo -e "  Hotspot SSID: RPiHotspot"
echo -e "  Hotspot Password: 1234567890${reset}"
echo -e "=========================================\n"

if ! sudo systemctl unmask hostapd > /dev/null 2>&1; then
  log_message "Failed to unmask hostapd"
  echo -e "${red}[!]${reset} Failed to unmask hostapd"
  exit 1
fi

if ! sudo cp "$NEW_HOSTAPD_CONF" "$TARGET_HOSTAPD_CONF"; then
  log_message "Failed to copy hostapd.conf to target directory"
  echo -e "${red}[!]${reset} Failed to copy hostapd.conf"
  exit 1
fi

echo -e "DAEMON_CONF=\"/etc/hostapd/hostapd.conf\"" | sudo tee -a /etc/default/hostapd > /dev/null 2>&1

if ! sudo systemctl enable hostapd > /dev/null 2>&1; then
  log_message "Failed to enable hostapd service"
  echo -e "${red}[!]${reset} Failed to enable hostapd"
  exit 1
fi

log_message " [+] Made config file: $TARGET_HOSTAPD_CONF"
log_message " [+] Enabled service: hostapd"

##########################################
# --> Udhcpd configuration <--
##########################################
log_message "Configuring udhcpd"
echo -e "\n  ${green}Configuring udhcpd${reset}"
echo -e "=========================================\n"

if ! sudo cp "$NEW_UDHCPD_CONF" "$TARGET_UDHCPD_CONF"; then
  log_message "Failed to copy udhcpd.conf to target directory"
  echo -e "${red}[!]${reset} Failed to copy udhcpd.conf"
  exit 1
fi

if ! sudo systemctl enable udhcpd > /dev/null 2>&1; then
  log_message "Failed to enable udhcpd service"
  echo -e "${red}[!]${reset} Failed to enable udhcpd"
  exit 1
fi

log_message " [+] Made config file: $TARGET_UDHCPD_CONF"
log_message " [+] Enabled service: udhcpd"

##########################################
# --> Configure x11vnc <--
##########################################
log_message "Configuring x11vnc"
echo -e "\n  ${green}Configuring x11vnc${reset}"
echo -e "=========================================\n"

if ! sudo cp "$NEW_VNC_SERVICE" "$TARGET_VNC_SERVICE"; then
  log_message "Failed to copy vncserver.service to target directory"
  echo -e "${red}[!]${reset} Failed to copy vncserver.service"
  exit 1
fi

if ! sudo systemctl enable vncserver > /dev/null 2>&1; then
  log_message "Failed to enable vncserver service"
  echo -e "${red}[!]${reset} Failed to enable vncserver"
  exit 1
fi

log_message " [+] Made service file: $TARGET_VNC_SERVICE"
log_message " [+] Enabled service: vncserver"

##########################################
# --> Reboot <--
##########################################
echo -en "\n${yellow}[?]${reset} Reboot now (read output for password)? [y/n]: "
read ans4

if [[ $ans4 == "y" ]]; then
  sudo reboot
else
  log_message "User opted not to reboot"
  echo -e "${red}[!]${reset} Reboot to start the hotspot"
fi

exit 0
