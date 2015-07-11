#!/bin/sh
##################################################
#
# Create a new key/certificate pair
# for Quassel IRC.
#
# In general, certificates should
# have permissions 644 root:root
#
# Private keys should have
# permissions 640 root:root
#
# Change the key's owners according
# to the users of the key.
#
#
# Private key and certificate files.
tgt_key=/var/lib/quassel/quasselCert.pem
tgt_crt=/var/lib/quassel/quasselCert.pem
# Process' user and group.
usr=quasselcore
grp=quassel
#
#
##################################################


# Check for root permissions.
if [ "$(id -u)" != "0" ]; then
  echo This script must be run as root 2>&1
  exit 1
fi

# Backup the old key and certificate.
date=$(date +%F_%H-%M-%S)
mv $tgt_key ${tgt_key}_${date}.old
mv $tgt_crt ${tgt_crt}_${date}.old

# Create the new key and certificate.
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $tgt_key -out $tgt_crt

# Set the permissions.
chown ${usr}:${grp} $tgt_crt
chown ${usr}:${grp} $tgt_key
chmod 644 $tgt_crt
chmod 640 $tgt_key
