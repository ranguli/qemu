#!/usr/bin/env bash

# A small wrapper script for bare QEMU to spin up a VM. Kind of like a low-level,
# less-automated Packer.

if [ -z "$1" ]; then
    echo "Provide the name of a blueprint .config file to be built as an argument"
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

QEMU_BASE_IMG=${config_value[0]}
QEMU_NAME=${config_value[1]}

if [ -z ${QEMU_BASE_IMG+x} ]
then
    echo "You must set the $QEMU_BASE_IMG variable."
    exit
fi

if [ -z ${QEMU_NAME+x} ]
then
    echo "You must set the $QEMU_NAME variable."
    exit
fi

if mkdir -p "$QEMU_NAME"/; then
    echo "Working with $QEMU_NAME/"
else
    echo "Could not create image. Aborting"
    exit
fi

QEMU_IMG="$QEMU_NAME.img"
QEMU_IMG_PATH="$QEMU_NAME/$QEMU_IMG"

if [[ -f $QEMU_IMG_PATH ]]
then
    echo "$QEMU_IMG_PATH already exists. Will not overwrite it. Aborting."
    exit
fi

if cp "$QEMU_BASE_IMG" "$QEMU_NAME"/"$QEMU_IMG"; then
    echo "Cloned $QEMU_BASE_IMG as $QEMU_IMG to $QEMU_IMG_PATH."
else
    echo "Could not clone image to $QEMU_IMG_PATH. Aborting"
    exit
fi


QEMU_CONFIG="$QEMU_NAME"/"$QEMU_NAME".config

if touch $QEMU_CONFIG; then
{
    echo "# Sets the name of the QEMU VM."
    echo "QEMU_NAME = ${QEMU_NAME}"
    echo ""
    echo "QEMU_IMG = ${QEMU_IMG}"
    echo ""
    echo "# Sets the SSH port of the server. You still need to configure OpenSSH."
    echo "SSH_PORT = $(shuf -i 1025-65534 -n 1)"
    echo ""
    echo "# Sets the SPICE port for VNC-style remote access."
    echo "SPICE_PORT = $(shuf -i 1025-65534 -n 1)"
    echo ""
    echo "# Sets the number of CPU cores the VM will use."
    echo "CORES = 4"
    echo ""
    echo "# Set the RAM in megabytes of the VM."
    echo "MEMORY = 4096" 
} >> "$QEMU_NAME"/"$QEMU_NAME".config
else
    echo "Could not create $QEMU_CONFIG. Aborting"
    exit
fi

echo "Run ./up.sh to start the VM."
