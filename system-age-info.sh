#!/bin/sh

get_time() {
    # $1=path $2=1 to allow mtime fallback
    out=$(stat -c "%W" "$1" 2>/dev/null) || out=$(stat -f "%B" "$1" 2>/dev/null)
    if [ -z "$out" ] || [ "$out" -eq 0 ] 2>/dev/null; then
        [ "$2" = 1 ] && out=$(stat -c "%Y" "$1" 2>/dev/null || stat -f "%m" "$1" 2>/dev/null)
    fi
    echo "$out"
}

usage_and_die() {
    cat >&2 <<EOF
Usage: $(basename "$0") <COMMAND>

Commands:
  birth       ... See when the system was installed. (Based on when '/' was created.)
  age         ... See system age. (Duration since birth.)
  counted     ... See system age. (Add up instead of same value in different formats.)
  file <path> ... See system age based on the age of a given file. (Same output as 'counted'.)
EOF
    exit 1
}

log_kv() { printf '\033[0;32m%s%s\033[0m %s\n' "$1" "${3:-:}" "$2"; }

get_birth() {
    date -d "@$1" "+%a %b %e %H:%M:%S %Y" 2>/dev/null || date -r "$1" "+%a %b %e %H:%M:%S %Y"
}

print_counted() {
    secs=$1 mins=$(( secs/60 )) hours=$(( secs/3600 )) days=$(( secs/86400 ))
    months=$(( days/30 )) years=$(( days/365 ))
    log_kv "Seconds" "$(( secs - mins*60 ))"
    log_kv "Minutes" "$(( mins - hours*60 ))"
    log_kv "Hours"   "$(( hours - days*24 ))"
    log_kv "Days"    "$(( days - months*30 ))"
    log_kv "Months"  "$(( months - years*12 ))"
    log_kv "Years"   "$years"
}

case "${1:-}" in
    birth)
        get_birth "$(get_time / 0)"
        ;;
    age)
        secs=$(( $(date +%s) - $(get_time / 0) ))
        echo "System age:"
        log_kv "In Seconds" "$secs"
        log_kv "In Minutes" "$(( secs/60 ))"
        log_kv "In Hours"   "$(( secs/3600 ))"
        log_kv "In Days"    "$(( secs/86400 ))"
        log_kv "In Months"  "$(( secs/86400/30 ))"
        log_kv "In Years"   "$(( secs/86400/365 ))"
        ;;
    counted)
        t=$(get_time / 0)
        echo "System age:"
        get_birth "$t"
        print_counted $(( $(date +%s) - t ))
        ;;
    file)
        file_path="${2:-}"
        [ -n "$file_path" ] && [ -e "$file_path" ] || { echo "Error: please provide a valid file path." >&2; usage_and_die; }
        t=$(get_time "$file_path" 1)
        echo "System age:"
        get_birth "$t"
        print_counted $(( $(date +%s) - t ))
        ;;
    *)
        usage_and_die
        ;;
esac
