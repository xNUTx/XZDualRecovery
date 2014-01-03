#!/sbin/busybox sh
set +x

echo "xperiafix ran ok" > /tmp/xperiablfix.log

BOOTREC_LED_RED="/sys/class/leds/$(ls -1 /sys/class/leds|grep red)/brightness"
BOOTREC_LED_GREEN="/sys/class/leds/$(ls -1 /sys/class/leds|grep green)/brightness"
BOOTREC_LED_BLUE="/sys/class/leds/$(ls -1 /sys/class/leds|grep blue)/brightness"

SETLED() {
        if [ "$1" = "on" ]; then

                ECHOL "Turn on LED R: $2 G: $3 B: $4"
                echo "$2" > ${BOOTREC_LED_RED}
                echo "$3" > ${BOOTREC_LED_GREEN}
                echo "$4" > ${BOOTREC_LED_BLUE}

        else

                ECHOL "Turn off LED"
                echo "0" > ${BOOTREC_LED_RED}
                echo "0" > ${BOOTREC_LED_GREEN}
                echo "0" > ${BOOTREC_LED_BLUE}

        fi
}


for LOCKINGPID in `/sbin/busybox lsof | awk '{print $1" "$2}' | grep -E "/bin|/system|/data|/cache" | awk '{print $1}'`; do
	BINARY=$(ps | grep " $LOCKINGPID " | grep -v "grep" | awk '{print $5}')
        echo "File ${BINARY} is locking a critical partition running as PID ${LOCKINGPID}, killing it now!" >> /tmp/xperiablfix.log
	kill -9 $LOCKINGPID
done

FLASHLED() {
	SETLED on 255 0 0
	sleep 1
	SETLED off
	sleep 1
	FLASHLED
}

REMAINING=$(/sbin/busybox lsof | awk '{print $1" "$2}' | grep -E "/bin|/system|/data|/cache" | wc -l)
if [ $REMAINING -gt 0 ]; then
	FLASHLED
fi
