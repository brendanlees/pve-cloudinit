#!/bin/bash

# --- defaults
template_name='your-template-name'
cloudimg_file='cloudimg-filename.img'
vmid='8000'
default_storage='storage-name'
resized_disk='64' # in GB


# --- helper functions

# convert GB to MB
gb_to_mb() {
    echo $(($1 * 1024))
}

# convert MB to GB
mb_to_gb() {
    echo $(($1 / 1024))
}

# function to get disk size in MB
get_disk_size_mb() {
    local size=$(qm config $1 | grep "scsi0:" | awk -F'size=' '{print $2}' | awk -F',' '{print $1}')
    local value=$(echo $size | sed 's/[^0-9]*//g')
    local unit=$(echo $size | sed 's/[0-9]//g')
    
    case "$unit" in
        G)
            echo $(gb_to_mb $value)
            ;;
        M)
            echo $value
            ;;
        *)
            echo "Error: Unrecognized size unit: $unit" >&2
            return 1
            ;;
    esac
}

# --- set up cloud-init

# create vm
qm create $vmid --memory 2048 --core 2 --name $template_name --net0 virtio,bridge=vmbr0

# get cloud-image
cd /var/lib/vz/template/iso/ 
qm importdisk $vmid $cloudimg_file $default_storage

# attach cloud-image
qm set $vmid --scsihw virtio-scsi-pci --scsi0 $default_storage:vm-$vmid-disk-0
qm set $vmid --ide2 $default_storage:cloudinit

# set boot disk
qm set $vmid --boot c --bootdisk scsi0 

# --- resize disk

# Get current disk size
CURRENT_SIZE_MB=$(get_disk_size_mb $vmid)

# Calculate the difference
RESIZED_DISK_MB=$(gb_to_mb $resized_disk)
DIFFERENCE_MB=$((RESIZED_DISK_MB - CURRENT_SIZE_MB))

# Resize the disk if necessary
if [ $DIFFERENCE_MB -ne 0 ]; then
    if [ $DIFFERENCE_MB -gt 0 ]; then
        echo "Increasing disk size by $DIFFERENCE_MB MB"
        qm resize $vmid scsi0 +${DIFFERENCE_MB}M
    else
        echo "Decreasing disk size by ${DIFFERENCE_MB#-} MB"
        qm resize $vmid scsi0 -${DIFFERENCE_MB#-}M
    fi
    
    # Get new size and convert to GB for display
    NEW_SIZE_MB=$(get_disk_size_mb $vmid)
    NEW_SIZE_GB=$(mb_to_gb $NEW_SIZE_MB)
    echo "New disk size: ${NEW_SIZE_GB}G"
else
    echo "Disk is already at the desired size of ${resized_disk}G"
fi

# allow / set serial access
qm set $vmid --serial0 socket --vga serial0

# Rescan storage
echo "Rescanning storage..."
qm rescan --vmid $vmid

echo "VM setup and configuration complete."
