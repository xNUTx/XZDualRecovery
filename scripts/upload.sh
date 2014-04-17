#!/bin/sh

uploadfiles() {
	PACKAGE=$*
        cd $WORKDIR/out
	if [ "$*" = "all" ]; then
		/usr/bin/scp * nut@jupiter.fun-industries.nl:/var/www/xda/upload/
	else
		/usr/bin/scp ${LABEL}-${PACKAGE}* nut@jupiter.fun-industries.nl:/var/www/xda/upload/
	fi
	wget -O /dev/null http://www.fun-industries.nl/xda/update.php
	cd $WORKDIR
	echo "press enter to return to the Action menu!"
	read
}
