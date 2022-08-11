#!/usr/bin/env bash

#Set prameter defaults and define variables

keep_daily=${ROTATE_KEEP_DAILY:=7}
keep_weekly=${ROTATE_KEEP_WEEKLY:=4}
keep_monthly=${ROTATE_KEEP_MONTHLY:=12}
keep_yearly=${ROTATE_KEEP_YEARLY:=100}

pwd="$(pwd)"

snapshot_location=${SNAPSHOT_LOCATION:=$pwd}

#functions section

print_help() {
    cat << EOF

Usage: rotate.sh <command> [<params>] [source] [target]

Commands:

help                print his help
daily [-d num]      do a daily rotation, keeping num daily snapshots
weekly [-w num]     do a weekly rotation, keeping num daily snapshots
monthly [-m num]    do a monthly rotation, keeping num monthly snapshots
yearly [-y num]     do a monthly yearly, keeping num yearly snapshots

EOF

    exit "$1"
}

get_max_num() {
    mode=$1
    cd "$snapshot_location" || exit 1
    newest="$(find . -name "$mode.*" | grep -o -e '\d*$' | sort | tail -1)"
    if [ -z "$newest" ]; then
        echo 0
    else
        echo "$newest"
    fi
}

delete_range() {
    mode=$1
    keep=$2
    max=$3
    cd "$snapshot_location" || exit 1
    min=$(( keep + 1 ))
    for i in $(seq "$min $max"); do
        rm -rf "./$mode.$i"
    done
}

bump() {
    mode=$1
    oldest=$2
    cd "$snapshot_location" || exit 1
    for i in $(seq "$oldest" 1); do
        next=$(( i + 1 ))
        mv "./$mode.$i" "./$mode.$next"
    done
    lower=''
    case "$mode" in
    "yearly")
        lower="monthly"
        ;;
    "monthly")
        lower="weekly"
        ;;
    "weekly")
        lower="daily"
        ;;
    "daily")
        cp -al "$source" "./daily.1"
        return
        ;;
    *)
        exit 1
        ;;
    esac
    max="$(get_max_num "$lower")"
    mv "./$lower.$max" "./$mode.1"
}

rotate() {
    mode=$1
    keep=$2
    if (( keep <= 0 )); then
        exit 1
    fi
    max=$(get_max_num daily)
    oldest=''
    if (( max >= keep )); then
        delete_range "$mode $keep $max"
        oldest=$(( keep - 1 ))
    else
        oldest=$max
    fi
    bump "$mode $oldest"
    exit 0
}

#TODO: Parse commandline
#TODO Set target_location and source variables

command=$1

case "$command" in
"help")
    print_help 0
    ;;
"daily")
    rotate daily "$keep_daily"
    ;;
"weekly")
    rotate weekly "$keep_weekly"
    ;;
"monthly")
    rotate monthly "$keep_monthly"
    ;;
"yearly")
    rotate yearly "$keep_yearly"
    ;;
*)
    print_help
    ;;
esac