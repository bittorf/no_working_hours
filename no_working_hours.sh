#!/bin/sh

TIME="${1:-$( date +%s )}"	# e.g. unixtime or year or '-1'

usage()
{
	cat <<EOF

Usage: $0 <empty = now|year|unixtime>

       $0		// sets returncode
       $0 2019	// outputs each day of year 2019

working_hours are:
- monday...friday @ 7:00-17:59
- no holiday in thuringia/germany @TEAG.de

EOF
}

if   [ ${#TIME} -eq 4 ]; then		# for testing a specific year each day at 9 o'clock
	YEAR="$TIME"
	UNIX_START="$( LC_ALL=C date +%s -d "$YEAR-01-01" )"
	UNIX_START="$(( UNIX_START + (9*3600) ))"	# at 9:00

	I=0
	while true; do {
		UNIX="$(( UNIX_START + (I*86400) ))"
		HUMN="$( LC_ALL=C date -d@$UNIX )"
		case "$HUMN" in *"$YEAR") ;; *) break ;; esac

		WORK='WORK'
		$0 $UNIX && {
			WORK='----'
			case "$HUMN" in 'Sat '*|'Sun '*) HUMN="$HUMN *" ;; *) HUMN="$HUMN !!" ;; esac
		}

		I=$(( I + 1 ))
		# e.g. 1576483200: WORK | 350 | Mon Dec 16 09:00:00 CET 2019
		printf '%s | %3d | %s\n' "$UNIX: $WORK" "$I" "$HUMN"

		case "$HUMN" in *' Dec 31 '*) exit ;; esac
	} done
elif [ "$TIME" -gt 0 ]; then
	UNIXTIME="$TIME"
else
	usage
	exit 1
fi

log()
{
	case "$DEBUG" in
		'true')
			logger -s "${1:-holiday} - $YEAR $MONTH $DAY $HOUR $MINUTE $WEEKDAY $DAYOFYEAR $DAYNAME $MONTHNAME"
		;;
	esac
}

is_weekend()
{
	# 6 = saturday
	# 7 = sunday
	test "$WEEKDAY" -eq 6 -o "$WEEKDAY" -eq 7
}

normal_office_hour()		# 7:00 - 17:59 = office
{
	case "$HOUR" in
		0|1|2|3|4|5|6)
			false
		;;
		18|19|20|21|22|23)
			false
		;;
		*)
			true
		;;
	esac
}

is_easterfriday()	# Karfreitag
{
	test "$WEEKDAY" -eq 5 || return 1
	test "$MONTH" -eq 3 -o "$MONTH" -eq 4 || return 1

	easter_sunday_get_day_of_year

	test $(( EASTER_SUNDAY - 2 )) -eq "$DAYOFYEAR" && log "is_easterfriday"
}

is_eastermonday()	# Ostermontag
{
	test "$WEEKDAY" -eq 1 || return 1
	test "$MONTH" -eq 3 -o "$MONTH" -eq 4 || return 1

	easter_sunday_get_day_of_year

	test $(( EASTER_SUNDAY + 1 )) -eq "$DAYOFYEAR" && log "is_eastermonday"
}

is_corpuschristi()	# Christi Himmelfahrt
{
	test "$WEEKDAY" -eq 4 || return 1
	test "$MONTH" -eq 4 -o "$MONTH" -eq 5 -o "$MONTH" -eq 6 || return 1

	easter_sunday_get_day_of_year

	test $(( EASTER_SUNDAY + 39 )) -eq "$DAYOFYEAR" && log "is_corpuschristi"
}

is_pentecost_monday()
{
	test "$WEEKDAY" -eq 1 || return 1
	test "$MONTH" -eq 5 -o "$MONTH" -eq 6 || return 1

	easter_sunday_get_day_of_year

	test $(( EASTER_SUNDAY + 50 )) -eq "$DAYOFYEAR" && log "is_pentecost_monday"
}

is_holiday()		# TODO: fronleichnam
{
	is_easterfriday && return 0
	is_eastermonday && return 0
	is_corpuschristi && return 0
	is_pentecost_monday && return 0

	# see:
	# https://www.feiertage.net/frei-tage.php
	# https://www.feiertage.net/csvfile.php?state=TH&year=2019&type=csv

	case "$DAY-$MONTHNAME" in
		 1-Jan) log ;;		# Neujahr
		 1-May) log ;;		# Tag der Arbeit
		20-Sep) log ;;		# Weltkindertag
		 3-Oct) log ;;		# Tag der Deutschen Einheit
		31-Oct) log ;;		# Reformationstag
		24-Dec) log ;;		# Weihnachten = TEAG/frei
		25-Dec) log ;;		# Weihnachtstag 1
		26-Dec) log ;;		# Weihnachtstag 2
		31-Dec) log ;;		# Silvester   = TEAG/frei
		*)
			false
		;;
	esac
}

easter_sunday_get_day_of_year()
{
	local a b c d e f g h j k l m n p
	# https://de.wikipedia.org/wiki/Gau%C3%9Fsche_Pessach-Formel
	# https://de.wikipedia.org/wiki/Spencers_Osterformel
	# https://de.wikipedia.org/wiki/Gau%C3%9Fsche_Osterformel#Rechenergebnisse_in_Ausnahmejahren

	# spencer modified:
	a=$(( YEAR % 19 ))
	b=$(( YEAR / 100 ))
	c=$(( YEAR % 100 ))

	d=$(( b / 4 ))
	e=$(( b % 4 ))
	f=$(( (b+8) / 25 ))
	g=$(( (b-f+1) / 3 ))
	h=$(( ( (19*a) + b - d - g + 15) % 30 ))

	i=$(( c / 4 ))
	k=$(( c % 4 ))
	l=$(( (32 + e + e + i + i - h - k) % 7 ))
	m=$(( (a + (11*h) + (22*l)) / 451 ))

	j=$(( h + l - m - m - m - m - m - m - m + 114 ))
	n=$(( j / 31 ))
	p=$(( j % 31 ))

	p=$(( p + 1 ))

	# day of the year 81...116
	EASTER_SUNDAY="$( LC_ALL=C date +'%-j' -d "$YEAR-$n-$p" )"

	export EASTER_SUNDAY
}

# YEAR=2019;MONTH=5;DAY=4;HOUR=16;MINUTE=12;WEEKDAY=6;DAYOFYEAR=124;DAYNAME=Sat;MONTHNAME=May
eval "$( LC_ALL=C date +'YEAR=%Y;MONTH=%-m;DAY=%-d;HOUR=%-H;MINUTE=%M;WEEKDAY=%u;DAYOFYEAR=%j;DAYNAME=%a;MONTHNAME=%b' -d@"$UNIXTIME" )"

# do we have free time?
if   is_weekend; then
	true
elif is_holiday; then
	true
elif ! normal_office_hour; then
	true
else
	false
fi
