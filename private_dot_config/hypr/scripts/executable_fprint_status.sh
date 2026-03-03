#!/usr/bin/env bash

set -u

if ! command -v busctl >/dev/null 2>&1; then
    exit 0
fi

runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
state_file="${runtime_dir}/hyprlock-fprint-last"

device="$(
    busctl --system call net.reactivated.Fprint /net/reactivated/Fprint/Manager \
        net.reactivated.Fprint.Manager GetDefaultDevice 2>/dev/null \
        | awk 'NF>=2 {print $2; exit}'
)"

if [ -z "${device}" ]; then
    exit 0
fi

finger_needed="$(
    busctl --system get-property net.reactivated.Fprint "${device}" \
        net.reactivated.Fprint.Device finger-needed 2>/dev/null \
        | awk '{print $2}'
)"

finger_present="$(
    busctl --system get-property net.reactivated.Fprint "${device}" \
        net.reactivated.Fprint.Device finger-present 2>/dev/null \
        | awk '{print $2}'
)"

if [ "${finger_needed}" != "true" ]; then
    rm -f "${state_file}"
    exit 0
fi

now="$(date +%s)"

if [ "${finger_present}" = "true" ]; then
    printf "%s\n" "${now}" > "${state_file}"
    echo "Fingerprint: scanning..."
    exit 0
fi

last_ts=""
if [ -f "${state_file}" ]; then
    last_ts="$(cat "${state_file}" 2>/dev/null || true)"
fi

if [ -n "${last_ts}" ] && [ $((now - last_ts)) -le 3 ]; then
    echo "Fingerprint: no match, try again"
else
    echo "Fingerprint: touch sensor"
fi
