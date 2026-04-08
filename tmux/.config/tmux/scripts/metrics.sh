#!/usr/bin/env bash

# RAM usage percentage on macOS.
page_size=$(sysctl -n hw.pagesize)
mem_total_bytes=$(sysctl -n hw.memsize)
vm_out=$(vm_stat)

pages_active=$(echo "$vm_out" | awk '/Pages active/ {gsub("\\.", "", $3); print $3}')
pages_wired=$(echo "$vm_out" | awk '/Pages wired down/ {gsub("\\.", "", $4); print $4}')
pages_compressed=$(echo "$vm_out" | awk '/Pages occupied by compressor/ {gsub("\\.", "", $5); print $5}')

used_pages=$((pages_active + pages_wired + pages_compressed))
used_bytes=$((used_pages * page_size))
ram_pct=$(awk -v used="$used_bytes" -v total="$mem_total_bytes" 'BEGIN {printf "%.0f", (used/total)*100}')

# Total CPU usage percentage (user + system).
cpu_pct=$(top -l 1 | awk -F'[:,%]' '/CPU usage/ {u=$2+0; s=$4+0; printf "%.0f", u+s; exit}')
if [[ -z "$cpu_pct" ]]; then
  cpu_pct="N/A"
fi

# CPU temperature via osx-cpu-temp.
if command -v osx-cpu-temp >/dev/null 2>&1; then
  raw_temp=$(osx-cpu-temp 2>/dev/null | awk '{print $1}')
  temp_num=$(echo "$raw_temp" | tr -cd '0-9.')
  if [[ -n "$temp_num" ]] && awk -v t="$temp_num" 'BEGIN {exit !(t > 1)}'; then
    temp="${temp_num}C"
  else
    temp="N/A"
  fi
else
  temp="N/A"
fi

# Fallback for systems where osx-cpu-temp doesn't expose a valid value.
if [[ "$temp" == "N/A" ]] && command -v istats >/dev/null 2>&1; then
  istats_temp=$(istats cpu temp --no-graphs 2>/dev/null | awk -F': ' '/CPU temp/ {print $2; exit}')
  if [[ -n "$istats_temp" ]]; then
    temp="$istats_temp"
  fi
fi

# Optional privileged fallback (only works if passwordless sudo is configured).
if [[ "$temp" == "N/A" ]]; then
  pm_temp=$(sudo -n powermetrics --samplers smc -n 1 2>/dev/null | awk -F': ' '/CPU die temperature|CPU temperature/ {print $2; exit}')
  if [[ -n "$pm_temp" ]]; then
    temp="$pm_temp"
  fi
fi

# Thermal pressure state (separate from numeric temperature).
therm_state="OK"
therm_out=$(pmset -g therm 2>/dev/null)
if echo "$therm_out" | grep -qi 'No thermal warning level has been recorded'; then
  therm_state="OK"
elif echo "$therm_out" | grep -qi 'warning level'; then
  therm_state="HOT"
fi

# Final fallback for unavailable numeric temperature.
if [[ "$temp" == "N/A" ]]; then
  temp="--"
fi

printf " %s%% |  %s%% |  %s %s" "$cpu_pct" "$ram_pct" "$temp" "$therm_state"
