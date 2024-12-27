# KaliPi Hotspot Setup Script

This script automates the process of setting up a fresh KaliPi installation as a Wi-Fi hotspot. It installs and configures the required software (`hostapd`, `udhcpd`, `x11vnc`), sets up default configurations, and ensures services are started automatically at boot.

## Features

- **Software Installation**: Installs `hostapd`, `udhcpd`, and `x11vnc`.
- **Hotspot Configuration**:
  - SSID: `RPiHotspot`
  - Password: `1234567890`
  - Wi-Fi Channel: 6
  - WPA2 encryption
- **DHCP Server Configuration**:
  - IP Range: `192.168.4.0/24`
  - AP IP: `192.168.4.1`
- **Startup Script**: Adds a custom bash script to `/usr/local/bin` that starts the services automatically at boot if the `wlan1` interface is connected.
- **Install Process**: `setup.sh` will copy all required files into place with root.

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/kali-hotspot-setup.git
   cd kali-hotspot-setup
   sudo ./setup.sh

## Notes

This script was tested using the following hardware on a fresh install of Kali Linux.
 - **Pi Model**: Raspberry Pi 4 Model B
 - **wlan0**: Onboard wifi chip
 - **wlan1**: Alfa awus1900 wifi adapter (rtl8814au)
 - **Fan**: I don't think this matters.