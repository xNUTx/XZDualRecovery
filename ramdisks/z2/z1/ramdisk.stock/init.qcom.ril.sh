#!/system/bin/sh
# Copyright (c) 2013, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of Linux Foundation nor
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

#
# start two rild when dsds property enabled
#
multisim=`getprop persist.multisim.config`
if [ "$multisim" = "dsds" ] || [ "$multisim" = "dsda" ]; then
        stop ril-daemon
        start ril-daemon
        start ril-daemon1
elif [ "$multisim" = "tsts" ]; then
        stop ril-daemon
        start ril-daemon
        start ril-daemon1
        start ril-daemon2
fi

carrier=`getprop persist.env.spec`
if [ "$carrier" = "ChinaTelecom" ]; then
    # Update the props.
    setprop persist.env.phone.global true
    setprop persist.env.plmn.update true

    # Remount /system with read-write permission for copy action.
    `mount -o remount,rw /system`

    # Copy the modules to system app.
    `cp /system/vendor/ChinaTelecom/system/app/RoamingSettings.apk /system/app/RoamingSettings.apk`
    `cp /system/vendor/ChinaTelecom/system/app/UniversalDownload.apk /system/app/UniversalDownload.apk`
    `chmod 644 /system/app/RoamingSettings.apk`
    `chmod 644 /system/app/UniversalDownload.apk`

    # Remount /system with read-only
    `mount -o remount,ro /system`
else
    # Update the props.
    setprop persist.env.phone.global false
    setprop persist.env.plmn.update false

    # Remount /system with read-write permission for remove action.
    `mount -o remount,rw /system`

    # Remove the modules from the system app.
    `rm /system/app/RoamingSettings.apk`
    `rm /system/app/UniversalDownload.apk`

    # Remount /system with read-only
    `mount -o remount,ro /system`
fi
