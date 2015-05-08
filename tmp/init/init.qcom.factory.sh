#!/system/bin/sh
# Copyright (c) 2009-2013, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

# Actions on fast factory test mode
    chown -h bluetooth.bluetooth /sys/module/bluetooth_power/parameters/power
    chown -h bluetooth.bluetooth /sys/class/rfkill/rfkill0/type
    chown -h bluetooth.bluetooth /sys/class/rfkill/rfkill0/state
    chown -h bluetooth.bluetooth /proc/bluetooth/sleep/proto
    chown -h system.system /sys/module/sco/parameters/disable_esco
    chown -h bluetooth.bluetooth /sys/module/hci_smd/parameters/hcismd_set
    chmod -h 0660 /sys/module/bluetooth_power/parameters/power
    chmod -h 0660 /sys/module/hci_smd/parameters/hcismd_set
    chmod -h 0660 /sys/class/rfkill/rfkill0/state
    chmod -h 0660 /proc/bluetooth/sleep/proto
    chown -h bluetooth.bluetooth /dev/ttyHS0
    chmod -h 0660 /dev/ttyHS0
    chown -h bluetooth.bluetooth /sys/devices/platform/msm_serial_hs.0/clock
    chmod -h 0660 /sys/devices/platform/msm_serial_hs.0/clock

    chmod -h 0660 /dev/ttyHS2
    chown -h bluetooth.bluetooth /dev/ttyHS2

    #Create QMUX deamon socket area
    mkdir -p /dev/socket/qmux_radio
    chown -h radio.radio /dev/socket/qmux_radio
    chmod -h 2770 /dev/socket/qmux_radio
    mkdir -p /dev/socket/qmux_audio
    chown -h media.audio /dev/socket/qmux_audio
    chmod -h 2770 /dev/socket/qmux_audio
    mkdir -p /dev/socket/qmux_bluetooth
    chown -h bluetooth.bluetooth /dev/socket/qmux_bluetooth
    chmod -h 2770 /dev/socket/qmux_bluetooth
    mkdir -p /dev/socket/qmux_gps
    chown -h gps.gps /dev/socket/qmux_gps
    chmod -h 2770 /dev/socket/qmux_gps

    # Allow QMUX daemon to assign port open wait time
    chown -h radio.radio /sys/devices/virtual/hsicctl/hsicctl0/modem_wait

    setprop wifi.interface wlan0

    setprop ro.telephony.call_ring.multiple false

    #Set SUID bit for usbhub
    chmod -h 4755 /system/bin/usbhub
    chmod -h 755 /system/bin/usbhub_init

    #Remove SUID bit for iproute2 ip tool
    chmod -h 0755 /system/bin/ip

    chmod -h 0444 /sys/devices/platform/msm_hsusb/gadget/usb_state

    # setup permissions for fb1 related nodes
    chown -h system.graphics /sys/class/graphics/fb1/hpd
    chown -h system.system /sys/class/graphics/fb1/hdcp/tp
    chmod -h 0664 /sys/devices/virtual/graphics/fb1/hpd
    chmod -h 0664 /sys/devices/virtual/graphics/fb1/hdcp/tp
    chmod -h 0664 /sys/devices/virtual/graphics/fb1/video_mode
    chmod -h 0664 /sys/devices/virtual/graphics/fb1/format_3d

    # Change owner and group for media server and surface flinger
    chown -h system.system /sys/devices/virtual/graphics/fb1/format_3d

    #For bridgemgr daemon to inform the USB driver of the correct transport
    chown -h radio.radio /sys/class/android_usb/f_rmnet_smd_sdio/transport

    #To allow interfaces to get v6 address when tethering is enabled
    echo 2 > /proc/sys/net/ipv6/conf/rmnet0/accept_ra
    echo 2 > /proc/sys/net/ipv6/conf/rmnet1/accept_ra
    echo 2 > /proc/sys/net/ipv6/conf/rmnet2/accept_ra
    echo 2 > /proc/sys/net/ipv6/conf/rmnet3/accept_ra
    echo 2 > /proc/sys/net/ipv6/conf/rmnet4/accept_ra
    echo 2 > /proc/sys/net/ipv6/conf/rmnet5/accept_ra
    echo 2 > /proc/sys/net/ipv6/conf/rmnet6/accept_ra
    echo 2 > /proc/sys/net/ipv6/conf/rmnet7/accept_ra
    echo 2 > /proc/sys/net/ipv6/conf/rmnet_sdio0/accept_ra
    echo 2 > /proc/sys/net/ipv6/conf/rmnet_sdio1/accept_ra
    echo 2 > /proc/sys/net/ipv6/conf/rmnet_sdio2/accept_ra
    echo 2 > /proc/sys/net/ipv6/conf/rmnet_sdio3/accept_ra
    echo 2 > /proc/sys/net/ipv6/conf/rmnet_sdio4/accept_ra
    echo 2 > /proc/sys/net/ipv6/conf/rmnet_sdio5/accept_ra
    echo 2 > /proc/sys/net/ipv6/conf/rmnet_sdio6/accept_ra
    echo 2 > /proc/sys/net/ipv6/conf/rmnet_sdio7/accept_ra
    echo 2 > /proc/sys/net/ipv6/conf/rmnet_usb0/accept_ra
    echo 2 > /proc/sys/net/ipv6/conf/rmnet_usb1/accept_ra
    echo 2 > /proc/sys/net/ipv6/conf/rmnet_usb2/accept_ra
    echo 2 > /proc/sys/net/ipv6/conf/rmnet_usb3/accept_ra

    # To prevent out of order acknowledgements from making
    # connection tracking to treat them as not belonging to
    # the connection they belong to.
    # Otherwise, a weird issue happens in which some long
    # connections on high-throughput links get dropped when
    # an ack packet comes out of order
    echo 1 > /proc/sys/net/netfilter/nf_conntrack_tcp_be_liberal

#TODO:
# basic network init
#    ifup lo
#    hostname localhost
#    domainname localdomain

# set RLIMIT_NICE to allow priorities from 19 to -20
#    setrlimit 13 40 40

# Memory management.  Basic kernel parameters, and allow the high
# level system server to be able to adjust the kernel OOM driver
# parameters to match how it is managing things.
    echo 1 > /proc/sys/vm/overcommit_memory
    echo 4 > /proc/sys/vm/min_free_order_shift
    chown -h root.system /sys/module/lowmemorykiller/parameters/adj
    chmod -h 0664 /sys/module/lowmemorykiller/parameters/adj
    chown -h root.system /sys/module/lowmemorykiller/parameters/minfree
    chmod -h 0664 /sys/module/lowmemorykiller/parameters/minfree

    # Tweak background writeout
    echo 200 > /proc/sys/vm/dirty_expire_centisecs
    echo 5 > /proc/sys/vm/dirty_background_ratio

    # Permissions for System Server and daemons.
    chown -h radio.system /sys/android_power/state
    chown -h radio.system /sys/android_power/request_state
    chown -h radio.system /sys/android_power/acquire_full_wake_lock
    chown -h radio.system /sys/android_power/acquire_partial_wake_lock
    chown -h radio.system /sys/android_power/release_wake_lock
    chown -h system.system /sys/power/autosleep
    chown -h system.system /sys/power/state
    chown -h system.system /sys/power/wakeup_count
    chown -h radio.system /sys/power/wake_lock
    chown -h radio.system /sys/power/wake_unlock
    chmod -h 0660 /sys/power/state
    chmod -h 0660 /sys/power/wake_lock
    chmod -h 0660 /sys/power/wake_unlock

    chown -h system.system /sys/devices/system/cpu/cpufreq/interactive/timer_rate
    chmod -h 0660 /sys/devices/system/cpu/cpufreq/interactive/timer_rate
    chown -h system.system /sys/devices/system/cpu/cpufreq/interactive/min_sample_time
    chmod -h 0660 /sys/devices/system/cpu/cpufreq/interactive/min_sample_time
    chown -h system.system /sys/devices/system/cpu/cpufreq/interactive/hispeed_freq
    chmod -h 0660 /sys/devices/system/cpu/cpufreq/interactive/hispeed_freq
    chown -h system.system /sys/devices/system/cpu/cpufreq/interactive/go_hispeed_load
    chmod -h 0660 /sys/devices/system/cpu/cpufreq/interactive/go_hispeed_load
    chown -h system.system /sys/devices/system/cpu/cpufreq/interactive/above_hispeed_delay
    chmod -h 0660 /sys/devices/system/cpu/cpufreq/interactive/above_hispeed_delay
    chown -h system.system /sys/devices/system/cpu/cpufreq/interactive/boost
    chmod -h 0660 /sys/devices/system/cpu/cpufreq/interactive/boost
    chown -h system.system /sys/devices/system/cpu/cpufreq/interactive/boostpulse
    chown -h system.system /sys/devices/system/cpu/cpufreq/interactive/input_boost
    chmod -h 0660 /sys/devices/system/cpu/cpufreq/interactive/input_boost
    chown -h system.system /sys/devices/system/cpu/cpufreq/interactive/boostpulse_duration
    chmod -h 0660 /sys/devices/system/cpu/cpufreq/interactive/boostpulse_duration

    # Assume SMP uses shared cpufreq policy for all CPUs
    chown -h system.system /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
    chmod -h 0660 /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq

    chown -h system.system /sys/class/timed_output/vibrator/enable
    chown -h system.system /sys/class/leds/keyboard-backlight/brightness
    chown -h system.system /sys/class/leds/lcd-backlight/brightness
    chown -h system.system /sys/class/leds/button-backlight/brightness
    chown -h system.system /sys/class/leds/jogball-backlight/brightness
    chown -h system.system /sys/class/leds/red/brightness
    chown -h system.system /sys/class/leds/green/brightness
    chown -h system.system /sys/class/leds/blue/brightness
    chown -h system.system /sys/class/leds/red/device/grpfreq
    chown -h system.system /sys/class/leds/red/device/grppwm
    chown -h system.system /sys/class/leds/red/device/blink
    chown -h system.system /sys/class/leds/red/brightness
    chown -h system.system /sys/class/leds/green/brightness
    chown -h system.system /sys/class/leds/blue/brightness
    chown -h system.system /sys/class/leds/red/device/grpfreq
    chown -h system.system /sys/class/leds/red/device/grppwm
    chown -h system.system /sys/class/leds/red/device/blink
    chown -h system.system /sys/class/timed_output/vibrator/enable
    chown -h system.system /sys/module/sco/parameters/disable_esco
    chown -h system.system /sys/kernel/ipv4/tcp_wmem_min
    chown -h system.system /sys/kernel/ipv4/tcp_wmem_def
    chown -h system.system /sys/kernel/ipv4/tcp_wmem_max
    chown -h system.system /sys/kernel/ipv4/tcp_rmem_min
    chown -h system.system /sys/kernel/ipv4/tcp_rmem_def
    chown -h system.system /sys/kernel/ipv4/tcp_rmem_max
    chown -h root radio /proc/cmdline

# Define TCP buffer sizes for various networks
#   ReadMin, ReadInitial, ReadMax, WriteMin, WriteInitial, WriteMax,
    setprop net.tcp.buffersize.default 4096,87380,110208,4096,16384,110208
    setprop net.tcp.buffersize.wifi    524288,1048576,2097152,262144,524288,1048576
    setprop net.tcp.buffersize.lte     524288,1048576,2097152,262144,524288,1048576
    setprop net.tcp.buffersize.umts    4094,87380,110208,4096,16384,110208
    setprop net.tcp.buffersize.hspa    4094,87380,1220608,4096,16384,1220608
    setprop net.tcp.buffersize.hsupa   4094,87380,1220608,4096,16384,1220608
    setprop net.tcp.buffersize.hsdpa   4094,87380,1220608,4096,16384,1220608
    setprop net.tcp.buffersize.hspap   4094,87380,1220608,4096,16384,1220608
    setprop net.tcp.buffersize.edge    4093,26280,35040,4096,16384,35040
    setprop net.tcp.buffersize.gprs    4092,8760,11680,4096,8760,11680
    setprop net.tcp.buffersize.evdo    4094,87380,262144,4096,16384,262144

# Assign TCP buffer thresholds to be ceiling value of technology maximums
# Increased technology maximums should be reflected here.
    echo 2097152 > /proc/sys/net/core/rmem_max
    echo 2097152 > /proc/sys/net/core/wmem_max

# Set the property to indicate type of virtual display to 0
# 0 indicates that virtual display is not a Wifi display and that the
# session is not exercised through RemoteDisplay in the android framework
    setprop persist.sys.wfd.virtual 0

# Set this property so surfaceflinger is not started by system_init
    setprop system_init.startsurfaceflinger 0

# Start the following services needed for fftm
    start config_bluetooth
    start media
    start fastmmi
    start adbd
    start qcom-post-boot
    start rmt_storage
    start qcom-c_main-sh
    start irsc_util
    start qcamerasvr
    start qcom-usb-sh
    start qcomsysd
