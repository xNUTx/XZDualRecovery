#!/bin/bash

cleanuptmp() {
	echo "cleaning up..."
	rm -rf $WORKDIR/tmp/*
}

cleanupout() {
	echo "removing previous ${LABEL} builds..."
	rm -f $WORKDIR/out/${LABEL}-*
}

copysource() {
	# Copy base packages to tmp
	cp -r $WORKDIR/includes/* $WORKDIR/tmp/
}

doall() {
	echo "Increment revision? (y/n)"
	read answer
	if [ "$answer" = "y" -o "$answer" = "Y" ]; then
		incrrevision
	fi
	cleanuptmp
	cleanupout
	copysource
	maketwrp auto
	makecwm auto
	makephilz auto
	if [ -d "$WORKDIR/ramdisks/${DRPATH}/ramdisk.stock" ]; then
		makestock auto
	fi
	packflashable
	packinstaller
	echo "Upload files now? (y/n)"
	read answer
	if [ "$answer" = "y" -o "$answer" = "Y" ]; then
		uploadfiles
	fi
}

packflashable() {
	cd $WORKDIR/tmp/
	echo "Flashable: copying files to their locations..."
	# Flashable
	cp $WORKDIR/tmp/recovery.cwm.cpio.lzma $WORKDIR/tmp/flashable/system/bin/recovery.cwm.cpio.lzma
	cp $WORKDIR/tmp/recovery.philz.cpio.lzma $WORKDIR/tmp/flashable/system/bin/recovery.philz.cpio.lzma
	cp $WORKDIR/tmp/recovery.twrp.cpio.lzma $WORKDIR/tmp/flashable/system/bin/recovery.twrp.cpio.lzma
	if [ -f "$WORKDIR/tmp/ramdisk.stock.cpio.lzma" ]; then
		cp $WORKDIR/tmp/ramdisk.stock.cpio.lzma $WORKDIR/tmp/flashable/tmp/ramdisk.stock.cpio.lzma
	fi
	cp $WORKDIR/src/installstock.sh $WORKDIR/tmp/flashable/tmp/installstock.sh
	cp $WORKDIR/src/mr.sh $WORKDIR/tmp/flashable/system/bin/mr
	cp $WORKDIR/src/chargemon.sh $WORKDIR/tmp/flashable/system/bin/chargemon
	cp $WORKDIR/src/dualrecovery.sh $WORKDIR/tmp/flashable/system/bin/dualrecovery.sh
	cp $WORKDIR/src/rickiller.sh $WORKDIR/tmp/flashable/system/bin/rickiller.sh
	cp $WORKDIR/src/disableric.sh $WORKDIR/tmp/flashable/tmp/disableric
	cp $WORKDIR/src/installdisableric.sh $WORKDIR/tmp/flashable/tmp/installdisableric.sh
	cp $WORKDIR/tmp/busybox $WORKDIR/tmp/flashable/system/xbin/busybox
	cp $WORKDIR/src/backupstockbinaries.sh $WORKDIR/tmp/flashable/backupstockbinaries.sh
	cp $WORKDIR/src/updater-script $WORKDIR/tmp/flashable/META-INF/com/google/android/updater-script
	echo "version=${MAJOR}.${MINOR}.${REVISION}-${RELEASE}" > $WORKDIR/tmp/flashable/dr.prop

	cd $WORKDIR/tmp/flashable
	echo "Creating flashable zip..."
	zip -r -b /tmp $WORKDIR/out/${LABEL}-lockeddualrecovery${MAJOR}.${MINOR}.${REVISION}-${RELEASE}.flashable.zip *
	chmod 644 $WORKDIR/out/${LABEL}-lockeddualrecovery${MAJOR}.${MINOR}.${REVISION}-${RELEASE}.flashable.zip
	zip -T $WORKDIR/out/${LABEL}-lockeddualrecovery${MAJOR}.${MINOR}.${REVISION}-${RELEASE}.flashable.zip
}

packinstaller() {
	echo "Installer: copying files to their locations..."
	cp $WORKDIR/tmp/recovery.cwm.cpio.lzma $WORKDIR/tmp/installer/lockeddualrecovery/files/recovery.cwm.cpio.lzma
	cp $WORKDIR/tmp/recovery.philz.cpio.lzma $WORKDIR/tmp/installer/lockeddualrecovery/files/recovery.philz.cpio.lzma
	cp $WORKDIR/tmp/recovery.twrp.cpio.lzma $WORKDIR/tmp/installer/lockeddualrecovery/files/recovery.twrp.cpio.lzma
	if [ -f "$WORKDIR/tmp/ramdisk.stock.cpio.lzma" ]; then
		cp $WORKDIR/tmp/ramdisk.stock.cpio.lzma $WORKDIR/tmp/installer/lockeddualrecovery/files/ramdisk.stock.cpio.lzma
	fi
	cp $WORKDIR/tmp/busybox $WORKDIR/tmp/installer/lockeddualrecovery/files/busybox
	cp $WORKDIR/src/mr.sh $WORKDIR/tmp/installer/lockeddualrecovery/files/mr.sh
	cp $WORKDIR/src/chargemon.sh $WORKDIR/tmp/installer/lockeddualrecovery/files/chargemon.sh
	cp $WORKDIR/src/dualrecovery.sh $WORKDIR/tmp/installer/lockeddualrecovery/files/dualrecovery.sh
	cp $WORKDIR/src/rickiller.sh $WORKDIR/tmp/installer/lockeddualrecovery/files/rickiller.sh
	cp $WORKDIR/src/disableric.sh $WORKDIR/tmp/installer/lockeddualrecovery/files/disableric
	cp $WORKDIR/src/installrecovery.sh $WORKDIR/tmp/installer/lockeddualrecovery/files/installrecovery.sh
	cp $WORKDIR/src/install.bat $WORKDIR/tmp/installer/lockeddualrecovery/install.bat
	cp $WORKDIR/src/install.sh $WORKDIR/tmp/installer/lockeddualrecovery/install.sh
	echo "version=${MAJOR}.${MINOR}.${REVISION}-${RELEASE}" > $WORKDIR/tmp/installer/lockeddualrecovery/files/dr.prop

	cd $WORKDIR/tmp/installer/
	echo "Creating installer zip..."
	zip -r -b /tmp $WORKDIR/out/${LABEL}-lockeddualrecovery${MAJOR}.${MINOR}.${REVISION}-${RELEASE}.installer.zip *
	chmod 644 $WORKDIR/out/${LABEL}-lockeddualrecovery${MAJOR}.${MINOR}.${REVISION}-${RELEASE}.installer.zip
	zip -T $WORKDIR/out/${LABEL}-lockeddualrecovery${MAJOR}.${MINOR}.${REVISION}-${RELEASE}.installer.zip
}
