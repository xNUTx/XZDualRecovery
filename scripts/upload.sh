#!/bin/sh

uploadfiles() {
	PACKAGE=$*
        cd $WORKDIR/out
	if [ "$*" = "all" ]; then
		/usr/bin/scp * nut@jupiter.fun-industries.nl:/var/www/xda/upload/
	else
		/usr/bin/scp ${LABEL}-${PACKAGE}* nut@jupiter.fun-industries.nl:/var/www/xda/upload/
	fi
	cd $WORKDIR
	echo "Put the uploaded files online? (y/n)"
	read answer
	if [ "$answer" = "y" -o "$answer" = "Y" ]; then
		wget -O /dev/null "http://nut.xperia-files.com/feature/major/${MAJOR}/minor/${MINOR}/revision/${REVISION}/releasetype/${RELEASE}/import.html"
	fi
	echo "press enter to return to the Action menu!"
	read
}
