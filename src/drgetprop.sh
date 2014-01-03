#!/bin/sh

set +x
#_PATH="$PATH"
#export PATH="/system/xbin"

DRGETPROP() {

	#PROP=`/system/bin/getprop $*`
	PROP=""
	
	if [ "$PROP" = "" ]; then

		PROP=`grep "$1" ./build.prop | awk -F'=' '{ print $NF }'`

	fi

	echo "$PROP"

}

echo "Checking device model..."
MODEL=$(DRGETPROP ro.product.model)
VERSION=$(DRGETPROP ro.build.id)
PHNAME=$(DRGETPROP ro.semc.product.name)

echo "Model found: $MODEL ($PHNAME - $VERSION)"