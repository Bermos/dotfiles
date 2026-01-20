#!/bin/bash
# System information script for LCARS EWW Dashboard

get_uptime() {
    # Get uptime in human-readable format
    local uptime_seconds=$(cat /proc/uptime | awk '{print int($1)}')
    
    local days=$((uptime_seconds / 86400))
    local hours=$(((uptime_seconds % 86400) / 3600))
    local minutes=$(((uptime_seconds % 3600) / 60))
    
    local result=""
    
    if [ $days -gt 0 ]; then
        result="${days}d "
    fi
    
    if [ $hours -gt 0 ] || [ $days -gt 0 ]; then
        result="${result}${hours}h "
    fi
    
    result="${result}${minutes}m"
    
    echo "$result"
}

get_hostname() {
    hostname | tr '[:lower:]' '[:upper:]'
}

get_kernel() {
    uname -r
}

get_processes() {
    ps aux --no-heading | wc -l
}

get_load() {
    # Get 1-minute load average
    cat /proc/loadavg | awk '{print $1}'
}

get_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$NAME"
    else
        echo "Linux"
    fi
}

case "$1" in
    uptime)
        get_uptime
        ;;
    hostname)
        get_hostname
        ;;
    kernel)
        get_kernel
        ;;
    processes)
        get_processes
        ;;
    load)
        get_load
        ;;
    distro)
        get_distro
        ;;
    *)
        echo "Usage: $0 {uptime|hostname|kernel|processes|load|distro}"
        exit 1
        ;;
esac
