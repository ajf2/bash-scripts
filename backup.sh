#!/bin/sh
. /home/adrian/scripts/userlib.sh
##################################################
#
# Backup from LVM snapshots.
#
##################################################

# Check for root permissions.
if [ "$(id -u)" != "0" ]; then
  echo This script must be run as root 2>&1
  exit 1
fi

# Determine GFS mode (1) or simple mode (0).
mode=0
if [ $# -gt 0 ]; then
  if [ $1 = "-g" ]; then
    mode=1
  fi
fi

# Where to backup to.
dest="/var/backups/server"

# LVM volume group name.
vg="ubuntu-vg"

# Where to mount LVM snapshots.
snap_mount="/mnt/snapshot"

# Where to store database backups.
db_backups="/var/backups/databases"

# What to backup.
backup_files="$db_backups /etc/apache2/apache2.conf /etc/apache2/sites-available /etc/dhcp/dhclient.conf /etc/hosts /etc/init.d/noip2 /etc/network/interfaces /etc/systemd/logind.conf /etc/wpa_supplicant/wpa_supplicant.conf /home/adrian /var/lib/quassel /var/log/quassel /var/www/owncloud"
mysql_databases="owncloud"

# MySQL parameters.
mysql_user="root"
mysql_password="Really secure password that no one will ever guess!"

# Set command paths.
lvcreate=/sbin/lvcreate
lvremove=/sbin/lvremove
mysqldump="$(which mysqldump)"
gzip="$(which gzip)"

# Clear out the target database backup directory.
rm -f $db_backups/mysql*

# Backup the MySQL databases using mysqldump.
mkdir -p $db_backups
mysql_target=$db_backups/mysql.sql
for mysql_db in $mysql_databases
do
  db_target=$db_backups/mysql_$mysql_db.sql
  echo "CREATE DATABASE $mysql_db; USE $mysql_db;" > $db_target
  $mysqldump --lock-tables -u $mysql_user --password="$mysql_password" $mysql_db >> $db_target
  cat $db_target >> $mysql_target
  echo "  MySQL database \"$mysql_db\" backed up"
done
$gzip -f --best $mysql_target
rm -f $db_backups/*.sql
echo "  MySQL backups compressed into $mysql_target.gz"

# Snapshot root and home.
$lvcreate -s -n root_snapshot -L 5G $vg/root
$lvcreate -s -n home_snapshot -L 1G $vg/home
$lvcreate -s -n backups_snapshot -L 10G $vg/backups

# Mount the snapshots.
mkdir -p ${snap_mount}
vg_sub=$(echo $vg | sed 's,-,--,g')
mount -r /dev/mapper/${vg_sub}-root_snapshot ${snap_mount}
mount -r /dev/mapper/${vg_sub}-home_snapshot ${snap_mount}/home
mount -r /dev/mapper/${vg_sub}-backups_snapshot ${snap_mount}/var/backups

# Create archive filename.
date=$(date +%F_%H-%M-%S)
hostname=$(hostname -s)_
distro=$(lsb_release -ds | sed s,\ ,_,g)_
archive_file="$hostname$distro$date.tgz"

# Set GFS destination.
if [ $mode -eq 1 ]; then
  echo "  Switching to GFS mode"
  # Determine the appropriate backup destination.
  day_of_year=$(date +%j)
  day_of_month=$(date +%d)
  day_of_week=$(date +%u)
  if [ $day_of_year -eq 1 ]; then
          dest="$dest/annual"
          echo "  Starting annual backup"
  elif [ $day_of_month -eq 1 ]; then
          dest="$dest/monthly"
          echo "  Starting monthly backup"
  elif [ $day_of_week -eq 1 ]; then
          dest="$dest/weekly"
          echo "  Starting weekly backup"
  else
          dest="$dest/daily"
          echo "  Starting daily backup"
  fi
fi

# Create the destination folder.
mkdir -p $dest

# Print start status message.
echo "  Backing up to $dest/$archive_file"

# Backup the files using tar.
backup_files_sub=$(echo \ $backup_files | sed 's, \/, ,g')
cd $snap_mount
tar -cpzf $dest/$archive_file $backup_files_sub

# Unmount the snapshots.
cd /
umount ${snap_mount}/var/backups
umount ${snap_mount}/home
umount ${snap_mount}

# Delete the snapshots.
$lvremove -f ${vg}/backups_snapshot
$lvremove -f ${vg}/home_snapshot
$lvremove -f ${vg}/root_snapshot

# Prune backups in GFS mode.
if [ $mode -eq 1 ]; then
  num_files=$(ls -l $dest | grep ^- | wc -l)
  echo "  $num_files files in $dest"
  month=$(date +%m)
  previous_month=$(($month - 1))
  if [ $previous_month -eq 0 ]; then
      previous_month=12
  fi
  numDayInMonth 1 $previous_month
  weeklies_to_keep=$?
  cd $dest
  if [ $day_of_month -eq 1 -a $num_files -ge 12 ]; then
          ls -tr | head -n -12 | xargs rm
          echo "  Removed oldest monthly backup archives"
  elif [ $day_of_week -eq 1 -a $num_files -ge $weeklies_to_keep ]; then
          ls -tr | head -n -$weeklies_to_keep | xargs rm
          echo "  Removed oldest weekly backup archives"
  elif [ $num_files -ge 7 ]; then
          ls -tr | head -n -7 | xargs rm
          echo "  Removed oldest daily backup archives"
  fi
fi

# Long listing of files in $dest to check file sizes.
ls -lh $dest
echo $dest

# Print end status message.
date=$(date)
echo "  Backup finished on $date"
