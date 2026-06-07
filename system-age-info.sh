#!/usr/bin/env bash

get_creation_time () {
    stat -c %W /
}

get_now_time () {
    date "+%s"
}

usage_and_die () {
    echo "Usage: $(basename "$0") <COMMAND>" >&2
    echo " " >&2
    echo "Commands:" >&2
    echo "  birth ... See when the system was installed. (Based on when '/' was created.)" >&2
    echo "  age   ... See system age. (Duration since birth.)" >&2
	echo "  counted ... See syste age. (But numbers add up instead of the same value shown in different formats.)" >&2
    echo "  combined ... See system age in one line. (Useful for fastfetch.)" >&2

    exit 1
}

log_key_val () {
    echo -e "\033[0;33m$1:\033[0m $2\033[0m"
}

log_key_val_counted () {
	echo -e "\033[0;33m$1\033[0m $2\033[0m"
}

log_key_val_combined () {
    echo -e "\033[0;m$1\033[0m $2\033[0m"
}

display_mode="$1"

if [[ "$display_mode" == "birth" ]]; then
    date -d "@$(get_creation_time)"
elif [[ "$display_mode" == "age" ]]; then
    duration_secs="$(( $(get_now_time) - $(get_creation_time) ))"
    duration_mins="$(( ${duration_secs} / 60 ))"
    duration_hours="$(( ${duration_mins} / 60 ))"
    duration_days="$(( ${duration_hours} / 24 ))"
    duration_months="$(( ${duration_days} / 30 ))"
    duration_years="$(( ${duration_days} / 365 ))"

	echo "System age:"
    log_key_val "In Seconds" "$duration_secs"
    log_key_val "In Minutes" "$duration_mins"
    log_key_val "In Hours" "$duration_hours"
    log_key_val "In Days" "$duration_days"
    log_key_val "In Months" "$duration_months"
    log_key_val "In Years" "$duration_years"
    
elif [[ "$display_mode" == "combined" ]]; then	
    duration_secs="$(( $(get_now_time) - $(get_creation_time) ))"
    duration_mins="$(( ${duration_secs} / 60 ))"
    duration_hours="$(( ${duration_mins} / 60 ))"
    duration_days="$(( ${duration_hours} / 24 ))"
    duration_months="$(( ${duration_days} / 30 ))"
    duration_years="$(( ${duration_days} / 365 ))"
    duration_combined="Years: $(( ${duration_days} / 365 ))|Months: $(( ${duration_days} / 365 ))|Days: $(( ${duration_hours} / 24 ))|Hours: $(( ${duration_mins} / 60 ))|Minutes: $(( ${duration_secs} / 60 ))|Seconds: $(( $(get_now_time) - $(get_creation_time) ))"

    log_key_val_combined "$duration_combined"
elif [[ "$display_mode" == "counted" ]]; then

    total_secs="$(( $(get_now_time) - $(get_creation_time) ))"
    total_mins="$(( ${total_secs} / 60 ))"
    total_hours="$(( ${total_mins} / 60 ))"
    total_days="$(( ${total_hours} / 24 ))"
    total_months="$(( ${total_days} / 30 ))"
	total_years="$(( ${total_days} / 365 ))"

	duration_secs="$(( ${total_secs} - ${total_mins} * 60 ))"
	duration_mins="$(( ${total_mins} - ${total_hours} * 60 ))"
	duration_hours="$(( ${total_hours} - ${total_days} * 24 ))"
	duration_days="$(( ${total_days} - ${total_months} * 30 ))"
	duration_months="$(( ${total_months} - ${total_years} * 12 ))"

	echo "System age:"	
	log_key_val_counted "Seconds:" "$duration_secs"
	log_key_val_counted "Minutes:" "$duration_mins"
	log_key_val_counted "Hours:" "$duration_hours"
	log_key_val_counted "Days:" "$duration_days"
	log_key_val_counted "Months" "$duration_months"
	log_key_val_counted "Years:" "$total_years"
else
    usage_and_die
fi
