#!/usr/bin/env bash

# Cross-platform tmux status metrics (macOS + Linux).
# Output format: used/total (pct) for CPU, RAM, GPU, VRAM.

set -u

cpu_pct="--"
cpu_used="--"
cpu_total="--"

ram_pct="--"
ram_used_gb="--"
ram_total_gb="--"

gpu_pct="--"
gpu_used="--"
gpu_total="--"

vram_pct="--"
vram_used="--"
vram_total="--"

temp="--"
therm_state="--"

os_name="$(uname -s 2>/dev/null || echo unknown)"

if [[ "$os_name" == "Darwin" ]]; then
  cpu_total="$(sysctl -n hw.logicalcpu 2>/dev/null || echo --)"

  # CPU total usage percent (user + system).
  cpu_pct="$(top -l 1 | awk -F'[:,%]' '/CPU usage/ {u=$2+0; s=$4+0; printf "%.0f", u+s; exit}')"
  [[ -z "$cpu_pct" ]] && cpu_pct="--"
  if [[ "$cpu_total" != "--" && "$cpu_pct" != "--" ]]; then
    cpu_used="$(awk -v t="$cpu_total" -v p="$cpu_pct" 'BEGIN {printf "%.1f", (t*p)/100}')"
  fi

  # RAM used percent = (active + wired + compressed) / total.
  page_size="$(sysctl -n hw.pagesize 2>/dev/null || echo 4096)"
  mem_total_bytes="$(sysctl -n hw.memsize 2>/dev/null || echo 0)"
  vm_out="$(vm_stat 2>/dev/null || true)"
  pages_active="$(echo "$vm_out" | awk '/Pages active/ {gsub("\\.", "", $3); print $3; exit}')"
  pages_wired="$(echo "$vm_out" | awk '/Pages wired down/ {gsub("\\.", "", $4); print $4; exit}')"
  pages_compressed="$(echo "$vm_out" | awk '/Pages occupied by compressor/ {gsub("\\.", "", $5); print $5; exit}')"
  pages_active="${pages_active:-0}"
  pages_wired="${pages_wired:-0}"
  pages_compressed="${pages_compressed:-0}"
  if [[ "$mem_total_bytes" -gt 0 ]]; then
    used_pages=$((pages_active + pages_wired + pages_compressed))
    used_bytes=$((used_pages * page_size))
    ram_pct="$(awk -v used="$used_bytes" -v total="$mem_total_bytes" 'BEGIN {printf "%.0f", (used/total)*100}')"
    ram_used_gb="$(awk -v b="$used_bytes" 'BEGIN {printf "%.1f", b/1073741824}')"
    ram_total_gb="$(awk -v b="$mem_total_bytes" 'BEGIN {printf "%.1f", b/1073741824}')"
  fi

  # CPU temperature (best-effort without blocking/prompting for sudo).
  if command -v osx-cpu-temp >/dev/null 2>&1; then
    temp_num="$(osx-cpu-temp 2>/dev/null | awk '{print $1}' | tr -cd '0-9.')"
    [[ -n "$temp_num" ]] && temp="${temp_num}C"
  fi
  if [[ "$temp" == "--" ]] && command -v istats >/dev/null 2>&1; then
    istats_temp="$(istats cpu temp --no-graphs 2>/dev/null | awk -F': ' '/CPU temp/ {print $2; exit}')"
    [[ -n "$istats_temp" ]] && temp="$istats_temp"
  fi

  # Best-effort GPU utilization on macOS (requires sudo rights for powermetrics on most systems).
  gpu_busy="$(sudo -n powermetrics --samplers gpu_power -n 1 2>/dev/null | awk -F': ' '/GPU HW active residency/ {print $2; exit}')"
  if [[ -n "$gpu_busy" ]]; then
    gpu_pct="$(echo "$gpu_busy" | tr -cd '0-9.')"
    [[ -z "$gpu_pct" ]] && gpu_pct="--"
  fi
  if [[ "$gpu_pct" != "--" ]]; then
    gpu_used="$(awk -v p="$gpu_pct" 'BEGIN {printf "%.0f", p}')"
    gpu_total="100"
  fi

  # Thermal pressure state (not the same as numeric temperature).
  therm_out="$(pmset -g therm 2>/dev/null || true)"
  if echo "$therm_out" | grep -qi 'No thermal warning level has been recorded'; then
    therm_state="OK"
  elif echo "$therm_out" | grep -qi 'warning level'; then
    therm_state="HOT"
  else
    therm_state="--"
  fi

  # On unified memory systems (Apple Silicon), VRAM mirrors RAM in used/total and %.
  if [[ "$ram_pct" != "--" ]]; then
    vram_pct="$ram_pct"
    vram_used="$ram_used_gb"
    vram_total="$ram_total_gb"
  fi

elif [[ "$os_name" == "Linux" ]]; then
  cpu_total="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo --)"

  # CPU usage percent from vmstat sample (100 - idle).
  cpu_pct="$(vmstat 1 2 2>/dev/null | tail -1 | awk '{print 100 - $15}')"
  [[ -z "$cpu_pct" ]] && cpu_pct="--"
  if [[ "$cpu_total" != "--" && "$cpu_pct" != "--" ]]; then
    cpu_used="$(awk -v t="$cpu_total" -v p="$cpu_pct" 'BEGIN {printf "%.1f", (t*p)/100}')"
  fi

  # RAM used percent from /proc/meminfo using MemAvailable.
  if [[ -r /proc/meminfo ]]; then
    read -r ram_pct ram_used_gb ram_total_gb < <(awk '
      /^MemTotal:/ {t=$2}
      /^MemAvailable:/ {a=$2}
      END {
        if (t>0 && a>=0) {
          u=t-a;
          printf "%.0f %.1f %.1f\n", (u/t)*100, u/1048576, t/1048576;
        } else {
          print "-- -- --";
        }
      }
    ' /proc/meminfo 2>/dev/null)
  fi

  # Temperature from thermal zones (millidegree Celsius).
  for f in /sys/class/thermal/thermal_zone*/temp; do
    if [[ -r "$f" ]]; then
      t_raw="$(cat "$f" 2>/dev/null)"
      if [[ "$t_raw" =~ ^[0-9]+$ ]] && [[ "$t_raw" -gt 1000 ]]; then
        temp="$(awk -v x="$t_raw" 'BEGIN {printf "%.1fC", x/1000}')"
        break
      fi
    fi
  done
  [[ "$temp" == "--" ]] && therm_state="--" || therm_state="OK"

  # GPU/VRAM on NVIDIA if available.
  if command -v nvidia-smi >/dev/null 2>&1; then
    gpu_line="$(nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | head -n1)"
    if [[ -n "$gpu_line" ]]; then
      gpu_pct="$(echo "$gpu_line" | awk -F',' '{gsub(/ /, "", $1); print $1}')"
      mem_used="$(echo "$gpu_line" | awk -F',' '{gsub(/ /, "", $2); print $2}')"
      mem_total="$(echo "$gpu_line" | awk -F',' '{gsub(/ /, "", $3); print $3}')"
      if [[ -n "$gpu_pct" ]]; then
        gpu_used="$gpu_pct"
        gpu_total="100"
      fi
      if [[ -n "$mem_used" && -n "$mem_total" && "$mem_total" != "0" ]]; then
        vram_pct="$(awk -v u="$mem_used" -v t="$mem_total" 'BEGIN {printf "%.0f", (u/t)*100}')"
        vram_used="$(awk -v m="$mem_used" 'BEGIN {printf "%.1f", m/1024}')"
        vram_total="$(awk -v m="$mem_total" 'BEGIN {printf "%.1f", m/1024}')"
      fi
    fi
  fi
fi

cpu_display="--/-- (--%)"
ram_display="--/--GiB (--%)"
gpu_display="--/-- (--%)"
vram_display="--/--GiB (--%)"

if [[ "$cpu_used" != "--" && "$cpu_total" != "--" && "$cpu_pct" != "--" ]]; then
  cpu_display="${cpu_used}/${cpu_total}c (${cpu_pct}%)"
fi
if [[ "$ram_used_gb" != "--" && "$ram_total_gb" != "--" && "$ram_pct" != "--" ]]; then
  ram_display="${ram_used_gb}/${ram_total_gb}GiB (${ram_pct}%)"
fi
if [[ "$gpu_used" != "--" && "$gpu_total" != "--" && "$gpu_pct" != "--" ]]; then
  gpu_display="${gpu_used}/${gpu_total} (${gpu_pct}%)"
fi
if [[ "$vram_used" != "--" && "$vram_total" != "--" && "$vram_pct" != "--" ]]; then
  vram_display="${vram_used}/${vram_total}GiB (${vram_pct}%)"
fi

output=$(printf "  %s |   %s | 󰢮  %s | 󰍛  %s |   %s |   %s" \
  "$cpu_display" "$ram_display" "$gpu_display" "$vram_display" "$temp" "$therm_state")

# tmux status format parses '%' tokens; escape them only when running inside tmux.
if [[ -n "${TMUX:-}" ]]; then
  output=${output//%/%%}
fi

printf "%s" "$output"
