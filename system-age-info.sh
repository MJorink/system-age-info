#!/bin/sh

get_creation_time() {
    # GNU
    if out=$(stat -c "%W" / 2>/dev/null) && [ -n "$out" ] && [ "$out" -ne 0 ] 2>/dev/null; then
        echo "$out"
    # BSD
    elif out=$(stat -f "%m" / 2>/dev/null) && [ -n "$out" ] && [ "$out" -ne 0 ] 2>/dev/null; then
        echo "$out"
    fi
}

get_now_time()      { date "+%s"; }

usage_and_die() {
    cat >&2 <<EOF
Usage: $(basename "$0") <COMMAND>

Commands:
  birth    ... See when the system was installed. (Based on when '/' was created.)
  age      ... See system age. (Duration since birth.)
  counted  ... See system age. (Add up instead of same value in different formats.)
  combined ... See system age in one line. (Useful for fastfetch.)
EOF
    exit 1
}

calc_duration() {
    local secs="$1"
    TOTAL_SECS=$secs
    TOTAL_MINS=$(( secs / 60 ))
    TOTAL_HOURS=$(( secs / 3600 ))
    TOTAL_DAYS=$(( secs / 86400 ))
    TOTAL_MONTHS=$(( TOTAL_DAYS / 30 ))
    TOTAL_YEARS=$(( TOTAL_DAYS / 365 ))

    REMAINING_SECS=$(( TOTAL_SECS   - TOTAL_MINS   * 60 ))
    REMAINING_MINS=$(( TOTAL_MINS   - TOTAL_HOURS  * 60 ))
    REMAINING_HOURS=$(( TOTAL_HOURS - TOTAL_DAYS   * 24 ))
    REMAINING_DAYS=$(( TOTAL_DAYS   - TOTAL_MONTHS * 30 ))
    REMAINING_MONTHS=$(( TOTAL_MONTHS - TOTAL_YEARS * 12 ))
}

log_kv() {
    # Usage: log_kv "key" "value" ["separator"]
    # separator defaults to ":"
    local sep="${3:-:}"
    printf '\033[0;33m%s%s\033[0m %s\n' "$1" "$sep" "$2"
}

get_birth() {
    local epoch_time
    epoch_time="$(get_creation_time)"

    # Check if date supports GNU syntax (-d), otherwise use BSD syntax (-r)
    if date -d "@$epoch_time" "+%Y" >/dev/null 2>&1; then
        date -d "@$epoch_time" "+%a %b %e %H:%M:%S %Y"
    else
        date -r "$epoch_time" "+%a %b %e %H:%M:%S %Y"
    fi
}

case "${1:-}" in
    birth)
    	get_birth
        ;;
    age)
        calc_duration "$(( $(get_now_time) - $(get_creation_time) ))"
        echo "System age:"
        log_kv "In Seconds" "$TOTAL_SECS"
        log_kv "In Minutes" "$TOTAL_MINS"
        log_kv "In Hours"   "$TOTAL_HOURS"
        log_kv "In Days"    "$TOTAL_DAYS"
        log_kv "In Months"  "$TOTAL_MONTHS"
        log_kv "In Years"   "$TOTAL_YEARS"
        ;;
    counted)
        calc_duration "$(( $(get_now_time) - $(get_creation_time) ))"
        echo "System age:"
        get_birth
        log_kv "Seconds" "$REMAINING_SECS"
        log_kv "Minutes" "$REMAINING_MINS"
        log_kv "Hours"   "$REMAINING_HOURS"
        log_kv "Days"    "$REMAINING_DAYS"
        log_kv "Months"  "$REMAINING_MONTHS"
        log_kv "Years"   "$TOTAL_YEARS"
        ;;
    combined)
        calc_duration "$(( $(get_now_time) - $(get_creation_time) ))"
        printf '\033[0mYears: %s|Months: %s|Days: %s|Hours: %s|Minutes: %s|Seconds: %s\033[0m\n' \
            "$TOTAL_YEARS" "$TOTAL_MONTHS" "$TOTAL_DAYS" \
            "$TOTAL_HOURS" "$TOTAL_MINS"   "$TOTAL_SECS"
        ;;
    *)
        usage_and_die
        ;;
esac
