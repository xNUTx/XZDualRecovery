#!/bin/sh

uploadfiles() {
	PACKAGE=$*
        cd $WORKDIR/out
	if [ "$*" = "all" ]; then
		/usr/bin/scp * nut@jupiter.fun-industries.nl:/var/www/xda/upload/
	else
		/usr/bin/scp ${LABEL}-${PACKAGE}* nut@jupiter.fun-industries.nl:/var/www/xda/upload/
	fi
	wget -O /dev/null "http://nut.xperia-files.com/?a=import&major=${MAJOR}&minor=${MINOR}&revision=${REVISION}&releasetype=${RELEASE}&folderid=WFpEdWFsUmVjb3Zlcnk="
	cd $WORKDIR
	echo "press enter to return to the Action menu!"
	read
}
