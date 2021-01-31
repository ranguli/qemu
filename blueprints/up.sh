#!/usr/bin/env bash

# A small wrapper script for bare QEMU to spin up a VM. Kind of like a low-level,
# less-automated Packer.

if [ -z "$1" ]; then
    echo "Provide the name of a .config file to be run as an argument"
    exit
fi

if [[ ! -f "$1" ]]; then
    echo "${1} not a file."
    exit
fi

i=0
while read -r line; do
  if [[ "$line" =~ ^[^#]*= ]]; then
    config_value[i]=${line#*= }
    ((i++))
  fi
done < "$1"

QEMU_NAME=${config_value[0]}
QEMU_IMG=${config_value[1]}
SSH_PORT=${config_value[2]}
SPICE_PORT=${config_value[3]}
CORES=${config_value[4]}
MEMORY=${config_value[5]}

if [ -z ${QEMU_NAME+x} ]
then
    echo "You must set the \$QEMU_NAME variable."
    exit
fi

if [ -z ${SSH_PORT+x} ]
then
    echo "You must set the \$SSH_PORT variable."
    exit
fi

if [ -z ${SPICE_PORT+x} ]
then
    echo "You must set the \$SSH_PORT variable."
    exit
fi

if [ -z ${CORES+x} ]
then
    echo "You must set the \$CORES variable."
    exit
fi

if [ -z ${MEMORY+x} ]
then
    echo "You must set the \$MEMORY variable."
    exit
fi

echo "Starting VM $QEMU_NAME with ${MEMORY}MB of RAM and $CORES CPU cores. Connect over SPICE on $SPICE_PORT or SSH on port ${SSH_PORT}"

qemu-system-x86_64 \
	-boot d \
	-drive format=raw,file=./"$QEMU_NAME"/"$QEMU_IMG" \
	-m "$MEMORY" \
	-smp "$CORES" \
	-enable-kvm \
	-nic user,hostfwd=tcp::${SSH_PORT}-:22 \
	-vga qxl \
	-device virtio-serial-pci \
	-spice port="$SPICE_PORT",disable-ticketing \
	-device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0 \
	-chardev spicevmc,id=spicechannel0,name=vdagent


