#!/bin/bash
# Temperature monitoring script for LCARS EWW Dashboard

get_cpu_temp() {
    local temp=0
    
    # Try hwmon (most common on modern systems)
    for hwmon in /sys/class/hwmon/hwmon*/; do
        if [ -f "${hwmon}name" ]; then
            name=$(cat "${hwmon}name" 2>/dev/null)
            case "$name" in
                coretemp|k10temp|zenpower|it87|nct*)
                    for temp_file in "${hwmon}"temp*_input; do
                        if [ -f "$temp_file" ]; then
                            label_file="${temp_file/_input/_label}"
                            if [ -f "$label_file" ]; then
                                label=$(cat "$label_file" 2>/dev/null)
                                if [[ "$label" =~ [Pp]ackage|Tdie|Tctl ]]; then
                                    temp=$(cat "$temp_file" 2>/dev/null)
                                    echo $((temp / 1000))
                                    return
                                fi
                            fi
                            if [ $temp -eq 0 ]; then
                                temp=$(cat "$temp_file" 2>/dev/null)
                            fi
                        fi
                    done
                    ;;
            esac
        fi
    done
    
    # Try thermal zones
    if [ $temp -eq 0 ]; then
        for zone in /sys/class/thermal/thermal_zone*/; do
            if [ -f "${zone}type" ]; then
                type=$(cat "${zone}type" 2>/dev/null)
                if [[ "$type" =~ x86_pkg_temp|cpu|acpitz ]]; then
                    if [ -f "${zone}temp" ]; then
                        temp=$(cat "${zone}temp" 2>/dev/null)
                        break
                    fi
                fi
            fi
        done
    fi
    
    if [ $temp -gt 0 ]; then
        echo $((temp / 1000))
    else
        echo "45"  # Default fallback
    fi
}

get_gpu_temp() {
    local temp=0
    
    # Try NVIDIA GPU
    if command -v nvidia-smi &>/dev/null; then
        temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1)
        if [ -n "$temp" ] && [ "$temp" -gt 0 ] 2>/dev/null; then
            echo "$temp"
            return
        fi
    fi
    
    # Try AMD GPU via hwmon
    for hwmon in /sys/class/hwmon/hwmon*/; do
        if [ -f "${hwmon}name" ]; then
            name=$(cat "${hwmon}name" 2>/dev/null)
            if [[ "$name" =~ amdgpu|radeon ]]; then
                if [ -f "${hwmon}temp1_input" ]; then
                    temp=$(cat "${hwmon}temp1_input" 2>/dev/null)
                    echo $((temp / 1000))
                    return
                fi
            fi
        fi
    done
    
    # Try Intel GPU
    for hwmon in /sys/class/hwmon/hwmon*/; do
        if [ -f "${hwmon}name" ]; then
            name=$(cat "${hwmon}name" 2>/dev/null)
            if [[ "$name" =~ i915 ]]; then
                if [ -f "${hwmon}temp1_input" ]; then
                    temp=$(cat "${hwmon}temp1_input" 2>/dev/null)
                    echo $((temp / 1000))
                    return
                fi
            fi
        fi
    done
    
    echo "40"  # Default fallback
}

case "$1" in
    cpu)
        get_cpu_temp
        ;;
    gpu)
        get_gpu_temp
        ;;
    *)
        echo "Usage: $0 {cpu|gpu}"
        exit 1
        ;;
esac
