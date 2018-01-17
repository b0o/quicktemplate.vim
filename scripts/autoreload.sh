#!/bin/bash

f=""
w=""

while getopts "f:w:" opt; do
	case $opt in
		f)
			f="$OPTARG"
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
  nvim $f
done
