#!/bin/bash
# Memory monitoring script for LCARS EWW Dashboard
# Outputs RAM and swap usage in various formats

human_readable() {
    local bytes=$1
    if [ $bytes -ge 1073741824 ]; then
        echo "$(awk "BEGIN {printf \"%.1f\", $bytes/1073741824}")G"
    elif [ $bytes -ge 1048576 ]; then
        echo "$(awk "BEGIN {printf \"%.0f\", $bytes/1048576}")M"
    else
        echo "$(awk "BEGIN {printf \"%.0f\", $bytes/1024}")K"
    fi
}

get_mem_info() {
    # Parse /proc/meminfo
    local mem_total=$(grep '^MemTotal:' /proc/meminfo | awk '{print $2}')
    local mem_free=$(grep '^MemFree:' /proc/meminfo | awk '{print $2}')
    local mem_available=$(grep '^MemAvailable:' /proc/meminfo | awk '{print $2}')
    local buffers=$(grep '^Buffers:' /proc/meminfo | awk '{print $2}')
    local cached=$(grep '^Cached:' /proc/meminfo | awk '{print $2}')
    local swap_total=$(grep '^SwapTotal:' /proc/meminfo | awk '{print $2}')
    local swap_free=$(grep '^SwapFree:' /proc/meminfo | awk '{print $2}')
    
    # Calculate used memory (total - available)
    local mem_used=$((mem_total - mem_available))
    local swap_used=$((swap_total - swap_free))
    
    # Convert to bytes for human_readable function
    local mem_total_bytes=$((mem_total * 1024))
    local mem_used_bytes=$((mem_used * 1024))
    local swap_total_bytes=$((swap_total * 1024))
    local swap_used_bytes=$((swap_used * 1024))
    
    case "$1" in
        used)
            human_readable $mem_used_bytes
            ;;
        total)
            human_readable $mem_total_bytes
            ;;
        percent)
            if [ $mem_total -eq 0 ]; then
                echo "0"
            else
                echo $((mem_used * 100 / mem_total))
            fi
            ;;
        swap_used)
            human_readable $swap_used_bytes
            ;;
        swap_total)
            human_readable $swap_total_bytes
            ;;
        swap_percent)
            if [ $swap_total -eq 0 ]; then
                echo "0"
            else
                echo $((swap_used * 100 / swap_total))
            fi
            ;;
        *)
            echo "Usage: $0 {used|total|percent|swap_used|swap_total|swap_percent}"
            exit 1
            ;;
    esac
}

get_mem_info "$1"
