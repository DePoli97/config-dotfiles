#!/usr/bin/env bash

# Cross-platform tmux status metrics (macOS + Linux).
# Output: RAM used/total in GiB.

set -u

ram_used_gb="--"
ram_total_gb="--"

os_name="$(uname -s 2>/dev/null || echo unknown)"

if [[ "$os_name" == "Darwin" ]]; then
  # RAM used = active + wired + compressed pages.
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
    ram_used_gb="$(awk -v b="$used_bytes" 'BEGIN {printf "%.1f", b/1073741824}')"
    ram_total_gb="$(awk -v b="$mem_total_bytes" 'BEGIN {printf "%.1f", b/1073741824}')"
  fi

elif [[ "$os_name" == "Linux" ]]; then
  # RAM used from /proc/meminfo via MemAvailable.
  if [[ -r /proc/meminfo ]]; then
    read -r ram_used_gb ram_total_gb < <(awk '
      /^MemTotal:/ {t=$2}
      /^MemAvailable:/ {a=$2}
      END {
        if (t>0 && a>=0) {
          printf "%.1f %.1f\\n", (t-a)/1048576, t/1048576;
        } else {
          print "-- --";
        }
      }
    ' /proc/meminfo 2>/dev/null)
  fi
fi

ram_display="--/-- GiB"

if [[ "$ram_used_gb" != "--" && "$ram_total_gb" != "--" ]]; then
  ram_display="${ram_used_gb}/${ram_total_gb} GiB"
fi

printf "  %s" "$ram_display"
