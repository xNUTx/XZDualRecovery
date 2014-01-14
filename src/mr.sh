#!/system/bin/sh

# MR Wrapper, part of XZDualRecovery
# This will make sure the command file survives if it exists.

if [ -f "/cache/recovery/command" -a -f "/cache/recovery/boot" ]; then
	cp /cache/recovery/command /cache/recovery/command.xzdr
fi

/system/bin/mr.stock
ECOD=$?

if [ -f "/cache/recovery/command.xzdr" -a -f "/cache/recovery/boot" -a ! -f "/cache/recovery/command" ]; then
        cp /cache/recovery/command.xzdr /cache/recovery/command
fi

exit $ECOD
