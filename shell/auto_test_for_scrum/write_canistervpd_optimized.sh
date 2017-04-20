#!/bin/bash

AWKCMD=awk
LSCMD=ls
trcfile="/dumps/scrumtest.trc"

function log()
{
    echo "[$(date -d today +"%Y-%m-%d %H:%M:%S")]" $* >>${trcfile}
}

function execbmcipmicmd()
{
                                                   #BUS  Addr cnt
    writecmd="timeout -k1 1 ipmitool raw 0x06 0x52 0x09 0xAC 0x00"
    paraindex=2

    #use paramaters of the function to build wirte command
    while [ $(($paraindex)) -le $# ]
    do
        writecmd="${writecmd} ${!paraindex}"
        paraindex=$(($paraindex+1))
    done

    #execute command and check whether execute successfully.
    ${writecmd} >null
    wirtecmd_rc=$(($?))
    if [ ${wirtecmd_rc} != 0 ]; then
        log "command exec fail,cmd_W:${writecmd},cmd_rc:${wirtecmd_rc}"
        exit 1
    fi

    log "cmd_W:${writecmd}"

    #read data and check weather it equal to write-data
    readcmd="timeout -k1 1 ipmitool raw 0x06 0x52 0x09 0xAC"
    readcnt=$(($#-3))
    readcmd="${readcmd} 0x$(printf %.2x $readcnt) $2 $3"
    log "cmd_R:${readcmd}"

    readresult=$(${readcmd})
    log "read data is"${readresult}

    array=($readresult)

    i=0
    while [ $(($i)) -lt $readcnt ]
    do
        j=$(($i+4))
        if [ $((16#${array[$i]})) != $((${!j})) ]; then
            write_ok=0
            log "read/write data inconsistent:index($i),writedata:$((${!j})),readdata:$((16#${array[$i]}))"
            exit 1
        fi
        i=$(($i+1))
    done
}

if [ ! -f ${trcfile} ]
then
    touch ${trcfile}
else
    typeset -i SZ
    SZ=$(${LSCMD} -s ${trcfile} | ${AWKCMD} -F " " '{print $1}')
    SZ=${SZ}*1024
    if [ $SZ -gt 163840 ]
    then
        tail --bytes=163840 ${trcfile} >/tmp/$$ 2>/dev/null
        mv -f /tmp/$$ ${trcfile} 2>/dev/null
    fi
fi

#script start exec from here
write_ok=1
log "============Begin exec script $0 at $(date)============" >>${trcfile}

l=$(($RANDOM%10))
m=$(($RANDOM%10))
n=$(($RANDOM%10))


#vpd_can_version_e
#0504
              #cnt of_h of_l data...
execbmcipmicmd 0x00 0X2B 0x02 0x05 0x04

#vpd_can_fru_part_number_e
#85y6116
              #cnt of_h of_l data...
execbmcipmicmd 0x00 0X2B 0x93 0x38 0x35 0x79 0x36 0x3$l 0x3$m 0x3$n


#vpd_can_fru_identity_e
#11S 85Y6112 YHU999 00P5E3
execbmcipmicmd 0x00 0X2B 0x80 0x38 0x35 0x59 0x36 0x31 0x31 0x32
execbmcipmicmd 0x00 0X2B 0x87 0x59 0x48 0x55 0x39 0x39 0x39
execbmcipmicmd 0x00 0X2B 0x8D 0x30 0x30 0x50 0x35 0x45 0x33


#vpd_can_model_type_e
#00000000000000000000000000000000
              #cnt of_h of_l data...
execbmcipmicmd 0x00 0X2B 0x20 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00


if [ $write_ok = 1 ]; then
    log "write canister vpd OK"
    exit 0
else
    log "write canister vpd fail"
    exit 1
fi
