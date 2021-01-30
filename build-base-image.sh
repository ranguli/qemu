#!/usr/bin/env bash

# A small wrapper script for bare QEMU to spin up a VM. Kind of like a low-level, 
# less-automated Packer. 

# Usage:
#   1. Configure and run script (see the CONFIG section below)
#      There is no parsing of stdin. All user data is onboard.
#   2. Connect over VNC (port 0.0.0.0:5900 by default) and go
#      through the OS installation process (its manual, but only once).
#   4. Do what you want: setup SSH, run Ansible, anything you want 
#      to have in your base system
#   5. Use new-from-base-image.sh to create new VMs
#      utilizing your newly created base image.

########################################
# CONFIG                               #
########################################

# Here you can configure the script for your own use.
# Alternatively you can accept the defaults and build a bog-standard
# Debian 10 system.

# Uncomment to set the name of the install ISO file you want to build a base 
# machine from (required).
ISO="debian-10.7.0-amd64-netinst.iso"

# Uncomment to set the URL at which to download your ISO file. (required)
ISO_URL="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-10.7.0-amd64-netinst.iso"

# Uncomment to set the checksum value to validate the integrity of your ISO. (required)
ISO_CHECKSUM="b317d87b0a3d5b568f48a92dcabfc4bc51fe58d9f67ca13b013f1b8329d1306d"

# Uncomment to set the command for validating the checksum, without the file 
# as an argument. (required)
CHECKSUM_COMMAND="sha256sum --check"

# Uncomment to set the name of the virtual disk for the base system. (required)
QEMU_IMG="debian_base.img"

# Uncomment to set the size of the virtual disk. (required)
QEMU_IMG_SIZE="10G"

#########################################

if [ -z ${ISO+x} ]; then
    echo "You must set the \$ISO config flag."
    exit
fi

if [ -z ${ISO_URL+x} ]; then
    echo "You must set the \$ISO_URL config flag."
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

if [[ -f "$ISO" ]]
then
    echo "$ISO already exists on your filesystem..."
else
    if wget "$ISO_URL"; then
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
CHECKSUM_VERIFICATION=$(echo "$ISO_CHECKSUM" "$ISO" | $CHECKSUM_COMMAND)

if [[ ! $CHECKSUM_VERIFICATION ]]
then
    echo "Verifying the checksum failed. Aborting"
    exit 
else
    if [ "$CHECKSUM_VERIFICATION" ==  "$ISO: OK" ]; then
    	echo "Checksum verification succeeded."
    else
	echo "Checksum verification failed. Aborting"
    fi		
fi

if [[ -f "$QEMU_IMG" ]]
then
    echo "$QEMU_IMG already exists. Not going to overwrite it, it could be important :^)"
    exit
else
    echo "Creating $QEMU_IMG..."
    if qemu-img create "$QEMU_IMG" "$QEMU_IMG_SIZE"; then
    	echo "Image created." 
    else
        echo "Could not create image. Aborting"
	exit
    fi
    	
fi

echo "Connect to the system over VNC at 0.0.0.0:5900 and go through the installation procedure."
qemu-system-x86_64 \
	-boot d \
	-drive format=raw,media=cdrom,readonly,file="$ISO" \
	-drive format=raw,file="$QEMU_IMG" \
	-m 4096 \
	-vnc 0.0.0.0:0 \
	-enable-kvm
