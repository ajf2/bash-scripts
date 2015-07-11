#!/bin/sh
##################################################
#
# Reconfigure noip2.
#
##################################################

# Check for root permissions.
if [ "$(id -u)" != "0" ]; then
  echo This script must be run as root 2>&1
  exit 1
fi

# Stop noip.
service noip2 stop

# Generate a new config file.
noip2 -C

# Start noip.
service noip2 start
