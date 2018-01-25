#!/bin/bash

c=""
w=""

while getopts "c:w:" opt; do
	case $opt in
		c)
			c="$OPTARG"
			;;
		w)
			w="$OPTARG"
			;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			exit 1
			;;
	esac
done


$(dirname $0)/watch.sh -p $$ -w $w &

while : ; do
  eval $c
done
