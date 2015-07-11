#!/bin/bash

# This file contains a few functions useful when included in other scripts.

# Returns the number of days in the month.
# Uses the current month of the current year by default.
# Params $1 - the month
#        $2 - the year
daysInMonth() {
    # Validate inputs.
    month=$(date +%m)
    if [ -n "$1" ]; then
        if [ $1 -ge 1 -o $1 -le 12 ]; then
            month=$1
        fi
    fi

    year=$(date +%Y)
    if [ -n "$2" ]; then
        echo $2 | grep -q "^[0-9]*$"
        if [ $? -eq 0 ]; then
            year=$2
        fi
    fi

    # Pad the month to two digits, e.g. 01 to 09.
    if [ ${#month} -lt 2 ]; then
        month=$(printf '%02d' $month)
    fi

    # Get the number of days in the month.
    case $month in
        01 )
            days=31
            ;;
        02 )
            isLeapYear $year
            leap=$?
            if [ $leap -eq 0 ]; then
                days=29
            else
                days=28
            fi
            ;;
        03 )
            days=31
            ;;
        04 )
            days=30
            ;;
        05 )
            days=31
            ;;
        06 )
            days=30
            ;;
        07 )
            days=31
            ;;
        08 )
            days=31
            ;;
        09 )
            days=30
            ;;
        10 )
            days=31
            ;;
        11 )
            days=30
            ;;
        12 )
            days=31
            ;;
    esac
    return $days
}

# Checks whether given year is a leap year or not.
# If the year is not supplied, it takes current year as default.
#
# This script assumes that a leap year comes every 4 years,
# but not every 100 years, then again every 400 years.
isLeapYear() {
    year=$(date +%Y)
    if [ -n "$1" ]; then
        echo $1 | grep -q "^[0-9]*$"
        if [ $? -eq 0 ]; then
            year=$1
        fi
    fi

    mod4=$(($year % 4))
    mod100=$(($year % 100))
    mod400=$(($year % 400))
    if [ $mod4 -ne 0 ]; then
        #echo "$year - NOT a leap year"
        return 1
    elif [ $mod100 -ne 0 ]; then
        #echo "$year - IS a leap year"
        return 0
    elif [ $mod400 -ne 0 ]; then
        #echo "$year - NOT a leap year"
        return 1
    else
        #echo "$year - IS a leap year"
        return 0
    fi
}

# Returns the number of occurrences of a particular day in a month.
# Uses the current day of the current month of the current year by default.
# Params $1 - the day
#        $2 - the month
#        $3 - the year
numDayInMonth() {
    # Validate inputs.
    echo $1 | grep -q "^Mo\|Tu\|We\|Th\|Fr\|Sa\|Su$"
    if [ $? -ne 0 ]; then
        day=$(date +%u)
        if [ -n "$1" ]; then
            if [ $1 -ge 1 -o $1 -le 7 ]; then
                day=$1
            fi
        fi
    else
        day=$1
    fi

    month=$(date +%m)
    if [ -n "$2" ]; then
        if [ $2 -ge 1 -o $2 -le 12 ]; then
            month=$2
        fi
    fi

    year=$(date +%Y)
    if [ -n "$3" ]; then
        echo $3 | grep -q "^[0-9]*$"
        if [ $? -eq 0 ]; then
            year=$3
        fi
    fi

    # Make sure the day is in its abbreviated form.
    case $day in
        1)
            day=Mo
            ;;
        2)
            day=Tu
            ;;
        3)
            day=We
            ;;
        4)
            day=Th
            ;;
        5)
            day=Fr
            ;;
        6)
            day=Sa
            ;;
        7)
            day=Su
            ;;
    esac

    # Get the calendar output for the month and year, then get the day row and count the columns, minus the row header.
    days_in_month=$(($(ncal -d ${year}-${month} | grep $day | wc -w) - 1))
    return $days_in_month
}
