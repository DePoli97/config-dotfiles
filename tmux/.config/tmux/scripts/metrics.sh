#!/usr/bin/env bash

# Cross-platform tmux status metrics (macOS + Linux).
# Output format: used/total (pct) for CPU and RAM.

set -u

cpu_pct="--"
cpu_used="--"
cpu_total="--"

ram_pct="--"
ram_used_gb="--"
ram_total_gb="--"

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

fi

cpu_display="--/-- (--%)"
ram_display="--/--GiB (--%)"

if [[ "$cpu_used" != "--" && "$cpu_total" != "--" && "$cpu_pct" != "--" ]]; then
  cpu_display="${cpu_used}/${cpu_total}c (${cpu_pct}%)"
fi
if [[ "$ram_used_gb" != "--" && "$ram_total_gb" != "--" && "$ram_pct" != "--" ]]; then
  ram_display="${ram_used_gb}/${ram_total_gb}GiB (${ram_pct}%)"
fi

output=$(printf "  %s |   %s" \
  "$cpu_display" "$ram_display")

# tmux status format parses '%' tokens; escape them only when running inside tmux.
if [[ -n "${TMUX:-}" ]]; then
  output=${output//%/%}
fi

printf "%s" "$output"
