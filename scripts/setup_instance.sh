#!/usr/bin/env bash

MOUNT_POINT="/mnt/gitlab-data"

# Wait for disk to mount 
while [ ! -e /dev/xvdf ]; do sleep 1; done

# Install XFS Tools to mount XFS volumes
echo "==> Installing XFS Tools"
sudo apt-get install -y xfsprogs
echo "(✓) XFS Tools Installed"

# Check if the volume has a file system on it already
# Based on guide from: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-using-volumes.html
echo "==> Checking mounted volume is formatted"
DATA_STR=$(sudo file -s /dev/xvdf | sed 's/\/dev\/xvdf\: //g')
echo "(?) DATA_STR ==> '${DATA_STR}'"
if [[ "${DATA_STR}" == "data" ]]; then
    echo "(!) Volume not yet formatted, preforming now..."
    sudo mkfs -t xfs /dev/xvdf
    DATA_STR=$(sudo file -s /dev/xvdf | sed 's/\/dev\/xvdf\: //g')
    echo "(?) DATA_STR ==> '${DATA_STR}'"
    echo "(✓) Volume has been formatted, continuing..."
else
    echo "(✓) Volume is already formatted, continuing..."
fi
sleep 2s

# Create the directory
sudo mkdir -p $MOUNT_POINT

# Configure the volume to auto-mount if we have to restart the EC2 instance
echo "==> Backing up fstab file"
sudo cp /etc/fstab /etc/fstab_`date +%Y%m%d`
echo "(✓) Backup completed"
echo "==> Adding new device to fstab file"
VOLUME_UUID=$(sudo lsblk -o +UUID | grep xvdf | awk '{print $7}')
echo "(?) VOLUME_UUID ==> '${VOLUME_UUID}'"
echo "(?) 'UUID=${VOLUME_UUID}  ${MOUNT_POINT}  xfs  defaults,nofail  0 2' >> etc/fstab"
echo "UUID=${VOLUME_UUID}  ${MOUNT_POINT}  xfs  defaults,nofail  0 2" >> /etc/fstab
echo "(✓) New device added to fstab file"

# Make sure we mount the volume
echo "==> Mounting new storage device"
sudo umount $MOUNT_POINT
sudo mount -a
if [ $? -eq 0 ]; then
    echo "(✓) New storage device mounted"
else
    echo "(!) Failed to mount device, rolling back fstab changes"
    # We failed to mount the device, we need to fall back
    # Make copy the new fstab file so we can debug the issue
    sudo cp /etc/fstab /etc/fstab_`date +%Y%m%d`_failed
    # Copy back in the original fstab file so the system still boots
    sudo mv /etc/fstab_`date +%Y%m%d` /etc/fstab
    echo "(✓) fstab changes have been rolled back. Manual intervention is advised"
fi
