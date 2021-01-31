# base

Contains config files that define a "base image", which is turned into a
QEMU image by `base-image-builder.sh`. Other QEMU VMs are then created by using
the base image as a starting point.

To create a new base image, run:

`base-image-builder.sh configs/debian-10.7.0-base.config`



