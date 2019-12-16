why
===

I needed an easy way to check, if a given unix timestamp falls into holiday/vacation/sparetime.


example1
========

a cronjob which is only active, if nobody is there

```
* * * * * no_working_hours.sh && run_task
```


example2
========

a cronjob which is only active, if everybody is working

```
* * * * * no_working_hours.sh || run_task
```


example3
========

read a csv-file (e.g. a call-log) linewise and output all events which are not during working ours.

```
while read -r LINE; do
  # e.g. 1608883200;Call from 0176/12345678
  UNIX="$( echo "$LINE" | cut -d';' -f1 )"

  no_working_hours.sh "$UNIX" && \
    echo "write paper for special working time"
done <FILE
```


example 4
=========

debug a given year and show all days. \\
symbol '!!' means holiday which is not on weekend. \\
symbol asterisk means weekend.

```
# no_working_hours.sh 2019 | grep -c WORK
248

# no_working_hours.sh 2020 | grep -c WORK
253

# no_working_hours.sh 2019

1546329600: ---- |   1 | Tue Jan  1 09:00:00 CET 2019 !!
1546416000: WORK |   2 | Wed Jan  2 09:00:00 CET 2019
1546502400: WORK |   3 | Thu Jan  3 09:00:00 CET 2019
1546588800: WORK |   4 | Fri Jan  4 09:00:00 CET 2019
1546675200: ---- |   5 | Sat Jan  5 09:00:00 CET 2019 *
1546761600: ---- |   6 | Sun Jan  6 09:00:00 CET 2019 *
1546848000: WORK |   7 | Mon Jan  7 09:00:00 CET 2019

[...]

1576915200: ---- | 355 | Sat Dec 21 09:00:00 CET 2019 *
1577001600: ---- | 356 | Sun Dec 22 09:00:00 CET 2019 *
1577088000: WORK | 357 | Mon Dec 23 09:00:00 CET 2019
1577174400: ---- | 358 | Tue Dec 24 09:00:00 CET 2019 !!
1577260800: ---- | 359 | Wed Dec 25 09:00:00 CET 2019 !!
1577347200: ---- | 360 | Thu Dec 26 09:00:00 CET 2019 !!
1577433600: WORK | 361 | Fri Dec 27 09:00:00 CET 2019
1577520000: ---- | 362 | Sat Dec 28 09:00:00 CET 2019 *
1577606400: ---- | 363 | Sun Dec 29 09:00:00 CET 2019 *
1577692800: WORK | 364 | Mon Dec 30 09:00:00 CET 2019
1577779200: ---- | 365 | Tue Dec 31 09:00:00 CET 2019 !!
```
