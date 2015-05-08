#!/system/bin/sh
# *********************************************************************
# * Copyright 2011 (C) Sony Ericsson Mobile Communications AB.        *
# * Copyright 2012 (C) Sony Mobile Communications AB.                 *
# * All rights, including trade secret rights, reserved.              *
# *********************************************************************
#

# use product specific script if exist.
if [ -f '/init.usbmode.product.sh' ] ; then
  exit `/init.usbmode.product.sh`
fi

TAG="usb"
VENDOR_ID=0FCE
PID_PREFIX=0

get_pid_prefix()
{
  case $1 in
    "mass_storage")
      PID_PREFIX=E
      ;;

    "mass_storage,adb")
      PID_PREFIX=6
      ;;

    "mtp")
      PID_PREFIX=0
      ;;

    "mtp,adb")
      PID_PREFIX=5
      ;;

    "mtp,cdrom")
      PID_PREFIX=4
      ;;

    "mtp,cdrom,adb")
      PID_PREFIX=4
# workaround for ICS framework. Don't enable ADB for PCC mode.
      USB_FUNCTION="mtp,cdrom"
      ;;

    "rndis")
      PID_PREFIX=7
      ;;

    "rndis,adb")
      PID_PREFIX=8
      ;;

    "ncm")
      PID_PREFIX=1
      ;;

    "ncm,adb")
      PID_PREFIX=2
      ;;

    *)
      /system/bin/log -t ${TAG} -p e "unsupported composition: $1"
      return 1
      ;;
  esac

  return 0
}

set_engpid()
{
  case ${PID_SUFFIX_PROP} in
    "196") # products which have MDM
      case $1 in
        "mass_storage,adb") PID_PREFIX=1 ;;
        "mtp,adb") PID_PREFIX=F ;;
        *)
         /system/bin/log -t ${TAG} -p i "No eng PID for: $1"
         return 1
         ;;
      esac
      DIAG_CLIENT="diag,diag_mdm"
      SERIAL_TRANSPORT="smd,tty,hsuart"
      RMNET_TRANSPORT="smd,bam,hsuart,hsuart"
      ;;
    *)
      SUPPORT_RMNET=1
      case $1 in
        "mass_storage,adb") PID_PREFIX=6 ;;
        "mtp,adb") PID_PREFIX=5 ;;
        "rndis,adb")
        PID_PREFIX=D
        SUPPORT_RMNET=0
        ;;
        *)
          /system/bin/log -t ${TAG} -p i "No eng PID for: $1"
          return 1
          ;;
      esac
      DIAG_CLIENT="diag"
      SERIAL_TRANSPORT="smd,tty"
      RMNET_TRANSPORT="smd,bam"
      ;;
  esac

  PID=${PID_PREFIX}146
  USB_FUNCTION=${1},serial,diag
  echo ${DIAG_CLIENT} > /sys/class/android_usb/android0/f_diag/clients
  echo ${SERIAL_TRANSPORT} > /sys/class/android_usb/android0/f_serial/transports
  if [ ${SUPPORT_RMNET}  -eq 1 ] ; then
    USB_FUNCTION=${USB_FUNCTION},rmnet
    echo ${RMNET_TRANSPORT} > /sys/class/android_usb/android0/f_rmnet/transports
  fi

  return 0
}

PID_SUFFIX_PROP=$(/system/bin/getprop ro.usb.pid_suffix)
USB_FUNCTION=$(/system/bin/getprop sys.usb.config)
ENG_PROP=$(/system/bin/getprop persist.usb.eng)

get_pid_prefix ${USB_FUNCTION}
if [ $? -eq 1 ] ; then
  exit 1
fi

PID=${PID_PREFIX}${PID_SUFFIX_PROP}

echo 0 > /sys/class/android_usb/android0/enable
echo ${VENDOR_ID} > /sys/class/android_usb/android0/idVendor

if [ ${ENG_PROP} -eq 1 ] ; then
  set_engpid ${USB_FUNCTION}
fi

echo ${PID} > /sys/class/android_usb/android0/idProduct
/system/bin/log -t ${TAG} -p i "usb product id: ${PID}"

echo ${USB_FUNCTION} > /sys/class/android_usb/android0/functions
/system/bin/log -t ${TAG} -p i "enabled usb functions: ${USB_FUNCTION}"

echo 1 > /sys/class/android_usb/android0/enable

exit 0
