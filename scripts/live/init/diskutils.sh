# vim: filetype=sh et ts=4

# this is a dreadful kludge, but no idea how else to
# solve the issue
# namely, after vgrename the mount table is not updated
# and still contains the previous VG name in the device
# path for the rootfs
grub_vgrename_kludge() {
    local vg=$FINAL_VGNAME
    local target=$TARGET
    local dir=/newroot
    sed -i "s,root=/dev/mapper/DBSTCK[^ ]*,root=/dev/$vg/ROOT," /boot/grub/grub.cfg
    mkdir $dir
    sync;sync;sync
    mount /dev/$vg/ROOT $dir
    $BOOTLOADER_INSTALL -s --boot-directory=$dir $target
    umount $dir
    rmdir $dir
}

enforce_lvm_cmd() {
    local cmd i
    cmd="$*"
    for i in 1 2 3; do
        # some disk related programs fail occasionally, it seems
        # to be a timing issue; there must be a reason, but
        # heaven knows which it is, so let's just retry
        # some commands need to be told "y"
        yes | $cmd && break
        sleep 1
    done
}


# output the percentage of the VG for the rootfs
# we adapt the desired share size to the actual size of the vg
# if the share is smaller than the minimum size, we calculate the
# share which is minimum size
vg_free() {
    vgs -o vg_free --noheadings --units G --nosuffix $1
}
blkdev_free() {
    lsblk -bndlo SIZE $1 | awk '{print $1/1024.0/1024.0/1024.0}'
}
# $1: desired_size (percentage of the vg[,min size in gb]; e.g. "10,25")
# $2: device or size (if device, then its size is retrieved)
# $3: as_pct (output percentage rather than absolute size)
calc_size() {
    local size dev as_pct
    dev="$2"
    as_pct="$3"
    free=$(case "$dev" in
        [A-Za-z]*) vg_free $dev ;;
        /dev/*) blkdev_free $dev ;;
        [0-9][0-9.]*) echo $dev ;;
        *) echo "** ERROR: from $dev cannot calculate the share size" 2>&1
            echo 1
            ;;
    esac)
    echo "$1" |
    awk -v as_pct="$as_pct" -v free="$free" '
    {
        n = split($1, a, ",");
        desired_share = a[1]/100.0;
        if (n == 2)
            min_size = a[2];
        else
            min_size = 0;
        size = free*desired_share;
        if (size < min_size)
            size = min_size;
        if (size > free)
            size = free;
    }
    END{if (as_pct == "")
            print int(size);
        else
            print int(100*(size/free));
    }'
}
calc_share() {
    calc_size $@ 1
}
