#!/bin/bash
if [ $# -lt 2 ] || [ ! -e $2 ]; then
        echo You must provide an action and a valid u-boot file as parameters
        echo Example: $0 clear_dcd_addr u-boot.imx
        exit 1
fi

# DCD address must be cleared for signature, as mfgtool will clear it.
if [ "$1" == "clear_dcd_addr" ]; then
        # store the DCD address
        dd if=$2 of=dcd_addr.bin bs=1 count=4 skip=12
        # generate a NULL address for the DCD
        dd if=/dev/zero of=zero.bin bs=1 count=4
        # replace the DCD address with the NULL address
        dd if=zero.bin of=$2 seek=12 bs=1 conv=notrunc
        rm zero.bin
fi

# DCD address must be set for mfgtool to localize the DCD table.
if [ "$1" == "set_dcd_addr" ]; then
        # restore the DCD address with the original address
        dd if=dcd_addr.bin of=$2 seek=12 bs=1 conv=notrunc
        rm dcd_addr.bin
fi
