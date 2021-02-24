#!/usr/bin/env bash

# A small wrapper script for bare QEMU to spin up a VM. Kind of like a low-level,
# virt-install but with a hell of a lot less dependencies.

if [ -z "$1" ]; then
    echo "Provide the name of a .config file as an argument"
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

ISO_URL=${config_value[0]}
ISO=${config_value[1]}
ISO_CHECKSUM=${config_value[2]}

CHECKSUM_COMMAND=${config_value[3]}

QEMU_IMG=${config_value[4]}
DISK_SIZE=${config_value[5]}

IMG_DIR=${config_value[6]}
ISO_DIR=${config_value[7]}

MEMORY=${config_value[8]}

if [ -z ${ISO_URL+x} ]; then
    echo "You must set the \$ISO_URL config flag."
    exit
fi

if [ -z ${ISO+x} ]; then
    echo "You must set the \$ISO config flag."
    exit
fi

if [ -z ${ISO_CHECKSUM+x} ]; then
    echo "You must set the \$ISO_CHECKSUM config flag."
    exit
fi

if [ -z ${CHECKSUM_COMMAND+x} ]; then
    echo "You must set the \$CHECKSUM_COMMAND config flag."
    exit
fi

if [[ -f "$ISO_DIR"/"$ISO" ]]
then
    echo "$ISO already exists on your filesystem..."
else
    if curl -L "$ISO_URL" -o "$ISO_DIR"/"$ISO"; then
    	echo "$ISO downloaded from $ISO_URL"
    else
        echo "Could not download $ISO from $ISO_URL. Aborting"
	exit
    fi
fi

if ! command -v $CHECKSUM_COMMAND > /dev/null
then
    echo "\"$CHECKSUM_COMMAND\" could not be found"
    exit
fi

echo "Verifying checksum of $ISO"
CHECKSUM_VERIFICATION=$(echo "$ISO_CHECKSUM" "$ISO_DIR"/"$ISO" | $CHECKSUM_COMMAND)

if [[ ! $CHECKSUM_VERIFICATION ]]
then
    echo "Verifying the checksum failed. Aborting"
    exit
else
    if [ "$CHECKSUM_VERIFICATION" ==  "$ISO_DIR/$ISO: OK" ]; then
    	echo "Checksum verification succeeded."
    else
	echo "Checksum verification failed. Is your ISO corrupted? Aborting"
	exit
    fi
fi

if [[ -f "$IMG_DIR"/"$QEMU_IMG" ]]
then
    echo "$IMG_DIR/$QEMU_IMG already exists. Not going to overwrite it, it could be important :^)"
    exit
else
    echo "Creating $IMG_DIR/$QEMU_IMG..."
    if qemu-img create "$IMG_DIR"/"$QEMU_IMG" "$DISK_SIZE"; then
    	echo "Image created."
    else
        echo "Could not create image. Aborting"
	exit
    fi

fi

SPICE_PORT=$(shuf -i 1025-65534 -n 1)
echo "Connect to the system over SPICE at port $SPICE_PORT and go through the installation procedure."
qemu-system-x86_64 \
	-boot c \
	-drive format=raw,media=cdrom,readonly,file="$ISO_DIR"/"$ISO" \
	-drive format=raw,file="$IMG_DIR"/"$QEMU_IMG" \
	-m "$MEMORY" \
	-vga qxl \
	-device virtio-serial-pci \
    -spice port="$SPICE_PORT",disable-ticketing \
	-device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0 \
	-chardev spicevmc,id=spicechannel0,name=vdagent \
	-enable-kvm
