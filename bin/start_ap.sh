#!/bin/bash
# Check if wlan1 is up
if iwconfig | grep wlan1; then
    echo "wlan1 is UP. Starting services..."
    
    # Bring up wlan1 with a static IP
    sudo ifconfig wlan1 192.168.4.1 up
    
    # Start hostapd and udhcpd
    sudo systemctl start hostapd
    sudo systemctl start udhcpd
else
    echo "wlan1 is DOWN. Stopping services..."
    
    # Stop hostapd and udhcpd
    sudo systemctl stop hostapd
    sudo systemctl stop udhcpd
fi
