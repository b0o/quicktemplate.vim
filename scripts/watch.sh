#!/bin/bash

pid=$$
ppid=0
watch=""

while getopts "p:w:" opt; do
	case $opt in
		p)
			ppid="$OPTARG"
			;;
		w)
			watch="$OPTARG"
			;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			exit 1
			;;
	esac
done

[[ $ppid == 0 ]] && {
	echo "Error: A PID must be specified with -p" >&2
exit 1
}


# sh -c "echo $watch | entr -p kill $cpids" &

while true; do
	inotifywait $watch -e CREATE,MODIFY,DELETE
	cpids="$(ps --ppid $ppid --format=pid --no-headers | grep -v $pid)"
	kill -SIGTERM $cpids
done
