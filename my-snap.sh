#! /bin/bash

lockfile=${1:-""}
source=${2:-""}
mountpoint=${3:-""}
destination=${4:-""}

if [ -z "${mountpoint}" ] ; then
    /usr/bin/flock -n ${lockfile} \
        /usr/bin/ionice -c 3 \
            /usr/local/bin/btrfs-backup\
                -q \
                -N 50 \
                -n 50 \
                -s \
                -T \
                ${source}
else
    /bin/mountpoint -q ${mountpoint} && \
        /usr/bin/flock -n ${lockfile} \
            /usr/bin/ionice -c 3 \
                /usr/local/bin/btrfs-backup\
                    -q \
                    -N 50 \
                    -n 50 \
                    -s \
                    -S \
                    ${source} ${destination}
fi
