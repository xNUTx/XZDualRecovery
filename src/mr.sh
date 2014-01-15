#!/system/bin/sh

# MR Wrapper, part of XZDualRecovery
# This will make sure the command file survives if it exists.
# Patched to work by Tungstwenty from XDA, thanks bro!

if [ -f "/cache/recovery/command" ]; then
        /system/bin/cp -fa /cache/recovery/command /cache/recovery/command.xzdr
fi

/system/bin/mr.stock
ECOD=$?

if [ -f "/cache/recovery/command.xzdr" -a ! -f "/cache/recovery/command" ]; then
        /system/bin/mv /cache/recovery/command.xzdr /cache/recovery/command
fi

exit $ECOD
