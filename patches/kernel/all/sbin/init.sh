#!/sbin/busybox sh

/sbin/taskset -p -c 0 1
/sbin/busybox sync
/sbin/taskset -c 0 /sbin/2nd-init
exit
