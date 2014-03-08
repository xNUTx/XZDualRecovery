#!/bin/bash

selectkernel() {

	clear

	KERNELPATH="$WORKDIR/kernels/${DRPATH}"

	cd $KERNELPATH

	grep_cmd=`ls -1 | grep -E "\\.elf|\\.sin$|\\.img$" | sort -f`

	if [ "$grep_cmd" == "" ]; then
		echo "Error: No sin, img or elf files found!"
		return 1
	fi

	count=0

	echo "" > temp.list
	echo "Available kernel files:" >> temp.list
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

		KERNEL=$file_chosen

	fi

	return 0

}

unpackkernel() {

	if [ ! -f "$KERNELPATH/$KERNEL" ]; then
		echo "Kernel file has gone away?"
		read
		return 1
	fi

	mkdir $WORKDIR/tmp/kernelparts
	mkdir $WORKDIR/tmp/kernelramdisk

	$WORKDIR/bin/php $WORKDIR/bin/unpack.php $KERNELPATH/$KERNEL $WORKDIR/tmp/kernelparts/

	if [ "$(grep '.sin' $KERNEL | wc -l)" = "1" ]; then
		KERNEL=$(basename $KERNEL .sin)
	elif [ "$(grep '.img' $KERNEL | wc -l)" = "1" ]; then
		KERNEL=$(basename $KERNEL .img)
	elif [ "$(grep '.elf' $KERNEL | wc -l)" = "1" ]; then
		KERNEL=$(basename $KERNEL .elf)
	fi

	cd $WORKDIR/tmp/kernelramdisk/

	gunzip -c $WORKDIR/tmp/kernelparts/$KERNEL.ramdisk.cpio.gz | cpio -i -u

	cd $WORKDIR

	if [ "$1" = "auto" ]; then
		sleep 2
	else
		echo "Press enter to return to the recovery menu!"
		read
	fi

}

patchramdisk() {

	echo "Patching kernel ramdisk."

	mv $WORKDIR/tmp/kernelramdisk/init.rc $WORKDIR/tmp/kernelramdisk/init.original.rc
	cp -r $WORKDIR/patches/kernel/all/* $WORKDIR/tmp/kernelramdisk/
	cp $WORKDIR/includes/busybox $WORKDIR/tmp/kernelramdisk/sbin/

	if [ "$1" = "auto" ]; then
		sleep 2
	else
		echo "Press enter to return to the recovery menu!"
		read
	fi

}

packramdisk() {

	echo "Packing new kernel ramdisk."

	MKBOOTFS=$WORKDIR/bin/mkbootfs

	cp $WORKDIR/tmp/recovery.* $WORKDIR/tmp/kernelramdisk/sbin/
	$MKBOOTFS $WORKDIR/tmp/kernelramdisk > $WORKDIR/tmp/$KERNEL.ramdisk.cpio
	gzip -fq $WORKDIR/tmp/$KERNEL.ramdisk.cpio

	RAMDISK="$WORKDIR/tmp/$KERNEL.ramdisk.cpio.gz"

	if [ "$1" = "auto" ]; then
		sleep 2
	else
		echo "Press enter to return to the recovery menu!"
		read
	fi

}

packkernel() {

	echo "Packing kernel image."

	DTIMAGE=""

	if [ -f "$WORKDIR/tmp/kernelparts/$KERNEL.dt.img" ]; then

		DTIMAGE="$WORKDIR/tmp/kernelparts/$KERNEL.dt.img"

	fi

	BOOTCMD=""

	if [ -f "$WORKDIR/tmp/kernelparts/$KERNEL.boot.cmd" ]; then

		BOOTCMD=$(cat $WORKDIR/tmp/kernelparts/$KERNEL.boot.cmd)

	fi

	ZIMAGE=""

	if [ -f "$WORKDIR/tmp/kernelparts/$KERNEL.zImage" ]; then

		ZIMAGE="$WORKDIR/tmp/kernelparts/$KERNEL.zImage"

	fi

	if [ ! -f "$RAMDISK" -o "$BOOTCMD" = "" -o "$ZIMAGE" = "" ] || [ "$TAGS" = "yes" -a "$DTIMAGE" = "" ]; then
		echo "Not all parameters are set, without all of them set there is no way to successfully build a kernel image!"
		read
		return 1
	fi

	MKBOOTCMDS="$WORKDIR/bin/mkbootimg"
	MKBOOTCMDS="$MKBOOTCMDS --base $BASE"
	MKBOOTCMDS="$MKBOOTCMDS --kernel $ZIMAGE"
	MKBOOTCMDS="$MKBOOTCMDS --ramdisk $RAMDISK"
	MKBOOTCMDS="$MKBOOTCMDS --ramdisk_offset $RAMDISKOFFSET"
	if [ "$TAGS" = "yes" ]; then
		MKBOOTCMDS="$MKBOOTCMDS --dt $DTIMAGE"
		MKBOOTCMDS="$MKBOOTCMDS --tags_offset $TAGSOFFSET"
	fi
	MKBOOTCMDS="$MKBOOTCMDS --pagesize $PAGESIZE"
	MKBOOTCMDS="$MKBOOTCMDS --cmdline \"$BOOTCMD\""
	MKBOOTCMDS="$MKBOOTCMDS --output $WORKDIR/tmp/$KERNEL.img"

	echo $MKBOOTCMDS

	eval $MKBOOTCMDS

	if [ "$1" = "auto" ]; then

		if [ "`$WORKDIR/bin/adb devices | grep '\<device\>' | wc -l`" = "1" ]; then
			echo "Flash it to the connected device? (y/n)"
			read answer
			if [ "$answer" = "y" -o "$answer" = "Y" ]; then
				$WORKDIR/bin/adb reboot bootloader
				$WORKDIR/bin/fastboot flash boot $WORKDIR/tmp/$KERNEL.img
				if [ "$?" = "0" ]; then
					$WORKDIR/bin/fastboot reboot
				fi
			fi
		fi

	fi

	if [ "$1" = "auto" ]; then
		sleep 2
	else
		echo "Press enter to return to the recovery menu!"
		read
	fi

}
