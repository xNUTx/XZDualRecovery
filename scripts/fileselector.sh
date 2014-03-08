#!/bin/bash

chosen=""

SELECTfile() {

	clear

	cd $*/

	grep_cmd=`ls -1 | grep -E "\\.sin$|\\.img$" | sort -f`

	if [ "$grep_cmd" == "" ]; then
		echo "Error: No sin or img files found!"
		return 1
	fi

	count=0

	echo "" > temp.list
	echo "All kernel files:" >> temp.list
	echo "" >> temp.list

	for filename in $grep_cmd; do

		count=$(($count+1))

		# Store file names in an array
		file_array[$count]=$filename
		echo "  ($count) $filename" >> temp.list

	done

	more temp.list
	rm -f temp.list

	echo ""
	echo -n "Enter file number (0 = cancel): "

	read enterNumber

	if [ "$enterNumber" == "0" ]; then
		echo "Cancelled selection!"
		return 1

	# Verify input is a number
	elif [ "`echo $enterNumber | sed 's/[0-9]*//'`" == "" ]; then

		file_chosen=${file_array[$enterNumber]}

		if [ "$file_chosen" == "" ]; then
			return 1
		fi

		chosen=$file_chosen

	fi

	return 0

}
