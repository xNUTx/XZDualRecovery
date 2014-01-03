#!/bin/sh

uploadfiles() {
        cd $WORKDIR/out
	/usr/bin/scp ${LABEL}-* nut@jupiter.fun-industries.nl:/var/www/xda/upload/
	wget -O /dev/null http://www.fun-industries.nl/xda/update.php
	cd $WORKDIR
	echo "press enter to return to the Action menu!"
	read
}
