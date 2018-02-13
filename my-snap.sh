#! /bin/bash

set -u

LOG_FACILITY=local0
prog=${0##*/}

USAGE="Usage: ${prog} -h for usage help
       ${prog} [options] <source_dir>"
HELP="${prog} [options] <source_dir>"

lockfile=""
mountpoint=""
quiet=""
destination=""
backup_path=""
care_battery=""
transfert="" # disable by default
nb_local=50
nb_remote=50

disable_transfert=""

while getopts "l:m:d:f:qb" arg; do
    case "${arg}" in
        h )
            echo "${HELP}"
            exit 0
            ;;
        l )
            lockfile="${OPTARG}"
            ;;
        m )
            mountpoint="${OPTARG}"
            ;;
        d )
            destination="${OPTARG}"
            ;;
        f )
            backup_path="-f ${OPTARG}"
            ;;
        q )
            quiet="-q"
            ;;
        b )
            care_battery="1"
            ;;
        * )
            echo "${USAGE}"
            exit 1
            ;;
    esac
done

shift $((OPTIND-1))

if [ $# -ne 1 ] ; then
    echo "${USAGE}"
    exit 1
fi

source="${1}"


function log.info() {
    logger -p ${LOG_FACILITY}.info -t ${prog} "${1}"
    test -z "${quiet}" && echo "${1}"
}

function log.error() {
    logger -p ${LOG_FACILITY}.err -t ${prog} "${1}"
    echo "ERROR: ${1}" >&2
    exit 1;
}

function log.debug() {
    logger -p ${LOG_FACILITY}.debug -t ${prog} "${1}"
    test -z "${quiet}" && echo "${1}"
}

if [ -z "${care_battery}" ]; then
    mode=`/usr/bin/acpi -a`
    if [[ "${mode}" = *"off-line"* ]]; then
        log.info "we are off-line so nothing will be sended"
        disable_transfert="1" # disconnected
    fi
fi

if [ -z "${lockfile}" ]; then
    bn=`basename "${destination}"`
    lockfile="/tmp/${prog}_${bn}.lock"
    log.info "using lock file: ${lockfile}"
fi

if [ -z "$destination" ]; then
    log.info "destination is not set, transfert will be disabled"
    enable_transfert
    disable_transfert="1"
fi

if [ -n "${mountpoint}" ]; then
    if /bin/mountpoint ${quiet} ${mountpoint}; then
        log.info "destination is mounted"
    else
        log.info "destination is not mounted"
        disable_transfert="1"
    fi
else
    log.info "no mountpoint defined"
    disable_transfert="1"
fi

if [ -n "${disable_transfert}" ]; then
    transfert="-T"
fi

/usr/bin/flock -n ${lockfile} \
    /usr/bin/ionice -c 3 \
        /usr/local/bin/btrfs-backup\
            ${quiet} \
            -N ${nb_local} \
            -n ${nb_remote} \
            -s \
            ${backup_path} \
            ${transfert} \
            ${source} ${destination}

log.info "end of snapshot"