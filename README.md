
# Usage:
#   1. Configure and run script (see the CONFIG section below)
#      There is no parsing of stdin. All user data is onboard.
#   2. Connect over VNC (port 0.0.0.0:5900 by default) and go
#      through the OS installation process (its manual, but only once).
#   4. Do what you want: setup SSH, run Ansible, anything you want
#      to have in your base system
#   5. Use new-from-base-image.sh to create new VMs
#      utilizing your newly created base image.


# Usage:
#   1. Create a base image using build-image.sh if you haven't already done so.
#      There is no parsing of stdin. All user data is onboard.
#   2. Configure the script below to your use case.
#   3. Run up.sh in the newly-created directory for your VM to spin it up.



