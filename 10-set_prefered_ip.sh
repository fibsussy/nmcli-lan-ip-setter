#!/bin/bash

set -x  # Enable verbose logging

INTERFACE=$1
ACTION=$2
CONNECTION_ID=$3

# Set D-Bus environment for Wayland
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
fi

# Log dispatcher details
echo "$(date): Dispatcher triggered: INTERFACE=$INTERFACE, ACTION=$ACTION, CONNECTION_ID=$CONNECTION_ID" >> /var/log/set_prefered_ip.log

# Skip loopback interface
if [ "$INTERFACE" = "lo" ]; then
    echo "$(date): Skipped: Loopback interface (lo)" >> /var/log/set_prefered_ip.log
    exit 0
fi

# Derive CONNECTION_ID if empty
if [ -z "$CONNECTION_ID" ] && [ -n "$INTERFACE" ]; then
    CONNECTION_ID=$(nmcli -t -f NAME,DEVICE con show --active | grep ":$INTERFACE$" | cut -d: -f1)
    echo "$(date): Derived CONNECTION_ID=$CONNECTION_ID for INTERFACE=$INTERFACE" >> /var/log/set_prefered_ip.log
fi

# Check dependencies
command -v nmcli >/dev/null 2>&1 || { echo "NetworkManager not installed"; exit 1; }
command -v arping >/dev/null 2>&1 || { echo "arping not installed"; exit 1; }
command -v ping >/dev/null 2>&1 || { echo "ping (iputils) not installed"; exit 1; }

# Run for non-loopback connections on up or connectivity-change
if [ -n "$CONNECTION_ID" ] && { [ "$ACTION" = "up" ] || [ "$ACTION" = "connectivity-change" ]; }; then
    # Validate connection
    nmcli con show "$CONNECTION_ID" >/dev/null 2>&1 || { echo "Connection '$CONNECTION_ID' not found"; exit 1; }

    # Wait for interface to be up
    for i in {1..5}; do
        if ip link show "$INTERFACE" | grep -q "state UP"; then
            break
        fi
        echo "Waiting for $INTERFACE to be up ($i/5)..."
        sleep 1
    done

    # Get network info
    BASE_IP="192.168.1"
    SUBNET_MASK="24"
    GATEWAY="192.168.1.1"
    NET_INFO=$(ip -4 addr show "$INTERFACE" | grep inet | awk '{print $2}' | head -n1)
    if [ -n "$NET_INFO" ]; then
        BASE_IP=$(echo "$NET_INFO" | cut -d. -f1-3)
        SUBNET_MASK=$(echo "$NET_INFO" | cut -d/ -f2)
        GATEWAY=$(ip route | grep default | grep "$INTERFACE" | awk '{print $3}' | head -n1 || echo "$BASE_IP.1")
    fi

    echo "Warning: Ensure IPs $BASE_IP.69 to $BASE_IP.100 are outside DHCP range to avoid conflicts."

    # Get current IP
    CURRENT_IP=$(nmcli -t -f ipv4.addresses con show "$CONNECTION_ID" | cut -d: -f2 | cut -d/ -f1)

    # Find desired IP
    START=69
    END=100
    DESIRED_IP=""
    for i in $(seq $START $END); do
        IP="$BASE_IP.$i"
        if [ "$IP" = "$CURRENT_IP" ]; then
            DESIRED_IP="$IP"
            break
        fi
        if ip link show "$INTERFACE" | grep -q "state UP"; then
            if ! arping -c 1 -w 1 -I "$INTERFACE" "$IP" >/dev/null 2>&1 && ! ping -c 1 -W 1 "$IP" >/dev/null 2>&1; then
                DESIRED_IP="$IP"
                break
            fi
        else
            DESIRED_IP="$IP"
            break
        fi
    done

    [ -z "$DESIRED_IP" ] && { echo "No available IP in range $START to $END"; exit 1; }

    # Set IP if needed
    if [ "$CURRENT_IP" = "$DESIRED_IP" ]; then
        echo "IP already set to $DESIRED_IP/$SUBNET_MASK with Gateway $GATEWAY for $CONNECTION_ID"
        exit 0
    fi

    nmcli con mod "$CONNECTION_ID" ipv4.method manual ipv4.addresses "$DESIRED_IP/$SUBNET_MASK" ipv4.gateway "$GATEWAY"
    nmcli con up "$CONNECTION_ID"
    echo "Assigned IP: $DESIRED_IP/$SUBNET_MASK, Gateway: $GATEWAY to $CONNECTION_ID" >> /var/log/set_prefered_ip.log
else
    echo "$(date): Skipped: ACTION=$ACTION, CONNECTION_ID=$CONNECTION_ID" >> /var/log/set_prefered_ip.log
fi
