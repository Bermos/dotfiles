#!/bin/bash
# CPU usage monitoring script for LCARS EWW Dashboard
# Outputs total CPU usage or per-core breakdown

get_total_cpu() {
    # Get CPU usage using /proc/stat
    # Read two samples 100ms apart for accurate measurement
    read -r cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
    prev_idle=$idle
    prev_total=$((user + nice + system + idle + iowait + irq + softirq + steal))
    
    sleep 0.1
    
    read -r cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
    curr_idle=$idle
    curr_total=$((user + nice + system + idle + iowait + irq + softirq + steal))
    
    diff_idle=$((curr_idle - prev_idle))
    diff_total=$((curr_total - prev_total))
    
    if [ $diff_total -eq 0 ]; then
        echo "0"
    else
        usage=$((100 * (diff_total - diff_idle) / diff_total))
        echo "$usage"
    fi
}

get_cores_json() {
    # Get per-core CPU usage as JSON array
    local cores=()
    local core_count=$(nproc)
    
    # First reading
    declare -A prev_total
    declare -A prev_idle
    
    while read -r line; do
        if [[ $line =~ ^cpu([0-9]+) ]]; then
            core_id="${BASH_REMATCH[1]}"
            read -r _ user nice system idle iowait irq softirq steal _ _ <<< "$line"
            prev_idle[$core_id]=$idle
            prev_total[$core_id]=$((user + nice + system + idle + iowait + irq + softirq + steal))
        fi
    done < /proc/stat
    
    sleep 0.1
    
    # Second reading
    while read -r line; do
        if [[ $line =~ ^cpu([0-9]+) ]]; then
            core_id="${BASH_REMATCH[1]}"
            read -r _ user nice system idle iowait irq softirq steal _ _ <<< "$line"
            curr_idle=$idle
            curr_total=$((user + nice + system + idle + iowait + irq + softirq + steal))
            
            diff_idle=$((curr_idle - ${prev_idle[$core_id]}))
            diff_total=$((curr_total - ${prev_total[$core_id]}))
            
            if [ $diff_total -eq 0 ]; then
                usage=0
            else
                usage=$((100 * (diff_total - diff_idle) / diff_total))
            fi
            
            cores+=("{\"id\":$core_id,\"usage\":$usage}")
        fi
    done < /proc/stat
    
    # Join array elements with commas
    local IFS=','
    echo "[${cores[*]}]"
}

case "$1" in
    total)
        get_total_cpu
        ;;
    cores)
        get_cores_json
        ;;
    *)
        echo "Usage: $0 {total|cores}"
        exit 1
        ;;
esac
