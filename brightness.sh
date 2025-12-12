#!/bin/bash
# ==============================================================================
# Script Name: ddc-brightness.sh
# Description: Controls external monitor brightness via DDC/CI for Hyprland/Wayland.
#              Features race condition prevention (flock) and parallel execution.
# Dependencies: ddcutil, util-linux (flock)
# ==============================================================================

# --- Configuration ---
# Modify these variables to match your hardware setup
BUSES="2 4"                     # I2C Bus numbers (run 'sudo ddcutil detect' to identify)
STEP=5                         # Percentage to increase/decrease per keypress
LOCK_FILE="/tmp/ddc_brightness.lock"

# --- Function: Adjust Brightness ---
# Uses ddcutil's relative value feature (+/-) to avoid expensive read operations.
adjust_brightness() {
    local bus=$1
    local op=$2   # Operator: + or -
    local step=$3 # Value: e.g., 10

    # Execute the DDC command in the background (&) for parallelism
    ddcutil --bus=$bus setvcp 10 $op $step &
}

# --- Concurrency Control (Cooldown) ---
# Attempt to acquire a non-blocking exclusive lock on the lock file.
# If the script is already running (previous keypress processing), 
# this instance will exit immediately to prevent input lag and queue pile-up.
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    exit 1
fi

# --- Argument Parsing ---
case "$1" in
  up)
    OP="+"
    ;;
  down)
    OP="-"
    ;;
  *)
    echo "Usage: $0 {up|down}"
    exit 1
    ;;
esac

# --- Main Execution ---
# Loop through all configured buses and trigger adjustments in parallel.
for BUS in $BUSES; do
    adjust_brightness $BUS $OP $STEP
done

# Wait for all background processes (monitor updates) to complete
# before releasing the lock (which happens automatically when script exits).
wait
