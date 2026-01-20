#!/bin/bash
# Network monitoring script for LCARS EWW Dashboard

# Cache file for storing previous values (for speed calculation)
CACHE_FILE="/tmp/eww-network-cache"

human_readable_speed() {
    local bytes=$1
    if [ $bytes -ge 1073741824 ]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1073741824}") GB/s"
    elif [ $bytes -ge 1048576 ]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1048576}") MB/s"
    elif [ $bytes -ge 1024 ]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1024}") KB/s"
    else
        echo "${bytes} B/s"
    fi
}

get_default_interface() {
    # Get the default network interface
    local iface=$(ip route | grep '^default' | awk '{print $5}' | head -n1)
    if [ -z "$iface" ]; then
        # Fallback: find first non-loopback interface that's UP
        iface=$(ip link show | grep -E '^[0-9]+:' | grep -v 'lo:' | grep 'state UP' | awk -F': ' '{print $2}' | head -n1)
    fi
    if [ -z "$iface" ]; then
        iface="eth0"  # Last resort fallback
    fi
    echo "$iface"
}

get_interface_ip() {
    local iface=$(get_default_interface)
    local ip=$(ip addr show "$iface" 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1 | head -n1)
    if [ -z "$ip" ]; then
        echo "No IP"
    else
        echo "$ip"
    fi
}

get_interface_status() {
    local iface=$(get_default_interface)
    local state=$(cat "/sys/class/net/$iface/operstate" 2>/dev/null)
    if [ "$state" = "up" ]; then
        echo "up"
    else
        echo "down"
    fi
}

get_network_speed() {
    local direction=$1  # "down" or "up"
    local iface=$(get_default_interface)
    
    # Read current values
    local rx_bytes=$(cat "/sys/class/net/$iface/statistics/rx_bytes" 2>/dev/null || echo 0)
    local tx_bytes=$(cat "/sys/class/net/$iface/statistics/tx_bytes" 2>/dev/null || echo 0)
    local current_time=$(date +%s%N)
    
    # Read previous values from cache
    if [ -f "$CACHE_FILE" ]; then
        source "$CACHE_FILE"
    else
        prev_rx_bytes=0
        prev_tx_bytes=0
        prev_time=$current_time
    fi
    
    # Calculate time difference in seconds (with nanosecond precision)
    local time_diff=$(awk "BEGIN {printf \"%.9f\", ($current_time - $prev_time) / 1000000000}")
    
    # Avoid division by zero and handle first run
    if [ "$(awk "BEGIN {print ($time_diff < 0.1)}")" = "1" ]; then
        time_diff=1
    fi
    
    # Calculate speeds
    local rx_diff=$((rx_bytes - prev_rx_bytes))
    local tx_diff=$((tx_bytes - prev_tx_bytes))
    
    # Handle counter wraparound or first run
    if [ $rx_diff -lt 0 ]; then rx_diff=0; fi
    if [ $tx_diff -lt 0 ]; then tx_diff=0; fi
    
    local rx_speed=$(awk "BEGIN {printf \"%.0f\", $rx_diff / $time_diff}")
    local tx_speed=$(awk "BEGIN {printf \"%.0f\", $tx_diff / $time_diff}")
    
    # Save current values to cache
    cat > "$CACHE_FILE" << EOF
prev_rx_bytes=$rx_bytes
prev_tx_bytes=$tx_bytes
prev_time=$current_time
EOF
    
    if [ "$direction" = "down" ]; then
        human_readable_speed $rx_speed
    else
        human_readable_speed $tx_speed
    fi
}

get_connections() {
    # Count active network connections
    local count=$(ss -tun state established 2>/dev/null | tail -n +2 | wc -l)
    echo "$count"
}

case "$1" in
    interface)
        get_default_interface
        ;;
    ip)
        get_interface_ip
        ;;
    status)
        get_interface_status
        ;;
    down)
        get_network_speed "down"
        ;;
    up)
        get_network_speed "up"
        ;;
    connections)
        get_connections
        ;;
    *)
        echo "Usage: $0 {interface|ip|status|down|up|connections}"
        exit 1
        ;;
esac
