#!/bin/bash
# Disk monitoring script for LCARS EWW Dashboard

# Cache file for storing previous I/O values
CACHE_FILE="/tmp/eww-disk-io-cache"

human_readable() {
    local bytes=$1
    if [ $bytes -ge 1099511627776 ]; then
        echo "$(awk "BEGIN {printf \"%.1f\", $bytes/1099511627776}")T"
    elif [ $bytes -ge 1073741824 ]; then
        echo "$(awk "BEGIN {printf \"%.1f\", $bytes/1073741824}")G"
    elif [ $bytes -ge 1048576 ]; then
        echo "$(awk "BEGIN {printf \"%.0f\", $bytes/1048576}")M"
    else
        echo "$(awk "BEGIN {printf \"%.0f\", $bytes/1024}")K"
    fi
}

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

get_disk_usage() {
    local mount=$1
    local field=$2
    
    # Get disk usage for the specified mount point
    local df_output=$(df -B1 "$mount" 2>/dev/null | tail -n1)
    
    if [ -z "$df_output" ]; then
        echo "N/A"
        return
    fi
    
    local total=$(echo "$df_output" | awk '{print $2}')
    local used=$(echo "$df_output" | awk '{print $3}')
    local available=$(echo "$df_output" | awk '{print $4}')
    local percent=$(echo "$df_output" | awk '{print $5}' | tr -d '%')
    
    case "$field" in
        percent)
            echo "$percent"
            ;;
        used)
            human_readable $used
            ;;
        total)
            human_readable $total
            ;;
        available)
            human_readable $available
            ;;
    esac
}

get_io_speed() {
    local direction=$1  # "read" or "write"
    
    # Find the primary disk device
    local disk=""
    for d in sda nvme0n1 vda; do
        if [ -d "/sys/block/$d" ]; then
            disk=$d
            break
        fi
    done
    
    if [ -z "$disk" ]; then
        echo "0 B/s"
        return
    fi
    
    # Read current I/O stats
    # For traditional disks: /sys/block/sda/stat
    # Fields: reads_completed reads_merged sectors_read time_reading writes_completed writes_merged sectors_written time_writing ...
    local stat_file="/sys/block/$disk/stat"
    
    if [ ! -f "$stat_file" ]; then
        echo "0 B/s"
        return
    fi
    
    local stats=$(cat "$stat_file")
    local sectors_read=$(echo "$stats" | awk '{print $3}')
    local sectors_written=$(echo "$stats" | awk '{print $7}')
    local current_time=$(date +%s%N)
    
    # Sector size is typically 512 bytes
    local sector_size=512
    
    # Read previous values from cache
    if [ -f "$CACHE_FILE" ]; then
        source "$CACHE_FILE"
    else
        prev_sectors_read=0
        prev_sectors_written=0
        prev_io_time=$current_time
    fi
    
    # Calculate time difference in seconds
    local time_diff=$(awk "BEGIN {printf \"%.9f\", ($current_time - $prev_io_time) / 1000000000}")
    
    if [ "$(awk "BEGIN {print ($time_diff < 0.1)}")" = "1" ]; then
        time_diff=1
    fi
    
    # Calculate I/O speeds
    local read_diff=$((sectors_read - prev_sectors_read))
    local write_diff=$((sectors_written - prev_sectors_written))
    
    # Handle counter wraparound
    if [ $read_diff -lt 0 ]; then read_diff=0; fi
    if [ $write_diff -lt 0 ]; then write_diff=0; fi
    
    local read_bytes=$((read_diff * sector_size))
    local write_bytes=$((write_diff * sector_size))
    
    local read_speed=$(awk "BEGIN {printf \"%.0f\", $read_bytes / $time_diff}")
    local write_speed=$(awk "BEGIN {printf \"%.0f\", $write_bytes / $time_diff}")
    
    # Save current values to cache
    cat > "$CACHE_FILE" << EOF
prev_sectors_read=$sectors_read
prev_sectors_written=$sectors_written
prev_io_time=$current_time
EOF
    
    if [ "$direction" = "read" ]; then
        human_readable_speed $read_speed
    else
        human_readable_speed $write_speed
    fi
}

case "$1" in
    root_percent)
        get_disk_usage "/" "percent"
        ;;
    root_used)
        get_disk_usage "/" "used"
        ;;
    root_total)
        get_disk_usage "/" "total"
        ;;
    home_percent)
        # Check if /home is a separate partition
        if mountpoint -q /home 2>/dev/null; then
            get_disk_usage "/home" "percent"
        else
            get_disk_usage "/" "percent"
        fi
        ;;
    home_used)
        if mountpoint -q /home 2>/dev/null; then
            get_disk_usage "/home" "used"
        else
            get_disk_usage "/" "used"
        fi
        ;;
    home_total)
        if mountpoint -q /home 2>/dev/null; then
            get_disk_usage "/home" "total"
        else
            get_disk_usage "/" "total"
        fi
        ;;
    read)
        get_io_speed "read"
        ;;
    write)
        get_io_speed "write"
        ;;
    *)
        echo "Usage: $0 {root_percent|root_used|root_total|home_percent|home_used|home_total|read|write}"
        exit 1
        ;;
esac
