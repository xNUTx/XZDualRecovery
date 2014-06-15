echo "Backing up TA.."
ls -alF /dev/block/platform/msm_sdcc.1/by-name/TA
dd if=/dev/block/platform/msm_sdcc.1/by-name/TA of=/data/local/tmp/TA.img
echo "Created /data/local/tmp/TA.img -- Checking MD5.."
md5 /dev/block/platform/msm_sdcc.1/by-name/TA /data/local/tmp/TA.img
chmod 777 /data/local/tmp/TA.img

echo "Disabling sony_ric"
/data/local/tmp/ric_disabler
echo "Remounting /system"
mount -o remount,rw /system
echo "Copying su"
cp /data/local/tmp/su /system/xbin/su
chmod 6755 /system/xbin/su