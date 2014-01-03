SKIP=5
INPUTID=0
INPUTNID=64

for INPUT in `find /dev/input/event*`; do

	if [ $INPUTID -lt $SKIP ]; then
		INPUTID=`expr $INPUTID + 1`
		continue
	fi

	BOOTREC_EVENT_NODE="$INPUT c 13 $INPUTNID"
	BOOTREC_EVENT="$INPUT"
	mknod -m 600 ${BOOTREC_EVENT_NODE}

	cat ${BOOTREC_EVENT} > /dev/keycheck$INPUTID &

	INPUTID=`expr $INPUTID + 1`

done

echo 300 > /sys/class/timed_output/vibrator/enable

EXECL sleep 3

INPUTID=0

for INPUT in `find /dev/input/event*`; do

	if [ $INPUTID -lt $SKIP ]; then
		INPUTID=`expr $INPUTID + 1`
		continue
	fi

	hexdump < /dev/keycheck$INPUTID > /dev/keycheckout$INPUTID

	VOLUKEYCHECK=`cat /dev/keycheck$INPUTID | grep '0001 0073' | wc -l`
	VOLDKEYCHECK=`cat /dev/keycheck$INPUTID | grep '0001 0072' | wc -l`

	if [ ! -z "$VOLUKEYCHECK" ]; then
		ECHOL "Recorded VOL-UP on $INPUT!"
		KEYCHECK="UP"
	elif [ ! -z "$VOLDKEYCHECK" ]; then
		ECHOL "Recorded VOL-DOWN on $INPUT!"
		KEYCHECK="DOWN"
	fi

	INPUTID=`expr $INPUTID + 1`

done

